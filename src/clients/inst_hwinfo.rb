# encoding: utf-8

#
# Module:	Initial hwinfo
#
# Author:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# Initial hwinfo module - configuration workflow
module Yast
  class InstHwinfoClient < Client
    def main
      Yast.import "UI"

      textdomain "tune"

      Yast.import "InitHWinfo"
      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "Report"
      Yast.import "Popup"
      Yast.import "Sequencer"
      Yast.import "Stage"
      Yast.import "Arch"

      Yast.include self, "hwinfo/routines.rb"
      Yast.include self, "hwinfo/classnames.rb"
      Yast.include self, "hwinfo/system_settings_ui.rb"
      Yast.include self, "hwinfo/system_settings_dialogs.rb"

      @selected_model = ""
      @selected_info = {}
      @selected_device = nil

      #*************************************
      #
      #            Main part
      #
      #************************************

      # aliases for wizard sequncer
      @aliases = {
        "detected" => lambda { detected_dialog },
        "details"  => [lambda { details_dialog(@selected_model, @selected_info) }, true],
        "newid"    => [lambda { SystemSettingsDialog() }, true],
        "activate" => lambda { ActivateSystemSetting() }
      }

      # workflow sequence
      @sequence = {
        "ws_start" => "detected",
        "detected" => {
          :abort   => :abort,
          :ok      => "activate",
          :details => "details",
          :newid   => "newid"
        },
        "details"  => { :abort => :abort, :ok => "detected" },
        "newid"    => { :abort => :abort, :next => "detected" },
        "activate" => { :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopIcon("hwinfo")

      # start workflow
      @ret = Sequencer.Run(@aliases, @sequence)

      Wizard.CloseDialog

      deep_copy(@ret)
    end

    # Show detail dialog for selected device
    # @param [String] model hardware description (used in the tree widget
    # as a root node)
    # @param [Hash] info hardware description returned by .probe agent
    # @return [Symbol] UserInput() value
    def details_dialog(model, info)
      info = deep_copy(info)
      # convert information in the map to tree widget content
      l = [Item(model, true, expandTree(info))]

      content = VBox(
        # tree widget label
        Tree(_("&Details"), l)
      )

      Wizard.HideBackButton
      Wizard.HideAbortButton
      Wizard.SetNextButton(:ok, Label.OKButton)

      # help text
      help_text = _(
        "<P><B>Details</B></P><P>The details of the selected hardware component are displayed here.</P>"
      )

      # heading text, %1 is component name (e.g. "USB UHCI Root Hub")
      Wizard.SetContents(
        Builtins.sformat(_("Component '%1'"), model),
        content,
        help_text,
        true,
        true
      )
      Wizard.SetTitleIcon("hardware_info") if Stage.initial

      Builtins.y2debug("tree content: %1", l)

      ret = :dummy
      while ret != :ok && ret != :close
        ret = Convert.to_symbol(UI.UserInput)
      end

      ret = :bort if ret == :close

      Wizard.RestoreNextButton
      Wizard.RestoreAbortButton
      Wizard.RestoreBackButton

      ret
    end

    # Show summary dialog with all detected hardware
    # @return [Symbol] UserInput() value
    def detected_dialog
      # this block is evaluated before each hardware class detection
      abortblock = lambda { UI.PollInput == :abort && Popup.ReallyAbort(false) }

      hw = InitHWinfo.DetectedHardware(false, abortblock)

      if hw == nil
        # detection was aborted
        return :abort
      end

      # create table content
      table_cont = []

      Builtins.foreach(hw) do |info|
        # device model name fallback
        model = Ops.get_locale(info, "model", _("Unknown device"))
        uniq = Ops.get_string(info, ["info", "unique_key"], "unknown")
        _class = Ops.get_integer(info, ["info", "class_id"], 255)
        subclass = Ops.get_integer(info, ["info", "sub_class_id"], 0)
        # find subclass name
        cls = Ops.get_string(@ClassNames, [_class, subclass])
        # try to use class name if subclass name wasn't found
        cls = Ops.get_string(@ClassNames, [_class, "name"]) if cls == nil
        # set to "unknown" if class name wasn't found too
        if cls == nil
          # device class is unknown
          cls = _("Unknown device class")
        end
        table_cont = Builtins.add(table_cont, Item(Id(uniq), cls, model))
      end if Ops.greater_than(
        Builtins.size(hw),
        0
      )

      Builtins.y2debug("table content: %1", table_cont)

      content = VBox(
        # table header
        Table(Id(:hwtable), Header(_("Class"), _("Model")), table_cont),
        VSpacing(0.4),
        HBox(
          # push button label
          PushButton(Id(:newid), _("&Kernel Settings...")),
          HSpacing(4),
          # push button label
          PushButton(Id(:details), _("&Details...")),
          PushButton(Id(:file), _("Save to &File..."))
        ),
        VSpacing(1)
      )

      # help text - part 1/3
      help_text = _(
        "<P><B>Detected Hardware</B><BR>This table contains all hardware components detected in your system.</P>"
      ) +
        # help text - part 2/3
        _(
          "<P><B>Details</B><BR>Select a component and press <B>Details</B> to see a more detailed description of the component.</P>"
        ) +
        # help text - part 3/3
          _(
            "<P><B>Save to File</B><BR>You can save\n    hardware information (<I>hwinfo</I> output) to a file.</P>"
          )

      Wizard.HideBackButton
      Wizard.HideAbortButton
      Wizard.SetNextButton(:ok, Label.OKButton)

      # heading text
      Wizard.SetContents(_("Detected Hardware"), content, help_text, true, true)

      # preselect last selected device
      if @selected_device != nil
        UI.ChangeWidget(Id(:hwtable), :CurrentItem, @selected_device)
      end

      ret = :dummy

      while ret != :ok && ret != :details && ret != :newid
        ret = Convert.to_symbol(UI.UserInput)

        Builtins.y2debug("UserInput: %1", ret)

        if ret == :details || ret == :hwtable
          @selected_device = Convert.to_string(
            UI.QueryWidget(Id(:hwtable), :CurrentItem)
          )

          if @selected_device != nil
            device_info = Builtins.find(hw) do |i|
              Ops.get_string(i, ["info", "unique_key"]) == @selected_device
            end

            if device_info != nil
              # remember selected device
              @selected_info = Ops.get_map(device_info, "info", {})
              # device model is unknown
              @selected_model = Ops.get_locale(
                device_info,
                "model",
                _("Unknown device")
              )
            else
              ret = :dummy
            end
          else
            ret = :dummy
          end
        elsif ret == :file
          # save to file
          save_hwinfo_to_file("/hwinfo.out")
        end
      end

      Wizard.RestoreNextButton
      Wizard.RestoreAbortButton
      Wizard.RestoreBackButton

      Builtins.y2debug("detected_dialog result: %1", ret)

      ret
    end

    # only activate the settings,
    # the configuration is written in system_settings_finish.ycp
    def ActivateSystemSetting
      SystemSettings.Activate

      :next
    end
  end
end

Yast::InstHwinfoClient.new.main
