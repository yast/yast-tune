# encoding: utf-8

# File:
#   system_settings.ycp
#
# Summary:
#   Configuration of System Settings. PCI ID, Kernel parameters,
#   Bootloader parameters etc.
#
# Authors:
#   Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
module Yast
  module HwinfoSystemSettingsDialogsInclude
    def initialize_hwinfo_system_settings_dialogs(include_target)
      Yast.import "UI"

      Yast.import "CWM"
      Yast.import "CWMTab"
      Yast.import "Label"
      Yast.import "Arch"
      Yast.import "Wizard"
      Yast.import "Mode"

      textdomain "tune"

      Yast.include include_target, "hwinfo/newid.rb"
      Yast.include include_target, "hwinfo/system_settings_ui.rb"

      @contents = VBox("tab")

      # whether to show I/O device autoconfig checkbox
      has_autoconf = Arch.s390

      kernel_widget_names = ["sysrq"]
      kernel_widgets = [VSpacing(1), Left("sysrq")]

      if has_autoconf
        kernel_widget_names << "autoconf"
        kernel_widgets << VSpacing(1) << Left("autoconf")
      end

      @tabs_descr = {
        "pci_id"          => {
          "header"       => NewPCIIDDialogCaption(),
          "contents"     => HBox(
            HSpacing(1),
            VBox(VSpacing(0.3), "pci_id_table_and_buttons", VSpacing(0.3)),
            HSpacing(1)
          ),
          "widget_names" => ["pci_id_table_and_buttons"]
        },
        "kernel_settings" => {
          "header"       => _("Kernel Settings"),
          "contents"     => VBox(
            HBox(
              HSpacing(1),
              VBox(*kernel_widgets),
              HSpacing(1)
            ),
            VStretch()
          ),
          "widget_names" => kernel_widget_names
        }
      }

      @initial_tab = "pci_id"

      @widget_names = ["tab"]
      @widget_descr = {
        "pci_id_table_and_buttons" => {
          "widget"        => :custom,
          "custom_widget" => NewPCIIDDialogContent(),
          "help"          => NewPCIIDDialogHelp(),
          "init"          => fun_ref(
            method(:InitNewPCIIDDialog),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleNewPCIIDDialog),
            "symbol (string, map)"
          )
        },
        # .sysconfig.sysctl
        "sysrq"                    => {
          "widget" => :checkbox,
          "label"  => _("Enable &SysRq Keys"),
          "store"  => fun_ref(method(:StoreSysRqSettings), "void (string, map)"),
          "init"   => fun_ref(method(:InitSysRqSettings), "void (string)"),
          # TRANSLATORS: Help text - over taken from /etc/sysconfig/sysctl file
          "help"   => _(
            "<p><b><big>Enable SysRq Keys</big></b><br>\n" +
              "If you enable SysRq keys, you will have some control over the system even if it\n" +
              "crashes (such as during kernel debugging). If it is enabled, the key combination\n" +
              "Alt-SysRq-<command_key> will start the respective command (e.g. reboot the\n" +
              "computer, dump kernel information). For further information, see\n" +
              "<tt>/usr/src/linux/Documentation/sysrq.txt</tt> (package kernel-source).</p>\n"
          )
        },
        "autoconf"                    => {
          "widget" => :checkbox,
          "label"  => _("Enable I/O device auto-configuration"),
          "store"  => fun_ref(method(:StoreAutoConfSettings), "void (string, map)"),
          "init"   => fun_ref(method(:InitAutoConfSettings), "void (string)"),
          "help"   => _(
            "<p><b><big>Enable I/O device auto-configuration</big></b><br>\n" +
            "Disable <b>I/O device auto-configuration</b>\n" +
            "if you don't want any existing I/O auto-configuration data to be applied.</p>\n"
          )
        }
      }
    end

    def SystemSettingsDialog
      tab_order = ["kernel_settings"]

      # do not show PCI ID tab on s390
      if !Arch.s390
        tab_order = Builtins.prepend(tab_order, "pci_id")
      else
        # remove the PCI ID tab definition
        @tabs_descr = Builtins.remove(@tabs_descr, "pci_id")

        # set focus to kernel_settings tab
        @initial_tab = "kernel_settings"
      end

      Ops.set(
        @widget_descr,
        "tab",
        CWMTab.CreateWidget(
          {
            "tab_order"    => tab_order,
            "tabs"         => @tabs_descr,
            "widget_descr" => @widget_descr,
            "initial_tab"  => @initial_tab
          }
        )
      )

      # explicitly set no help (otherwise CWM logs an error)
      Ops.set(@widget_descr, ["tab", "help"], "")

      caption = _("Kernel Settings")

      Wizard.SetContentsButtons(
        "",
        VBox(),
        "",
        Label.BackButton,
        Label.NextButton
      )
      Wizard.DisableBackButton
      Wizard.SetDesktopIcon("org.opensuse.yast.SystemSettings")

      ret = CWM.ShowAndRun(
        {
          "widget_descr" => @widget_descr,
          "widget_names" => @widget_names,
          "contents"     => @contents,
          "caption"      => caption,
          # hide back button
          "back_button"  => "",
          "abort_button" => Label.CancelButton,
          "next_button"  => Label.OKButton
        }
      )

      if ret != :back && ret != :abort && ret != :cancel
        @initial_tab = CWMTab.CurrentTab
      end
      Builtins.y2milestone("Returning %1", ret)

      ret
    end
  end
end
