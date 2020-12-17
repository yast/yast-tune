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
require "cfa/sysctl_config"

module Yast
  class SystemSettingsClass < Module
    include Yast::Logger

    # Initialize the module
    def main
      textdomain "tune"

      Yast.import "Bootloader"
      Yast.import "Mode"

      # Internal Data
      @enable_sysrq  = nil
      @kernel_sysrq  = nil
      @sysctl_config = nil
      @sysctl_sysrq  = nil
      @autoconf      = true
      @modified      = false
    end

    # Determine if the module was modified
    def Modified
      log.info("Modified: #{@modified}")
      @modified
    end

    # Read system settings
    #
    # @see #read_sysrq
    # @see #read_autoconf
    def Read
      read_sysrq
      read_autoconf

      @modified = false
      true
    end

    # Activate settings
    #
    # @see #activate_sysrq
    # @see #activate_autoconf
    def Activate
      activate_sysrq
      activate_autoconf

      true
    end

    # Write settings to system configuration
    def Write
      write_sysrq
      write_autoconf
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

    # Determine current I/O device autoconf setting
    #
    # @return [Boolean] true if enabled; false otherwise.
    def GetAutoConf
      log.info "GetAutoConf = #{@autoconf}"
      @autoconf
    end

    # Set I/O device autoconf status
    #
    # @param value [Boolean] true to enable; false to disable
    def SetAutoConf(value)
      if value != @autoconf
        @modified = true
        @autoconf = value
      end

      nil
    end

    publish function: :Modified, type: "boolean ()"
    publish function: :Read, type: "boolean ()"
    publish function: :Activate, type: "boolean ()"
    publish function: :Write, type: "boolean ()"
    publish function: :GetSysRqKeysEnabled, type: "boolean ()"
    publish function: :SetSysRqKeysEnabled, type: "void (boolean)"
    publish function: :GetAutoConf, type: "boolean ()"
    publish function: :SetAutoConf, type: "void (boolean)"

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
      @sysctl_sysrq = sysctl_config.kernel_sysrq
      log.info("SysRq enabled: #{@sysctl_sysrq}")
      @sysctl_sysrq
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

    # Activate I/O device autoconf setting
    def activate_autoconf
      if @autoconf
        log.info("removing rd.zdev kernel parameter")
        Bootloader.modify_kernel_params("rd.zdev" => :missing)
      else
        log.info("adding rd.zdev=no-auto kernel parameter")
        Bootloader.modify_kernel_params("rd.zdev" => "no-auto")
      end
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
      sysctl_config.kernel_sysrq = enable_sysrq
      sysctl_config.save unless sysctl_config.conflict?
    end

    # Read I/O device autoconfig settings
    def read_autoconf
      rd_zdev = Bootloader.kernel_param(:common, "rd.zdev")
      log.info "current rd.zdev setting: rd.zdev=#{rd_zdev.inspect}"

      @autoconf = rd_zdev != "no-auto"
    end

    # Write I/O device autoconfig settings
    #
    # This method only has effect during normal mode. During installation,
    # bootloader configuration is written at the end of the first stage.
    #
    # @see Bootloader#Write
    # @see Write
    def write_autoconf
      Bootloader.Write if Mode.normal
    end

  private

    # Returns the sysctl configuration
    #
    # @note It memoizes the value until {#main} is called.
    #
    # @return [Yast2::CFA::SysctlConfig]
    def sysctl_config
      return @sysctl_config if @sysctl_config
      @sysctl_config = CFA::SysctlConfig.new
      @sysctl_config.load
      @sysctl_config
    end
  end

  SystemSettings = SystemSettingsClass.new
  SystemSettings.main
end
