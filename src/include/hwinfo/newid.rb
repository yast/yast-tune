# encoding: utf-8

# File:
#   newid.ycp
#
# Summary:
#   Configuration of PCI ID - User interface
#
# Authors:
#   Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
module Yast
  module HwinfoNewidInclude
    def initialize_hwinfo_newid(include_target)
      Yast.import "UI"

      textdomain "tune"

      Yast.import "Wizard"
      Yast.import "NewID"
      Yast.import "Report"

      Yast.import "Popup"
      Yast.import "Label"
      Yast.import "Mode"

      Yast.include include_target, "hwinfo/routines.rb"

      # FIXME: move to the NewID.ycp module
      # PCI ID settings have been changed
      @pci_id_changed = false

      @handle_function_returns = nil
    end

    def ReadSettings
      NewID.Read("/etc/sysconfig/hardware/newids")
      :next
    end

    def WriteSettings
      NewID.Write ? :next : :abort
    end

    # Return list of items for table widget
    # @return [Array] List of items
    def get_table_items
      ids = NewID.GetNewIDs

      # prepare table items
      table_items = []
      id = 0

      Builtins.foreach(ids) do |newid|
        # IDs for selected PCI device
        newid = NewID.AddIDs(newid) if Builtins.haskey(newid, "uniq")
        table_items = Builtins.add(
          table_items,
          Item(
            Id(id),
            Ops.get_string(newid, "driver", ""),
            NewID.GetModelString(Ops.get_string(newid, "uniq", "")),
            add_hex_prefix(Ops.get_string(newid, "vendor", "")),
            add_hex_prefix(Ops.get_string(newid, "device", "")),
            add_hex_prefix(Ops.get_string(newid, "subvendor", "")),
            add_hex_prefix(Ops.get_string(newid, "subdevice", "")),
            add_hex_prefix(Ops.get_string(newid, "class", "")),
            add_hex_prefix(Ops.get_string(newid, "class_mask", "")),
            Ops.get_string(newid, "sysdir", "")
          )
        )
        id = Ops.add(id, 1)
      end if ids != nil

      deep_copy(table_items)
    end


    def GetIdValue(widget)
      ret = Convert.to_string(UI.QueryWidget(Id(widget), :Value))

      ret = "" if ret == nil

      ret
    end

    def NewIDPopup(newid)
      newid = deep_copy(newid)
      # ask user to support new device
      new_id_dialog = VBox(
        VSpacing(0.4),
        # text in dialog header
        Heading(_("PCI ID Setup")),
        VSpacing(0.5),
        HBox(
          HSpacing(1),
          VBox(
            # textentry label
            TextEntry(
              Id(:driver),
              _("&Driver"),
              Ops.get_string(newid, "driver", "")
            ),
            VSpacing(0.5),
            # textentry label
            TextEntry(
              Id(:vendor),
              _("&Vendor"),
              Ops.get_string(newid, "vendor", "")
            ),
            VSpacing(0.5),
            # textentry label
            TextEntry(
              Id(:subvendor),
              _("&Subvendor"),
              Ops.get_string(newid, "subvendor", "")
            ),
            VSpacing(0.5),
            # textentry label
            TextEntry(
              Id(:class),
              _("&Class"),
              Ops.get_string(newid, "class", "")
            )
          ),
          HSpacing(1.5),
          VBox(
            # textentry label
            TextEntry(
              Id(:sysdir),
              _("Sys&FS Directory"),
              Ops.get_string(newid, "sysdir", "")
            ),
            VSpacing(0.5),
            # textentry label
            TextEntry(
              Id(:device),
              _("&Device"),
              Ops.get_string(newid, "device", "")
            ),
            VSpacing(0.5),
            # textentry label
            TextEntry(
              Id(:subdevice),
              _("S&ubdevice"),
              Ops.get_string(newid, "subdevice", "")
            ),
            VSpacing(0.5),
            # textentry label
            TextEntry(
              Id(:class_mask),
              _("Class &Mask"),
              Ops.get_string(newid, "class_mask", "")
            )
          ),
          HSpacing(1)
        ),
        VSpacing(1),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        ),
        VSpacing(0.4)
      )

      UI.OpenDialog(new_id_dialog)

      # allow only hex numbures
      hexchars = "0123456789abcdefABCDEFx"
      UI.ChangeWidget(Id(:vendor), :ValidChars, hexchars)
      UI.ChangeWidget(Id(:subvendor), :ValidChars, hexchars)
      UI.ChangeWidget(Id(:device), :ValidChars, hexchars)
      UI.ChangeWidget(Id(:subdevice), :ValidChars, hexchars)
      UI.ChangeWidget(Id(:class), :ValidChars, hexchars)
      UI.ChangeWidget(Id(:class_mask), :ValidChars, hexchars)

      ui = nil
      ret = {}
      begin
        ui = Convert.to_symbol(UI.UserInput)

        if ui == :ok
          # read and set values
          vendor = GetIdValue(:vendor)
          subvendor = GetIdValue(:subvendor)
          device = GetIdValue(:device)
          subdevice = GetIdValue(:subdevice)
          _class = GetIdValue(:class)
          class_mask = GetIdValue(:class_mask)
          driver = Convert.to_string(UI.QueryWidget(Id(:driver), :Value))
          sysdir = Convert.to_string(UI.QueryWidget(Id(:sysdir), :Value))

          if driver == "" && sysdir == ""
            # error message, driver name and sysfs directory are empty. one is needed
            Report.Error(_("Enter the driver or SysFS directory name."))
            ui = nil
          elsif vendor == "" && subvendor == "" && device == "" &&
              subdevice == "" &&
              class_mask == "" &&
              _class == ""
            # error message, user didn't fill any PCI ID value
            Report.Error(_("At least one PCI ID value is required."))
            ui = nil
          else
            ret = {
              "ui"    => :ok,
              "newid" => {
                "vendor"     => vendor,
                "device"     => device,
                "subvendor"  => subvendor,
                "subdevice"  => subdevice,
                "class"      => _class,
                "class_mask" => class_mask,
                "driver"     => driver,
                "sysdir"     => sysdir
              }
            }
          end
        elsif ui == :close || ui == :cancel
          ret = { "ui" => :cancel }
        end
      end while ui != :ok && ui != :cancel && ui != :close

      UI.CloseDialog

      deep_copy(ret)
    end

    def pci_items(selected_uniq)
      ret = []

      pcidevices = NewID.GetPCIdevices

      Builtins.foreach(pcidevices) do |pcidev|
        uniq = Ops.get_string(pcidev, "unique_key", "")
        model = Ops.get_string(pcidev, "model", "")
        busid = Ops.get_string(pcidev, "sysfs_bus_id", "")
        if uniq != "" && model != "" && busid != ""
          ret = Builtins.add(
            ret,
            Item(
              Id(uniq),
              Builtins.sformat("%1 (%2)", model, busid),
              uniq == selected_uniq
            )
          )
        end
      end 


      deep_copy(ret)
    end

    def NewDeviceIDPopup(newid)
      newid = deep_copy(newid)
      # ask user to support new device
      new_id_dialog = VBox(
        VSpacing(0.4),
        # text in dialog header
        Heading(_("PCI ID Setup")),
        VSpacing(0.5),
        HBox(
          HSpacing(1),
          # textentry label
          TextEntry(
            Id(:driver),
            _("&Driver"),
            Ops.get_string(newid, "driver", "")
          ),
          HSpacing(1.5),
          # textentry label
          TextEntry(
            Id(:sysdir),
            _("Sys&FS Directory"),
            Ops.get_string(newid, "sysdir", "")
          ),
          HSpacing(1)
        ),
        VSpacing(1),
        HBox(
          HSpacing(1),
          ComboBox(
            Id(:pcidevices),
            _("PCI &Device"),
            pci_items(Ops.get_string(newid, "uniq", ""))
          ),
          HSpacing(1)
        ),
        VSpacing(1),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        ),
        VSpacing(0.4)
      )

      UI.OpenDialog(new_id_dialog)

      ui = nil
      ret = {}
      begin
        ui = Convert.to_symbol(UI.UserInput)

        if ui == :ok
          # read and set values
          driver = Convert.to_string(UI.QueryWidget(Id(:driver), :Value))
          sysdir = Convert.to_string(UI.QueryWidget(Id(:sysdir), :Value))
          uniq = Convert.to_string(UI.QueryWidget(Id(:pcidevices), :Value))

          if driver == "" && sysdir == ""
            # error message, driver name and sysfs directory are empty
            Report.Error(_("Enter the driver or SysFS directory name."))
            ui = nil
          else
            ret = {
              "ui"    => :ok,
              "newid" => {
                "uniq"   => uniq,
                "driver" => driver,
                "sysdir" => sysdir
              }
            }
          end
        elsif ui == :close || ui == :cancel
          ret = { "ui" => :cancel }
        end
      end while ui != :ok && ui != :cancel && ui != :close

      UI.CloseDialog

      deep_copy(ret)
    end

    # bugzilla #237339
    def AdjustDialogButtons(count_of_items_in_table)
      # at least one PCIID defined
      if Ops.greater_than(count_of_items_in_table, 0)
        UI.ChangeWidget(Id(:edit), :Enabled, true)
        UI.ChangeWidget(Id(:delete), :Enabled, true) 
        # nothing listed, disabling buttons
      else
        UI.ChangeWidget(Id(:edit), :Enabled, false)
        UI.ChangeWidget(Id(:delete), :Enabled, false)
      end

      nil
    end

    def RefreshTableContent
      items = get_table_items

      UI.ChangeWidget(:newid_table, :Items, items)
      AdjustDialogButtons(Builtins.size(items))

      nil
    end

    def NewPCIIDDialogContent
      VBox(
        # table header, use as short texts as possible
        Table(
          Id(:newid_table),
          Header(
            _("Driver"),
            _("Card Name"),
            _("Vendor"),
            _("Device"),
            # table header, use as short texts as possible
            _("Subvendor"),
            _("Subdevice"),
            _("Class"),
            _("Class Mask"),
            _("SysFS Dir.")
          )
        ),
        VSpacing(0.5),
        HBox(
          MenuButton(
            Ops.add(Label.AddButton, "..."),
            [
              Item(Id(:add_selected), _("&From List")),
              Item(Id(:add), _("&Manually"))
            ]
          ),
          HSpacing(1),
          PushButton(Id(:edit), Label.EditButton),
          HSpacing(1),
          PushButton(Id(:delete), Label.DeleteButton),
          HStretch()
        ),
        VSpacing(0.5)
      )
    end

    def NewPCIIDDialogHelp
      # bugzilla #237379
      button_label = Mode.installation || Mode.config ?
        Label.OKButton :
        Label.FinishButton
      if Builtins.regexpmatch(button_label, "&")
        button_label = Builtins.regexpsub(button_label, "(.*)&(.*)", "\\1\\2")
      end

      Ops.add(
        Ops.add(
          # help text header
          _("<P><B>PCI ID Setup</B><BR></P>") +
            # PCI ID help text
            _(
              "<P>It is possible to add a PCI ID to a device driver to extend its internal database of known supported devices.</P>"
            ) +
            # PCI ID help text
            _(
              "<P>PCI ID numbers are entered and displayed as hexadecimal numbers. <b>SysFS Dir.</b> is the directory name in the /sys/bus/pci/drivers directory. If it is empty, the driver name is used as the directory name.</P>"
            ) +
            # PCI ID help text
            _(
              "<P>If the driver is compiled into the kernel, leave the driver name empty and enter the SysFS directory name instead.</P>"
            ),
          Builtins.sformat(
            # PCI ID help text, %1 stands for a button name (OK or Finish -- depends on the situation)
            _(
              "<P>Use the buttons below the table to change the list of PCI IDs. Press <b>%1</b> to activate the settings.</P>"
            ),
            button_label
          )
        ),
        # PCI ID help text
        _(
          "<P><B>Warning:</B> This is an expert configuration. Only continue if you know what you are doing.</P>"
        )
      )
    end

    def NewPCIIDDialogCaption
      # dialog header
      _("PCI ID Setup")
    end

    def InitNewPCIIDDialog(id)
      Wizard.DisableBackButton
      Builtins.y2milestone("Init: %1", id)
      items = get_table_items
      UI.ChangeWidget(Id(:newid_table), :Items, items)
      AdjustDialogButtons(Builtins.size(items))

      nil
    end

    # Function sets whether PCI ID settings have been changed
    def SetNewPCIIDChanged(changed)
      @pci_id_changed = changed

      nil
    end

    # Function returns whether PCI ID settings have been changed
    def GetNewPCIIDChanged
      @pci_id_changed
    end
    def HandleNewPCIIDDialog(key, event)
      event = deep_copy(event)
      # we serve only PC_ID settings
      return nil if key != "pci_id_table_and_buttons"
      return nil if Ops.get(event, "ID") == "kernel_settings"

      Builtins.y2milestone("Key: %1, Event: %2", key, event)

      handle_function_returns = Ops.get(event, "ID")

      if handle_function_returns == nil
        Builtins.y2warning("Unknown event")
      elsif handle_function_returns == :back
        # returning back
        handle_function_returns = :back
      elsif handle_function_returns == :next
        # activate the settings
        NewID.Activate
        # returning next
        handle_function_returns = :next
      elsif handle_function_returns == :cancel
        if GetNewPCIIDChanged()
          if Popup.ReallyAbort(true) == false
            # loop - continue
            handle_function_returns = :continue
          end
        end
        # returning abort
        handle_function_returns = :abort
      elsif handle_function_returns == :add ||
          handle_function_returns == :add_selected
        result = handle_function_returns == :add ?
          NewIDPopup({}) :
          NewDeviceIDPopup({})

        if Ops.get_symbol(result, "ui", :cancel) == :ok
          # add new id
          NewID.AddID(Ops.get_map(result, "newid", {}))

          # refresh table content
          RefreshTableContent()
        end
      elsif handle_function_returns == :edit
        curr = Convert.to_integer(
          UI.QueryWidget(Id(:newid_table), :CurrentItem)
        )
        nid = NewID.GetNewID(curr)

        result = Builtins.haskey(nid, "uniq") ?
          NewDeviceIDPopup(nid) :
          NewIDPopup(nid)

        if Ops.get_symbol(result, "ui", :cancel) == :ok
          NewID.SetNewID(Ops.get_map(result, "newid", {}), curr)
          RefreshTableContent()
          UI.ChangeWidget(Id(:newid_table), :CurrentItem, curr)
        end
      elsif handle_function_returns == :delete
        curr = Convert.to_integer(
          UI.QueryWidget(Id(:newid_table), :CurrentItem)
        )
        NewID.RemoveID(curr)

        RefreshTableContent()

        numids = Builtins.size(NewID.GetNewIDs)

        # preselect the nearest line to deleted one if possible
        if Ops.greater_than(numids, 0)
          curr = Ops.subtract(numids, 1) if Ops.greater_or_equal(curr, numids)

          UI.ChangeWidget(Id(:newid_table), :CurrentItem, curr)
        end
      end

      Builtins.y2milestone("Returning %1", handle_function_returns)

      nil
    end

    # Main PCI ID configuration dialog
    # @return [Object] Result from UserInput()
    def NewIDConfigDialog
      Wizard.SetContents(
        NewPCIIDDialogCaption(),
        NewPCIIDDialogContent(),
        NewPCIIDDialogHelp(),
        true,
        true
      )
      Wizard.DisableBackButton
      Wizard.SetNextButton(:next, Label.OKButton)

      InitNewPCIIDDialog("pci_id_table_and_buttons")

      @handle_function_returns = nil
      while true
        @handle_function_returns = Convert.to_symbol(UI.UserInput)
        HandleNewPCIIDDialog(
          "pci_id_table_and_buttons",
          { "ID" => @handle_function_returns }
        )
        # breaking the loop
        if @handle_function_returns == :back ||
            @handle_function_returns == :next ||
            @handle_function_returns == :abort
          break
        end
      end

      Builtins.y2milestone("New PCI ID: %1", @handle_function_returns)
      @handle_function_returns
    end
  end
end
