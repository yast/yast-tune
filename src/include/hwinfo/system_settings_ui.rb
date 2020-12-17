# encoding: utf-8

#
# Module:	System Settings UI Handling
#
# Author:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# System Settings for PCI ID, I/O Scheduler, etc.
module Yast
  module HwinfoSystemSettingsUiInclude
    def initialize_hwinfo_system_settings_ui(include_target)
      Yast.import "UI"
      Yast.import "Progress"
      Yast.import "SystemSettings"
      Yast.import "Wizard"

      # ReadSettings()
      Yast.include include_target, "hwinfo/newid.rb"

      textdomain "tune"

      # Short sleep between reads or writes
      @sl = 500
    end

    def ReadSystemSettingsDialog
      caption = _("Reading the Configuration")

      # FIXME: s390: disable reading PCI IDs
      Progress.New(
        caption,
        " ",
        2,
        [_("Read the PCI ID settings"), _("Read the system settings")],
        [
          _("Reading the PCI ID settings..."),
          _("Reading the system settings..."),
          _("Finished")
        ],
        _(
          "<p><b><big>Reading the Configuration</big></b><br>\nPlease wait...</p>"
        )
      )

      progress_orig = nil

      Progress.NextStage
      progress_orig = Progress.set(false)
      # calling PCI ID Read()
      ReadSettings()
      Progress.set(progress_orig)

      Progress.NextStage
      progress_orig = Progress.set(false)
      # I have to admit that this is very ugly but it is here
      # to avoid of the very long starting time of the yast module
      # because the Storage module (which is imported by the Bootloader (imported by the SystemSettings module))
      # has a Read() function call in its constructor.

      # Aborting without any message since SystemSettings.Read
      # already reported the problem to the user
      return :abort unless SystemSettings.Read

      Progress.set(progress_orig)

      Progress.NextStage
      Builtins.sleep(Ops.multiply(2, @sl))

      :next
    end

    def WriteSystemSettingsDialog
      caption = _("Saving the Configuration")
      Progress.New(
        caption,
        " ",
        2,
        [_("Save the PCI ID settings"), _("Save the system settings")],
        [
          _("Saving the PCI ID settings..."),
          _("Saving the system settings..."),
          _("Finished")
        ],
        _(
          "<p><b><big>Saving the Configuration</big></b><br>\nPlease wait...</p>"
        )
      )

      progress_orig = nil

      Progress.NextStage
      progress_orig = Progress.set(false)
      # calling PCI ID Write()
      WriteSettings()
      Progress.set(progress_orig)

      Builtins.sleep(@sl)

      Progress.NextStage
      progress_orig = Progress.set(false)

      if SystemSettings.Modified
        # activate the current configuration
        SystemSettings.Activate

        # save the configuration
        SystemSettings.Write
      else
        Builtins.y2milestone("SystemSettings:: have not been modified")
      end

      Progress.set(progress_orig)

      Progress.NextStage
      Builtins.sleep(Ops.multiply(2, @sl))

      :next
    end

    def InitSysRqSettings(key)
      Wizard.DisableBackButton
      UI.ChangeWidget(Id("sysrq"), :Value, SystemSettings.GetSysRqKeysEnabled)

      nil
    end

    def StoreSysRqSettings(key, event)
      event = deep_copy(event)
      Builtins.y2milestone("Key: %1, Event: %2", key, event)

      sysrq_new = Convert.to_boolean(UI.QueryWidget(Id("sysrq"), :Value))
      if SystemSettings.GetSysRqKeysEnabled != sysrq_new
        SystemSettings.SetSysRqKeysEnabled(sysrq_new)
      end

      nil
    end

    def InitAutoConfSettings(key)
      Wizard.DisableBackButton
      UI.ChangeWidget(Id("autoconf"), :Value, SystemSettings.GetAutoConf)

      nil
    end

    def StoreAutoConfSettings(key, event)
      event = deep_copy(event)
      Builtins.y2milestone("Key: %1, Event: %2", key, event)

      autoconf_new = Convert.to_boolean(UI.QueryWidget(Id("autoconf"), :Value))
      if SystemSettings.GetAutoConf != autoconf_new
        SystemSettings.SetAutoConf(autoconf_new)
      end

      nil
    end
  end
end
