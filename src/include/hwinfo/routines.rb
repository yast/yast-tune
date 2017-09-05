# encoding: utf-8

# File:	routines.ycp
#
# Author:	Ladislav Slezak <lslezak@suse.cz>
# $Id$
#
# Functions used in hwinfo and in init_hwinfo modules.
module Yast
  module HwinfoRoutinesInclude
    def initialize_hwinfo_routines(include_target)
      Yast.import "UI"

      textdomain "tune"

      Yast.import "Report"

      Yast.include include_target, "hwinfo/classnames.rb"

      # translation table- key is replaced by value on it's way to ui
      # must be done this way, because keys are machine-generated
      @trans_table = Builtins.eval(
        {
          # tree node string
          "architecture"               => [
            _("Architecture"),
            "yast-hardware"
          ],
          # tree node string - means "hardware bus"
          "bus"                        => [
            _("Bus"),
            "yast-hardware"
          ],
          # tree node string - means "hardware bus ID"
          "bus_id"                     => [
            _("Bus ID"),
            "yast-hardware"
          ],
          # tree node string
          "card_type"                  => [
            _("Card Type"),
            "yast-hardware"
          ],
          # tree node string
          "cardtype"                   => [
            _("Card Type"),
            "yast-hardware"
          ],
          # tree node string - means "class of hardware"
          "class_id"                   => [
            _("Class"),
            "yast-hardware"
          ],
          # tree node string
          "cdtype"                     => [
            _("CD Type"),
            "yast-cd"
          ],
          # tree node string
          "dev_name"                   => [
            _("Device Name"),
            "yast-hardware"
          ],
          # tree node string
          "dev_num"                    => [
            _("Device Numbers"),
            "yast-hardware"
          ],
          # tree node string
          "sysfs_id"                   => [
            _("Sysfs ID"),
            "yast-hardware"
          ],
          # tree node string
          "device"                     => [
            _("Device"),
            "yast-hardware"
          ],
          # tree node string
          "device_id"                  => [
            _("Device Identifier"),
            "yast-hardware"
          ],
          # tree node string - means "hardware drivers"
          "drivers"                    => [
            _("Drivers"),
            "yast-hardware"
          ],
          # tree node string - means "hardware driver"
          "driver"                     => [
            _("Driver"),
            "yast-hardware"
          ],
          # tree node string
          "type"                       => [
            _("Type"),
            "yast-hardware"
          ],
          # tree node string
          "major"                      => [
            _("Major"),
            "yast-partitioning"
          ],
          # tree node string
          "minor"                      => [
            _("Minor"),
            "yast-partitioning"
          ],
          # tree node string
          "range"                      => [
            _("Range"),
            "yast-hardware"
          ],
          # tree node string (System Management BIOS)
          "smbios"                     => [
            _("SMBIOS"),
            "yast-hardware"
          ],
          # tree node string
          "prog_if"                    => [
            _("Interface"),
            "yast-hardware"
          ],
          # tree node string
          "resource"                   => [
            _("Resources"),
            "yast-hardware"
          ],
          # tree node string
          "requires"                   => [
            _("Requires"),
            "yast-hardware"
          ],
          # tree node string
          "rev"                        => [
            _("Revision"),
            "yast-hardware"
          ],
          # tree node string - location of hardware in the machine
          "slot_id"                    => [
            _("Slot ID"),
            "yast-hardware"
          ],
          # tree node string
          "length"                     => [
            _("Length"),
            "yast-hardware"
          ],
          # tree node string
          "width"                      => [
            _("Width"),
            "yast-hardware"
          ],
          # tree node string
          "height"                     => [
            _("Height"),
            "yast-hardware"
          ],
          # tree node string
          "active"                     => [
            _("Active"),
            "yast-hardware"
          ],
          # tree node string
          "dev_names"                  => [
            _("Device Names"),
            "yast-hardware"
          ],
          # tree node string (number of colors)
          "color"                      => [
            _("Colors"),
            "yast-hardware"
          ],
          # tree node string (harddisk parameter)
          "disk_log_geo"               => [
            _("Logical Geometry"),
            "yast-hardware"
          ],
          # tree node string
          "count"                      => [
            _("Count"),
            "yast-hardware"
          ],
          # tree node string
          "mode"                       => [
            _("Mode"),
            "yast-hardware"
          ],
          # tree node string (interrupt request)
          "irq"                        => [
            _("IRQ"),
            "yast-hardware"
          ],
          # tree node string
          "io"                         => [
            _("IO Port"),
            "yast-hardware"
          ],
          # tree node string
          "mem"                        => [
            _("Memory"),
            "yast-hardware"
          ],
          # tree node string (direct memory access)
          "dma"                        => [
            _("DMA"),
            "yast-hardware"
          ],
          # tree node string
          "bus_hwcfg"                  => [
            _("Hwcfg Bus"),
            "yast-hardware"
          ],
          # tree node string
          "sysfs_bus_id"               => [
            _("Sysfs ID"),
            "yast-hardware"
          ],
          # tree node string
          "parent_unique_key"          => [
            _("Parent Unique ID"),
            "yast-hardware"
          ],
          # tree node string
          "udi"                        => [
            _("UDI"),
            "yast-hardware"
          ],
          # tree node string
          "uniqueid"                   => [
            _("Unique ID"),
            "yast-x11"
          ],
          # tree node string (monitor parameter)
          "vfreq"                      => [
            _("Vertical Frequency"),
            "yast-x11"
          ],
          # tree node string (monitor parameter)
          "max_hsync"                  => [
            _("Max. Horizontal Frequency"),
            "yast-x11"
          ],
          # tree node string (monitor parameter)
          "max_vsync"                  => [
            _("Max. Vertical Frequency"),
            "yast-x11"
          ],
          # tree node string (monitor parameter)
          "min_hsync"                  => [
            _("Min. Horizontal Frequency"),
            "yast-x11"
          ],
          # tree node string (monitor parameter)
          "min_vsync"                  => [
            _("Min. Vertical Frequency"),
            "yast-x11"
          ],
          # tree node string
          "dvd"                        => [
            _("DVD"),
            "yast-cdrom"
          ],
          # tree node string
          "driver_module"              => [
            _("Kernel Driver"),
            "yast-hardware"
          ],
          # tree node string
          "hwaddr"                     => [
            _("HW Address"),
            "yast-hardware"
          ],
          # tree node string
          "bios_id"                    => [
            _("BIOS ID"),
            "yast-hardware"
          ],
          # tree node string
          "enabled"                    => [
            _("Enabled"),
            "yast-hardware"
          ],
          # tree node string (monitor resolution e.g. 1280x1024)
          "monitor_resol"              => [
            _("Resolution"),
            "yast-x11"
          ],
          # tree node string
          "size"                       => [
            _("Size"),
            "yast-x11"
          ],
          # tree node string
          "old_unique_key"             => [
            _("Old Unique Key"),
            "yast-x11"
          ],
          # tree node string
          "sub_class_id"               => [
            _("Class (spec)"),
            "yast-x11"
          ],
          # tree node string
          "sub_device"                 => [
            _("Device (spec)"),
            "yast-x11"
          ],
          # tree node string
          "sub_device_id"              => [
            _("Device Identifier (spec)"),
            "yast-x11"
          ],
          # tree node string
          "sub_vendor"                 => [
            _("Subvendor"),
            "yast-x11"
          ],
          # tree node string
          "sub_vendor_id"              => [
            _("Subvendor Identifier"),
            "yast-x11"
          ],
          # tree node string
          "unique_key"                 => [
            _("Unique Key"),
            "yast-x11"
          ],
          # tree node string
          "vendor"                     => [
            _("Vendor"),
            "yast-x11"
          ],
          # tree node string
          "bios_video"                 => [
            _("BIOS Video"),
            "yast-x11"
          ],
          # tree node string
          "boot_arch"                  => [
            _("Boot Architecture"),
            "yast-bootloader"
          ],
          # tree node string
          "boot_disk"                  => [
            _("Boot Disk"),
            "yast-bootloader"
          ],
          # tree node string
          "block"                      => [
            _("Block Devices"),
            "yast-disk"
          ],
          # tree node string
          "redasd"                     => [
            _("DASD Disks"),
            "yast-dasd"
          ],
          # tree node string
          "cdrom"                      => [
            _("CD-ROM"),
            "yast-cdrom"
          ],
          # tree node string
          "cpu"                        => [
            _("CPU"),
            "yast-hardware"
          ],
          # tree node string
          "disk"                       => [
            _("Disk"),
            "yast-disk"
          ],
          # tree node string
          "display"                    => [
            _("Display"),
            "yast-x11"
          ],
          # tree node string
          "floppy"                     => [
            _("Floppy Disk"),
            "yast-floppy"
          ],
          # tree node string
          "framebuffer"                => [
            _("Framebuffer"),
            "yast-x11"
          ],
          # tree node string (powermanagement)
          "has_apm"                    => [
            _("Has APM"),
            "yast-power-management"
          ],
          # tree node string
          "has_pcmcia"                 => [
            _("Has PCMCIA"),
            "yast-hardware"
          ],
          # tree node string (multiprocessing)
          "has_smp"                    => [
            _("Has SMP"),
            "yast-hardware"
          ],
          # tree node string - UML = User Mode Linux
          "is_uml"                     => [
            _("UML System"),
            "yast-vm-management"
          ],
          # tree node string
          "ihw_data"                   => [
            _("Hardware Data"),
            "yast-hardware"
          ],
          # tree node string
          "isdn"                       => [
            _("ISDN"),
            "yast-isdn"
          ],
          # tree node string
          "keyboard"                   => [
            _("Keyboard"),
            "yast-keyboard"
          ],
          # tree node string
          "monitor"                    => [
            _("Monitor"),
            "yast-x11"
          ],
          # tree node string
          "netdev"                     => [
            _("Network Devices"),
            "yast-lan"
          ],
          # tree node string
          "netif"                      => [
            _("Network Interface"),
            "yast-lan"
          ],
          # tree node string
          "printer"                    => [
            _("Printer"),
            "yast-printer"
          ],
          # tree node string
          "modem"                      => [
            _("Modem"),
            "yast-modem"
          ],
          # tree node string
          "sound"                      => [
            _("Sound"),
            "yast-sound"
          ],
          # tree node string
          "storage"                    => [
            _("Storage Media"),
            "yast-disk"
          ],
          # tree node string
          "system"                     => [
            _("System"),
            "yast-hardware"
          ],
          # tree node string
          "tv"                         => [
            _("TV Card"),
            "yast-tv"
          ],
          # tree node string
          "dvb"                        => [
            _("DVB Card"),
            "yast-tv"
          ],
          # tree node string
          "usb_type"                   => [
            _("USB Type"),
            "yast-hardware"
          ],
          # tree node string
          "version"                    => [
            _("Version"),
            "yast-hardware"
          ],
          # tree node string - memory (RAM) information
          "memory"                     => [
            _("Memory"),
            "yast-hardware"
          ],
          # tree node string
          "netcard"                    => [
            _("Network Card"),
            "yast-lan"
          ],
          # tree node string
          "bios"                       => [
            _("BIOS"),
            "yast-hardware"
          ],
          # tree node string
          "fbdev"                      => [
            _("Framebuffer Device"),
            "yast-x11"
          ],
          # tree node string - bus type
          "ide"                        => [
            _("IDE"),
            "yast-disk"
          ],
          # tree node string - bus type
          "pci"                        => [
            _("PCI"),
            "yast-hardware"
          ],
          # tree node string - bus type
          "usb"                        => [
            _("USB"),
            "yast-hardware"
          ],
          # tree node string - bus type
          "isapnp"                     => [
            _("ISA PnP"),
            "yast-hardware"
          ],
          # tree node
          "usbctrl"                    => [
            _("USB Controller"),
            "yast-hardware"
          ],
          # tree node
          "hub"                        => [
            _("USB Hub"),
            "yast-hardware"
          ],
          # tree node
          "ieee1394ctrl"               => [
            _("IEEE1394 Controller"),
            "yast-hardware"
          ],
          # tree node
          "scsi"                       => [
            _("SCSI"),
            "yast-hardware"
          ],
          # tree node
          "scanner"                    => [
            _("Scanner"),
            "yast-scanner"
          ],
          # tree node
          "mouse"                      => [_("Mouse"), "yast-mouse"],
          # tree node
          "joystick"                   => [
            _("Joystick"),
            "yast-joystick"
          ],
          # tree node
          "braille"                    => [
            _("Braille Display"),
            "yast-hardware"
          ],
          # tree node
          "chipcard"                   => [
            _("Chipcard Reader"),
            "yast-hardware"
          ],
          # tree node - Digital camera or WebCam
          "camera"                     => [
            _("Camera"),
            "yast-hardware"
          ],
          # Point-to-Point Protocol Over Ethernet
          "pppoe"                      => [
            _("PPP over Ethernet"),
            "yast-dsl"
          ],
          # tree node string - CPU information
          "bogomips"                   => [
            _("Bogus Millions of Instructions Per Second"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "cache"                      => [
            _("Cache"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "coma_bug"                   => [
            _("Coma Bug"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "f00f_bug"                   => [
            _("f00f Bug"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "cpuid_level"                => [
            _("CPU ID Level"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "mhz"                        => [
            _("Frequency"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "fdiv_bug"                   => [
            _("Floating point division bug"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "flags"                      => [
            _("Flags"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "fpu"                        => [
            _("Floating Point Unit"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "fpu_exception"              => [
            _("Floating Point Unit Exception"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "hlt_bug"                    => [
            _("Halt Bug"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "processor"                  => [
            _("Processor"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "stepping"                   => [
            _("Stepping"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "vendor_id"                  => [
            _("Vendor Identifier"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "family"                     => [
            _("Family"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "model"                      => [
            _("Model"),
            "yast-hardware"
          ],
          # tree node string - CPU information
          "wp"                         => [
            _("WP"),
            "yast-hardware"
          ],
          # tree node string - wireless network adapters
          "wlan"                       => [
            _("Wireless LAN"),
            "yast-wifi"
          ],
          # tree node string - tape devices
          "tape"                       => [
            _("Tape"),
            "yast-hardware"
          ],
          # tree node string - Bluetooth devices
          "bluetooth"                  => [
            _("Bluetooth"),
            "yast-bluetooth"
          ],
          # tree node string - DSL devices
          "dsl"                        => [
            _("DSL"),
            "yast-dsl"
          ],
          # tree node string - generic device name
          "Ethernet network interface" => [
            _("Ethernet Network Interface"),
            "yast-lan"
          ],
          # tree node string - generic device name
          "Network Interface"          => [
            _("Network Interface"),
            "yast-lan"
          ],
          # tree node string - generic device name
          "Loopback network interface" => [
            _("Loopback Network Interface"),
            "yast-lan"
          ],
          # tree node string - generic device name
          "Partition"                  => [
            _("Partition"),
            "yast-disk"
          ],
          # tree node string - generic device name
          "Floppy Disk"                => [
            _("Floppy Disk"),
            "yast-floppy"
          ],
          # tree node string - generic device name
          "Floppy disk controller"     => [
            _("Floppy Disk Controller"),
            "yast-floppy"
          ],
          # tree node string - generic device name
          "PnP Unclassified device"    => [
            _("PnP Unclassified Device"),
            "yast-hardware"
          ],
          # tree node string - generic device name
          "Unclassified device"        => [
            _("Unclassified Device"),
            "yast-hardware"
          ],
          # tree node string - generic device name
          "Main Memory"                => [
            _("Main Memory"),
            "yast-hardware"
          ],
          # tree node string - generic device name
          "UHCI Host Controller"       => [
            _("UHCI Host Controller"),
            "yast-hardware"
          ],
          # tree node string - generic device name
          "EHCI Host Controller"       => [
            _("EHCI Host Controller"),
            "yast-hardware"
          ],
          # tree node string - generic device name
          "OHCI Host Controller"       => [
            _("OHCI Host Controller"),
            "yast-hardware"
          ],
          # translate "probe" to empty string
          # search starts from .probe node which doesn't
          # contain any hardware information
          "probe"                      => [
            "",
            "yast-hardware"
          ]
        }
      )


      # order table: list of lists.
      # first item of nested list is key name
      # second is term that should be used for formating the key- takes key name as first argument
      # if third item is true, the whole map will be passed to term as second argument
      @representant_order = [
        "sub_device",
        "device",
        "model name",
        "model",
        "vendor",
        "irq",
        "start",
        "name",
        "xkbmodel",
        "server",
        "size",
        "unit",
        "width",
        "cylinders",
        "dev_name",
        "modules",
        "sub_class_id",
        "modules",
        "type"
      ]
    end

    # reads values from map and creates formatted label for monitor resolution data
    # @param [Object] a dummy parameter?
    # @param [Hash] m device info
    # @return [String] formatted label

    def resolution(a, m)
      a = deep_copy(a)
      m = deep_copy(m)
      if Builtins.haskey(m, "height")
        return Builtins.sformat(
          "%1x%2",
          Ops.get(m, "width"),
          Ops.get(m, "height")
        )
      end
      Ops.get_string(m, "width", "")
    end

    def modules(val)
      val = deep_copy(val)
      Builtins.y2warning("calling modules with param: %1", val)
      outlist = Builtins.maplist(val) do |e|
        Ops.add("modprobe ", Builtins.mergestring(e, " "))
      end
      deep_copy(outlist)
    end

    # tries to determine hardware name by class_id and sub_class_id
    # and substitues them in given map. returns modified map
    # @param [Hash{String => Object}] hw device info
    # @return [Hash] device info with translated class information

    def translate_hw_entry(hw)
      hw = deep_copy(hw)
      ret = deep_copy(hw)

      if Builtins.haskey(hw, "class_id")
        iclassid = Ops.get_integer(hw, "class_id", 255)
        classid = Ops.get_string(@ClassNames, [iclassid, "name"], "")

        ret = Builtins.add(ret, "class_id", classid)

        if Builtins.haskey(hw, "sub_class_id")
          isubclassid = Ops.get_integer(hw, "sub_class_id", 0)
          subclassid = Ops.get_string(@ClassNames, [iclassid, isubclassid], "")
          ret = Builtins.add(ret, "sub_class_id", subclassid)
        end
      end
      deep_copy(ret)
    end

    # Translate subclass identification of the device
    # @param [Object] a dummy parameter?
    # @param [Hash{String => Object}] m device information
    # @return [String] translated subclass name
    def classtostring(a, m)
      a = deep_copy(a)
      m = deep_copy(m)
      trans = translate_hw_entry(m)
      Ops.get_string(trans, "sub_class_id", "")
    end

    # translate string - looks to the translation table and returns value
    # @param [String] str string to translate
    # @return [String] translated string or original string if translation is unknown
    def trans_str(str)
      if !Builtins.haskey(@trans_table, str)
        Builtins.y2warning("Cannot translate string '%1'", str)
      end
      Ops.get(@trans_table, [str, 0], str)
    end

    # icon for path - looks to the translation table and returns value
    # @param [String] str string of the path
    # @return [String] icon name or nil if not found
    def icon(str)
      if !Builtins.haskey(@trans_table, str)
        Builtins.y2warning("Cannot find icon for string '%1'", str)
        return nil
      end
      Ops.get(@trans_table, [str, 1])
    end

    # translate boolean to Yes/No
    # @param [Object] b any value
    # @return [String] parameter b converted to string, if b is boolean then Yes/No is returned
    def trans_bool(b)
      b = deep_copy(b)
      if Ops.is_boolean?(b)
        # yes/no strings
        return b == true ? _("Yes") : _("No")
      end
      Builtins.sformat("%1", b)
    end

    # evals to true if given value is scalar (not map or term or list)
    # @param [Object] node any value
    # @return [Boolean] true if parameter node is a scalar value (it isn't a list or a map)

    def scalar(node)
      node = deep_copy(node)
      if Ops.is_string?(node) || Ops.is_boolean?(node) || Ops.is_integer?(node) ||
          Ops.is_float?(node) ||
          Ops.is_locale?(node) ||
          Ops.is_path?(node)
        return true
      end
      false
    end


    # if expandTree function tries to explore list, it should use some
    # label for each item. it tree items are maps, this function decides
    # which value from map will be used as label
    # @param [Hash{String => Object}] m device info
    # @return [String] name of the selected representant for whole map
    def get_representant(m)
      m = deep_copy(m)
      out = ""
      i = 0
      # search the 'order' table
      while Ops.less_than(i, Builtins.size(@representant_order))
        key_name = Ops.get(@representant_order, i, "")
        if Builtins.haskey(m, key_name)
          if key_name == "start"
            out = Builtins.tohexstring(Ops.get_integer(m, key_name, 0))
          elsif key_name == "modules"
            # Linux kernel modules (drivers)
            out = _("Modules")
          elsif key_name == "width"
            out = resolution("dummy", m)
          elsif key_name == "sub_class_id"
            out = classtostring("dummy", m)
          elsif key_name == "device"
            out = Ops.get_string(m, key_name, "")
            if Builtins.haskey(m, "dev_name")
              device = Ops.get_string(m, "dev_name", "")

              if device != ""
                # tree node string - %1 is device name, %2 is /dev file
                out = Builtins.sformat(_("%1 (%2)"), out, device)
              end
            end
          else
            out = trans_str(Builtins.sformat("%1", Ops.get(m, key_name)))
          end
          break
        end
        i = Ops.add(i, 1)
      end

      out
    end

    # Recursively converts (scalar/nested) lists and maps to tree datastructure
    # @param [Object] node any value
    # @return [Array] list of items (content of tree widget)

    def expandTree(node)
      node = deep_copy(node)
      return [] if node == nil

      # workaround for bug #31144 - don't visualize list
      # with only one map item
      if Ops.is_list?(node) && Builtins.size(Convert.to_list(node)) == 1
        node_list = Convert.to_list(node)

        if Ops.is_map?(Ops.get(node_list, 0))
          tmp = Builtins.eval(Ops.get_map(node_list, 0, {}))

          # if map has "model" key then don't flatten list,
          # device model name would be removed from the tree
          # when there is only one device in a device category
          node = deep_copy(tmp) if !Builtins.haskey(tmp, "model")
        end
      end

      # if node is scalar, we just return the new item.
      return [Item(trans_str(Builtins.sformat("%1", node)))] if scalar(node)


      if Ops.is_list?(node)
        # if node is list ...
        lout = []
        pos = 0
        Builtins.foreach(Convert.to_list(node)) do |e|
          if scalar(e)
            if e != nil
              lout = Builtins.add(lout, Item(Builtins.sformat("%1", e)))
            end
          else
            lab = UI.Glyph(:ArrowRight)
            if Ops.is(e, "map <string, any>")
              # ... create label for each item ...
              s = get_representant(
                Convert.convert(e, :from => "any", :to => "map <string, any>")
              )
              lab = s if s != ""
            end
            lout = Builtins.add(lout, Item(lab, expandTree(e)))
          end
          # ... and add it to item list
          pos = Ops.add(pos, 1)
        end 

        return deep_copy(lout)
      end
      if Ops.is_map?(node)
        # if node is map ...
        node_map = translate_hw_entry(
          Convert.convert(node, :from => "any", :to => "map <string, any>")
        )
        ltmp = []
        Builtins.foreach(node_map) do |key, v|
          # haha, hack! we need to translate the 'modules' entry into some more readable form...
          # unfortunatelly 'modules' is used in several places and in different meaings...
          if key == "modules" && Ops.is_list?(v)
            v = modules(
              Convert.convert(v, :from => "any", :to => "list <list <string>>")
            )
          end
          # ... explore all pairs
          if scalar(v) || v == {} || v == []
            ltmp = Builtins.add(
              ltmp,
              Item(Builtins.sformat("%1: %2", trans_str(key), trans_bool(v)))
            )
          elsif v == [""]
            ltmp = Builtins.add(
              ltmp,
              Item(Builtins.sformat("%1", trans_str(key)))
            )
          else
            ltmp = Builtins.add(
              ltmp,
              Item(trans_str(Builtins.sformat("%1", key)), expandTree(v))
            )
          end
        end 

        # ... and finally sort the items alphabetically
        return Builtins.sort(ltmp)
      end

      []
    end

    # Save hwinfo output to the specified file
    # @param [String] file Target file
    # @return [Boolean] True if saving was successful
    def save_hwinfo(file)
      return false if file == "" || file == nil

      command = Ops.add("/usr/sbin/hwinfo > ", file)
      SCR.Execute(path(".target.bash"), command) == 0
    end


    # Save hwinfo output to the specified file, progress popup is displayed.
    # Display error message when saving failed.
    # @param [String] target_file_name Target file
    # @return [Boolean] True if saving was successful
    def save_hwinfo_to_file(target_file_name)
      # window title
      filename = UI.AskForSaveFileName(
        target_file_name,
        "*",
        _("Save hwinfo Output to File")
      )
      saved = false

      if filename != nil && Ops.greater_than(Builtins.size(filename), 0)
        # progress window content
        UI.OpenDialog(Label(_("Saving hardware information...")))
        saved = save_hwinfo(filename)
        UI.CloseDialog

        if saved == false
          # error popup message
          Report.Error(
            Builtins.sformat(
              _("Saving output to the file '%1' failed."),
              target_file_name
            )
          )
        end
      end

      saved
    end

    # Mount specified device
    # @param [String] device device name to mount
    # @return [String] mount point where device was mounted (in /tmp subdirectory)
    #         or nil when mount failed
    def mount_device(device)
      tmpdir = Convert.to_string(SCR.Read(path(".target.tmpdir")))
      mpoint = Ops.add(tmpdir, "/mount")

      # create mount point directory
      SCR.Execute(path(".target.mkdir"), mpoint)

      # mount device
      result = Convert.to_boolean(
        SCR.Execute(path(".target.mount"), [device, mpoint], "")
      )

      result == true ? mpoint : nil
    end

    # Unmount device
    # @param [String] mount_point directory where device is mounted
    # @return [Boolean] true on success
    def umount_device(mount_point)
      Convert.to_boolean(SCR.Execute(path(".target.umount"), mount_point))
    end

    def has_hex_prefix(_in)
      return false if Ops.less_than(Builtins.size(_in), 2)

      # check whether string has hex prefix (0x or 0X)
      start = Builtins.substring(_in, 0, 2)
      start == "0x" || start == "0X"
    end

    def remove_hex_prefix(_in)
      return _in if !has_hex_prefix(_in)

      Builtins.substring(_in, 2)
    end

    def add_hex_prefix(_in)
      if _in == nil || _in == ""
        return ""
      else
        return !has_hex_prefix(_in) ? Ops.add("0x", _in) : _in
      end
    end
  end
end
