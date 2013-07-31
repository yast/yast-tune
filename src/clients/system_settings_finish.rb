# encoding: utf-8

# File:
#  system_settings_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
module Yast
  class SystemSettingsFinishClient < Client
    def main

      textdomain "tune"

      Yast.import "SystemSettings"
      Yast.import "NewID"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end

      Builtins.y2milestone("starting system_settings_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Info"
        @ret = {
          "steps" => 1,
          # progress step title
          "title" => _("Saving system settings..."),
          "when"  => [:installation, :update, :autoinst]
        }
      elsif @func == "Write"
        # save kernel options
        SystemSettings.Write

        # save PCI ID config
        NewID.Write
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("system_settings_finish finished")
      deep_copy(@ret)
    end
  end
end

Yast::SystemSettingsFinishClient.new.main
