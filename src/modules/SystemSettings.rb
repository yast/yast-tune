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

module Yast
  class SystemSettingsClass < Module
    def main
      textdomain "tune"

      Yast.import "Service"
      Yast.import "Mode"

      # Internal Data
      @ENABLE_SYSRQ = nil

      @elevator = nil
      # Internal Data

      @modified = false
    end

    def GetPossibleElevatorValues
      # here are listed all known values of the 'elevator' variable
      ["cfq", "noop", "deadline"]
    end

    def Modified
      Builtins.y2milestone("Modified: %1", @modified)
      @modified
    end

    def Read
      @ENABLE_SYSRQ = Convert.to_string(
        SCR.Read(path(".etc.sysctl_conf.\"kernel.sysrq\""))
      )
      Builtins.y2milestone("SysRq enabled: %1", @ENABLE_SYSRQ)

      current_sysrq = Convert.to_string(
        SCR.Read(path(".target.string"), "/proc/sys/kernel/sysrq")
      )

      # read just the first line
      current_sysrq = Ops.get(Builtins.splitstring(current_sysrq, "\n"), 0, "")

      if @ENABLE_SYSRQ != nil && current_sysrq != @ENABLE_SYSRQ
        Builtins.y2warning(
          "SysRq mismatch: sysconfig value: '%1', current: '%2'",
          @ENABLE_SYSRQ,
          current_sysrq
        )
      end

      # display the current value if it not configured
      @ENABLE_SYSRQ = current_sysrq if @ENABLE_SYSRQ == nil

      # I have to admit that this is very ugly but it is here
      # to avoid of the very long starting time of the yast module
      # because the Storage module (which is imported by the Bootloader (imported by the SystemSettings module))
      # has a Read() function call in its constructor.
      Yast.import "Bootloader"

      if Mode.normal
        # runtime - read the settings
        Bootloader.Read
      end

      # get 'elevator' option from the default section
      elevator_parameter = Bootloader.getKernelParam(
        Bootloader.getDefaultSection,
        "elevator"
      )

      Builtins.y2milestone("elevator_parameter: %1", elevator_parameter)

      # Variable is not set
      if elevator_parameter == false || elevator_parameter == "false"
        @elevator = "" 
        # Variable is set but has not parameter
      elsif elevator_parameter == true || elevator_parameter == "true"
        Builtins.y2warning("'elevator' variable has to have some value")
        @elevator = "" 
        # Variable is set but hasn't any known value
      elsif !Builtins.contains(
          GetPossibleElevatorValues(),
          Convert.to_string(elevator_parameter)
        )
        Builtins.y2warning(
          "'elevator' variable has to have a value from %1 instead of being set to %2",
          GetPossibleElevatorValues(),
          elevator_parameter
        )
        @elevator = "" 
        # Variable is OK
      else
        @elevator = Convert.to_string(elevator_parameter)
      end

      Builtins.y2milestone("Global IO scheduler: %1", @elevator)

      true
    end

    def Activate
      if @ENABLE_SYSRQ != nil && Builtins.regexpmatch(@ENABLE_SYSRQ, "^[0-9]+$")
        Builtins.y2milestone("Activating SysRq config: %1", @ENABLE_SYSRQ)
        SCR.Execute(
          path(".target.bash"),
          Builtins.sformat("echo '%1' > /proc/sys/kernel/sysrq", @ENABLE_SYSRQ)
        )
      else
        Builtins.y2warning(
          "Not activating invalid ENABLE_SYSRQ value: %1",
          @ENABLE_SYSRQ
        )
      end

      if @elevator != nil
        Yast.import "Bootloader"
        new_elevator = @elevator == "" ? "false" : @elevator

        Builtins.y2milestone("Activating scheduler: %1", new_elevator)
        # set the scheduler
        Bootloader.setKernelParam(
          Bootloader.getDefaultSection,
          "elevator",
          new_elevator
        ) 

        # TODO FIXME: set the scheduler for all disk devices,
        # reboot is required to activate the new scheduler now
      end

      true
    end


    def Write
      # writing SysRq settings
      if @ENABLE_SYSRQ != nil && Builtins.regexpmatch(@ENABLE_SYSRQ, "^[0-9]+$")
        # save the SysRq setting
        Builtins.y2milestone("Saving ENABLE_SYSRQ: %1", @ENABLE_SYSRQ)
        SCR.Write(path(".etc.sysctl_conf.\"kernel.sysrq\""), @ENABLE_SYSRQ)
        SCR.Write(path(".etc.sysctl_conf"), nil)
      else
        Builtins.y2warning(
          "Not writing invalid ENABLE_SYSRQ value: %1",
          @ENABLE_SYSRQ
        )
      end

      # enable boot.sysctl service which sets the value after boot
      Service.Enable("boot.sysctl")

      # the bootloader configuration is written at the end of the first stage
      if Mode.normal
        # write the elevator setting
        Yast.import "Bootloader"
        Bootloader.Write
      end

      true
    end

    # Kernel param 'elevator'
    def GetIOScheduler
      @elevator
    end

    def SetIOScheduler(io_scheduler)
      # empty string = use the default scheduler
      if Builtins.contains(GetPossibleElevatorValues(), io_scheduler) ||
          io_scheduler == ""
        @modified = true if @elevator != io_scheduler

        @elevator = io_scheduler
      else
        Builtins.y2error(
          "unknown IO scheduler '%1', use: %2",
          io_scheduler,
          GetPossibleElevatorValues()
        )
      end

      nil
    end

    def GetSysRqKeysEnabled
      @ENABLE_SYSRQ != nil && @ENABLE_SYSRQ != "0"
    end

    def SetSysRqKeysEnabled(enable_sysrq)
      if enable_sysrq == nil
        Builtins.y2warning("enable_sysrq should be 'true' or 'false'")
        return
      end

      enable_sysrq_string = enable_sysrq ? "1" : "0"

      @modified = true if @ENABLE_SYSRQ != enable_sysrq_string

      @ENABLE_SYSRQ = enable_sysrq_string
      Builtins.y2milestone("SysRq was set to %1", @ENABLE_SYSRQ)

      nil
    end

    publish :function => :GetPossibleElevatorValues, :type => "list <string> ()"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Activate, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :GetIOScheduler, :type => "string ()"
    publish :function => :SetIOScheduler, :type => "void (string)"
    publish :function => :GetSysRqKeysEnabled, :type => "boolean ()"
    publish :function => :SetSysRqKeysEnabled, :type => "void (boolean)"
  end

  SystemSettings = SystemSettingsClass.new
  SystemSettings.main
end
