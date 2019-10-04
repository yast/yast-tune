# encoding: utf-8

#
# Module:	Set Kernel and System Settings
#
# Author:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# This module manages the System and Kernel settings such as I/O Scheduler type,
# SysRq Keys...
require "yast"
require "cfa/sysctl"

module Yast
  class SystemSettingsClass < Module
    include Yast::Logger

    # Initialize the module
    def main
      textdomain "tune"

      Yast.import "Bootloader"
      Yast.import "Mode"

      # Internal Data
      @elevator     = nil
      @enable_sysrq = nil
      @kernel_sysrq = nil
      @sysctl_file  = nil
      @sysctl_sysrq = nil
      @modified     = false
    end

    # Known values of the 'elevator' variable
    ELEVATORS = ["cfq", "noop", "deadline"].freeze

    # Return the possible values to be used as elevators/schedulers
    #
    # @return [Array<String>] Know elevators/schedulers
    #
    # @see ELEVATORS
    def GetPossibleElevatorValues
      ELEVATORS
    end

    # Determine if the module was modified
    def Modified
      log.info("Modified: #{@modified}")
      @modified
    end

    # Read system settings
    #
    # @see #read_sysrq
    # @see #read_scheduler
    def Read
      read_sysrq
      read_scheduler
      @modified = false
      true
    end

    # Activate settings
    #
    # @see #activate_sysrq
    # @see #activate_scheduler
    def Activate
      activate_sysrq
      activate_scheduler
      true
    end

    # Write settings to system configuration
    def Write
      write_sysrq
      write_scheduler
    end

    # Return the kernel IO scheduler
    #
    # The scheduler is specified as the 'elevator' kernel parameter.
    # If not scheduler is set, it will return an empty string.
    #
    # @return [String] IO scheduler name or empty string if not set
    def GetIOScheduler
      @elevator
    end

    # Set IO scheduler
    #
    # @param scheduler [String] IO scheduler
    def SetIOScheduler(scheduler)
      # empty string = use the default scheduler
      if valid_scheduler?(scheduler) || scheduler == ""
        if GetIOScheduler() != scheduler
          @modified = true
          @elevator = scheduler
        end
      else
        log.error("unknown IO scheduler '#{scheduler}', use: #{GetPossibleElevatorValues()}")
      end

      nil
    end

    # Determine if SysRq keys are enabled
    #
    # @return [Boolean] true if they're enabled; false otherwise.
    def GetSysRqKeysEnabled
      !(enable_sysrq.nil? || enable_sysrq == "0")
    end

    # Set SysRq keys status
    #
    # @param value [Boolean] true to enable them; false to disable
    def SetSysRqKeysEnabled(value)
      if value.nil?
        log.warn("enable_sysrq should be 'true' or 'false'")
        return
      end

    value_string = value ? "1" : "0"
      if value_string != enable_sysrq
        @modified = true
        self.enable_sysrq = value_string
      end

      nil
    end

    publish function: :GetPossibleElevatorValues, type: "list <string> ()"
    publish function: :Modified, type: "boolean ()"
    publish function: :Read, type: "boolean ()"
    publish function: :Activate, type: "boolean ()"
    publish function: :Write, type: "boolean ()"
    publish function: :GetIOScheduler, type: "string ()"
    publish function: :SetIOScheduler, type: "void (string)"
    publish function: :GetSysRqKeysEnabled, type: "boolean ()"
    publish function: :SetSysRqKeysEnabled, type: "void (boolean)"

  protected

    # Return configuration for SysRq keys
    #
    # This is the value that will be written when #Write is called. If you want tools
    # get the real value from the system, check #kernel_sysrq and #sysctl_sysrq.
    #
    # @return [String] Configuration value; returns an empty string if it's not set.
    #
    # @see Write
    # @see kernel_sysrq
    # @see sysctl_sysrq
    attr_reader :enable_sysrq

    # Set sysctl configuration value for SysRq keys
    #
    # The value is not written until #Write is called.
    #
    # @param value [String] Configuration value
    #
    # @see Write
    def enable_sysrq=(value)
      log.info("SysRq was set to #{value}")
      @enable_sysrq = value
    end

    KERNEL_SYSRQ_FILE = "/proc/sys/kernel/sysrq".freeze

    # Return kernel configuration value for SysRq keys
    #
    # The value is read from /proc/sys/kernel/sysrq
    #
    # @return [String] Configuration value; returns an empty string if it's not set.
    def kernel_sysrq
      return @kernel_sysrq if @kernel_sysrq
      content = File.exist?(KERNEL_SYSRQ_FILE) ? File.read(KERNEL_SYSRQ_FILE) : ""
      @kernel_sysrq = content.split("\n")[0] || ""
    end

    # Return sysctl configuration value for SysRq keys
    #
    # @return [String] Configuration value; returns an empty string if it's not set.
    def sysctl_sysrq
      return @sysctl_sysrq if @sysctl_sysrq
      @sysctl_sysrq = sysctl_file.kernel_sysrq
      log.info("SysRq enabled: #{@sysctl_sysrq}")
      @sysctl_sysrq
    end

    # Determine if a string is a valid scheduler name
    #
    # @return [Boolean] true if it's valid; false otherwise.
    def valid_scheduler?(elevator)
      GetPossibleElevatorValues().include?(elevator)
    end

    # Determine the current scheduler from the system
    #
    # @return [String] IO Scheduler name; if it's not valid/set, it will return an empty string
    def current_elevator
      # get 'elevator' option from the default section
      elevator_parameter = Bootloader.kernel_param(:common, "elevator")
      log.info("elevator_parameter: #{elevator_parameter}")

      if elevator_parameter == :missing    # Variable is not set
        ""
      elsif elevator_parameter == :present # Variable is set but has not parameter
        log.info("'elevator' variable has to have some value")
        ""
      elsif !valid_scheduler?(elevator_parameter.to_s) # Variable is set but hasn't any known value
        log.warn(
          format("'elevator' variable has to have a value from %s instead of being set to %s",
            GetPossibleElevatorValues(),
            elevator_parameter
          )
        )
        ""
      else
        elevator_parameter.to_s
      end
    end

    # Activate SysRq keys configuration
    #
    # @see enable_sysrq
    def activate_sysrq
      if enable_sysrq.nil? || enable_sysrq !~ /\A[0-9]\z/
        log.warn("Not activating invalid ENABLE_SYSRQ value: #{enable_sysrq}")
        return
      end

      log.info("Activating SysRq config: #{enable_sysrq}")
      File.write(KERNEL_SYSRQ_FILE, "#{enable_sysrq}\n")
    end

    # Activate IO scheduler
    #
    # @see activate_scheduler
    def activate_scheduler
      return unless GetIOScheduler()

      new_elevator = GetIOScheduler() == "" ? :missing : GetIOScheduler()
      log.info("Activating scheduler: #{new_elevator}")
      # set the scheduler
      Bootloader.modify_kernel_params("elevator" => new_elevator)
      # set bootloader configuration as 'changed' (bsc#968192)
      Bootloader.proposed_cfg_changed = true

      # activate the scheduler for all disk devices
      return if new_elevator == :missing
      Dir["/sys/block/*/queue/scheduler"].each do |f|
        # skip devices which do not support the selected scheduler,
        # keep the original scheduler
        next unless device_supports_scheduler(f, new_elevator)

        log.info("Activating scheduler '#{new_elevator}' for device #{f}")
        File.write(f, new_elevator)
      end
    end

    # read available schedulers for the device
    # @param device [String] path to device scheduler file
    # @return [Array<String>] read schedulers from the file
    def read_device_schedulers(device)
      schedulers = File.read(device).split(/\s+/).map do |sched|
        # remove the current scheduler marks [] around the name
        sched[0] == "[" && sched [-1] == "]" ? sched[1..-2] : sched
      end

      log.info("Available schedulers for #{device}: #{schedulers}")

      schedulers
    end

    # does the device support support the scheduler?
    # @param device [String] path to device scheduler file
    # @param scheduler [String] name of the requested scheduler
    # @return [Boolean] true if supported
    def device_supports_scheduler(device, scheduler)
      schedulers = read_device_schedulers(device)
      schedulers.include?(scheduler)
    end

    # Read IO scheduler configuration updating the module's value
    #
    # @see Read
    def read_scheduler
      # Read bootloader settings in normal mode
      Bootloader.Read if Mode.normal

      # Set IO scheduler
      SetIOScheduler(current_elevator)
      log.info("Global IO scheduler: #{GetIOScheduler()}")
    end

    # Read SysRq keys configuration updating the module's value
    #
    # @see Read
    def read_sysrq
      if kernel_sysrq != sysctl_sysrq
        log.warn(
          format("SysRq mismatch: sysconfig value: '%s', current: '%s'", sysctl_sysrq, kernel_sysrq)
        )
      end

      # display the current value if it not configured
      self.enable_sysrq = sysctl_sysrq || kernel_sysrq
    end

    # Write SysRq keys settings
    #
    # @see Write
    def write_sysrq
      if enable_sysrq.nil? || enable_sysrq !~ /\A[0-9]\z/
        log.warn("Not writing invalid ENABLE_SYSRQ value: #{enable_sysrq}")
        return
      end

      log.info("Saving ENABLE_SYSRQ: #{enable_sysrq}")
      sysctl_file.kernel_sysrq = enable_sysrq
      sysctl_file.save
    end

    # Write IO Scheduler settings
    #
    # This method only has effect during normal mode. During installation,
    # bootloader configuration is written at the end of the first stage.
    #
    # @see Bootloader#Write
    # @see Write
    def write_scheduler
      Bootloader.Write if Mode.normal
      true
    end

  private

    # Returns the sysctl configuration
    #
    # @note It memoizes the value until {#main} is called.
    #
    # @return [Yast2::CFA::Sysctl]
    def sysctl_file
      return @sysctl_file if @sysctl_file
      @sysctl_file = CFA::Sysctl.new
      @sysctl_file.load
      @sysctl_file
    end
  end

  SystemSettings = SystemSettingsClass.new
  SystemSettings.main
end
