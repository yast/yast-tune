# encoding: utf-8

#
# Module:	System Settings Client
#
# Author:	Lukas Ocilka <locilka@suse.cz>
#		Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# System Settings for PCI ID, I/O Scheduler, etc.
module Yast
  class SystemSettingsClient < Client
    def main
      Yast.import "UI"

      textdomain "tune"

      Yast.import "Wizard"
      Yast.import "Sequencer"
      Yast.import "CommandLine"

      # PCI ID (backward compatibility)
      Yast.include self, "hwinfo/newid.rb"
      # UI handling functions
      Yast.include self, "hwinfo/system_settings_ui.rb"
      # UI definition functions
      Yast.include self, "hwinfo/system_settings_dialogs.rb"

      #*************************************
      #
      #            Main part
      #
      #************************************

      # aliases for wizard sequencer
      @aliases = {
        "read"  => [lambda { ReadSystemSettingsDialog() }, true],
        "main"  => lambda { SystemSettingsDialog() },
        "write" => lambda { WriteSystemSettingsDialog() }
      }

      # workflow sequence
      @sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }


      @cmdline_description = {
        "guihandler" => fun_ref(method(:GUIhandler), "any ()")
      }

      @ret = CommandLine.Run(@cmdline_description)

      deep_copy(@ret)
    end

    def GUIhandler
      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("org.opensuse.yast.SystemSettings")

      # start workflow
      ret = Sequencer.Run(@aliases, @sequence)
      Builtins.y2milestone("Finishing with %1", ret)

      UI.CloseDialog

      deep_copy(ret)
    end
  end
end

Yast::SystemSettingsClient.new.main
