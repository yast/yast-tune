# encoding: utf-8

#
# Module:	Set new PCI ID for kernel drivers
#
# Author:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# Manage new PCI IDs for kernel drivers
require "yast"

module Yast
  class NewIDClass < Module
    def main
      Yast.import "UI"
      Yast.import "String"
      Yast.import "Report"
      Yast.import "ModuleLoading"
      Yast.import "Linuxrc"
      Yast.import "FileUtils"

      Yast.include self, "hwinfo/routines.rb"
      textdomain "tune"

      # list of configured PCI IDs
      @new_ids = nil
      @removed_ids = []

      # cache .probe.pci values
      @pcidevices = nil

      @refresh_proposal = false
      @configfile = "/etc/sysconfig/hardware/newids"
    end

    def GetPCIdevices
      if @pcidevices == nil
        # initialize list
        @pcidevices = Convert.convert(
          SCR.Read(path(".probe.pci")),
          :from => "any",
          :to   => "list <map>"
        )

        # still nil, set to empty - avoid reprobing next time
        @pcidevices = [] if @pcidevices == nil
      end

      deep_copy(@pcidevices)
    end


    def AddID(new_id)
      new_id = deep_copy(new_id)
      # initialize list if needed
      @new_ids = [] if @new_ids == nil

      if new_id != nil && new_id != {}
        if @new_ids == nil
          @new_ids = [new_id]
          @refresh_proposal = true

          if Builtins.contains(@removed_ids, new_id)
            # remove added id from removed list
            @removed_ids = Builtins.filter(@removed_ids) { |i| i != new_id }
          end
        elsif !Builtins.contains(@new_ids, new_id)
          @new_ids = Builtins.add(@new_ids, new_id)
          @refresh_proposal = true
        end
      end

      nil
    end

    def RemoveID(index)
      removed_id = Ops.get(@new_ids, index, {})

      @new_ids = Builtins.remove(@new_ids, index)
      @refresh_proposal = true

      # add to removed
      if removed_id != nil && removed_id != {} &&
          !Builtins.contains(@removed_ids, removed_id)
        @removed_ids = Builtins.add(@removed_ids, removed_id)

        if Builtins.contains(@new_ids, removed_id)
          # remove deleted id from list of new
          @new_ids = Builtins.filter(@new_ids) { |i| i != removed_id }
        end
      end

      nil
    end

    def GetNewIDs
      deep_copy(@new_ids)
    end

    def GetNewID(index)
      Ops.get(@new_ids, index, {})
    end

    def SetNewID(nid, index)
      nid = deep_copy(nid)
      Ops.set(@new_ids, index, nid)
      @refresh_proposal = true

      nil
    end

    def RefreshProposal
      @refresh_proposal
    end

    def Read(filename)
      if filename != nil && filename != ""
        @new_ids = []

        # read file
        file = nil
        if FileUtils.Exists(filename)
          file = Convert.to_string(SCR.Read(path(".target.string"), filename))
        else
          Builtins.y2milestone("File %1 does not exist yet", filename)
        end

        return false if file == nil

        lines = Builtins.splitstring(file, "\n")

        Builtins.y2debug("lines: %1", lines)
        comment = []

        # parse lines
        Builtins.foreach(lines) do |line|
          line = String.CutBlanks(line)
          if Builtins.regexpmatch(line, "^#.*")
            # line is a comment
            comment = Builtins.add(comment, line)
          else
            parts = Builtins.splitstring(line, ",")

            driver = Ops.get(parts, 1)
            sysdir = Ops.get(parts, 2)

            # parse newid line
            # replace tabs by spaces
            line = Builtins.mergestring(
              Builtins.splitstring(Ops.get(parts, 0, ""), "\t"),
              " "
            )

            idparts = Builtins.splitstring(line, " ")

            idparts = Builtins.filter(idparts) do |part|
              part != nil && part != ""
            end

            vendor = Ops.get(idparts, 0)
            device = Ops.get(idparts, 1)
            subvendor = Ops.get(idparts, 2)
            subdevice = Ops.get(idparts, 3)
            _class = Ops.get(idparts, 4)
            class_mask = Ops.get(idparts, 5)
            driver_data = Ops.get(idparts, 6)

            newid = {}

            # search for existing PCI card if class is not specified
            if class_mask == nil && _class == nil && vendor != nil &&
                device != nil
              vid = nil
              did = nil
              svid = nil
              sdid = nil

              if vendor != nil
                vid = Builtins.tointeger(
                  !has_hex_prefix(vendor) ? Ops.add("0x", vendor) : vendor
                )
              end
              if device != nil
                did = Builtins.tointeger(
                  !has_hex_prefix(device) ? Ops.add("0x", device) : device
                )
              end
              if subvendor != nil
                svid = Builtins.tointeger(
                  !has_hex_prefix(subvendor) ?
                    Ops.add("0x", subvendor) :
                    subvendor
                )
              end
              if subdevice != nil
                sdid = Builtins.tointeger(
                  !has_hex_prefix(subdevice) ?
                    Ops.add("0x", subdevice) :
                    subdevice
                )
              end

              Builtins.y2debug("vid: %1", vid)
              Builtins.y2debug("did: %1", did)
              Builtins.y2debug("svid: %1", svid)
              Builtins.y2debug("sdid: %1", sdid)

              Builtins.foreach(GetPCIdevices()) do |dev|
                # check ID
                if vid ==
                    Ops.subtract(Ops.get_integer(dev, "vendor_id", 0), 65536) &&
                    did ==
                      Ops.subtract(Ops.get_integer(dev, "device_id", 0), 65536)
                  # some devices don't have subdevice, subvendor
                  if Builtins.haskey(dev, "sub_vendor_id") &&
                      Builtins.haskey(dev, "sub_device_id")
                    if svid ==
                        Ops.subtract(
                          Ops.get_integer(dev, "sub_vendor_id", 0),
                          65536
                        ) &&
                        sdid ==
                          Ops.subtract(
                            Ops.get_integer(dev, "sub_device_id", 0),
                            65536
                          )
                      Ops.set(
                        newid,
                        "uniq",
                        Ops.get_string(dev, "unique_key", "")
                      )
                    end
                  else
                    Ops.set(
                      newid,
                      "uniq",
                      Ops.get_string(dev, "unique_key", "")
                    )
                  end
                end
              end
            end

            if !Builtins.haskey(newid, "uniq")
              Ops.set(newid, "vendor", vendor) if vendor != nil
              Ops.set(newid, "device", device) if device != nil
              Ops.set(newid, "subvendor", subvendor) if subvendor != nil
              Ops.set(newid, "subdevice", subdevice) if subdevice != nil
              Ops.set(newid, "class", _class) if _class != nil
              Ops.set(newid, "class_mask", class_mask) if class_mask != nil
            end

            Ops.set(newid, "driver_data", driver_data) if driver_data != nil

            Ops.set(newid, "driver", driver) if driver != nil
            Ops.set(newid, "sysdir", sysdir) if sysdir != nil
            if Ops.greater_than(Builtins.size(comment), 0)
              Ops.set(newid, "comment", comment)
            end

            Builtins.y2milestone("read newid: %1", newid)

            @new_ids = Builtins.add(@new_ids, newid) if newid != {}

            comment = []
          end
        end 


        Builtins.y2milestone("Read settings: %1", @new_ids)

        return true
      end
      false
    end

    # Prepend option to PCI ID string, use default value if required
    # @param [String] newopt Prepend this option
    # @param [String] opts Already existing option string
    # @param [String] defval Default value, used when newopt is empty
    def prepend_option(newopt, opts, defval)
      return "" if opts == "" && newopt == ""

      if Ops.greater_than(Builtins.size(opts), 0)
        return Ops.add(
          Ops.add(
            Ops.greater_than(Builtins.size(newopt), 0) ? newopt : defval,
            " "
          ),
          opts
        )
      else
        return newopt
      end
    end

    def AddIDs(id)
      id = deep_copy(id)
      newid = deep_copy(id)

      if Builtins.haskey(newid, "uniq")
        # add device/vendor values from PCI scan for selected PCI device
        Builtins.foreach(GetPCIdevices()) do |pcidev|
          if Ops.get_string(pcidev, "unique_key", "") ==
              Ops.get_string(newid, "uniq", "")
            Builtins.y2debug("Found PCI device: %1", pcidev)
            # libhd uses 0x10000 offset for PCI devices
            if Builtins.haskey(pcidev, "device_id")
              Ops.set(
                newid,
                "device",
                Builtins.tohexstring(
                  Ops.subtract(Ops.get_integer(pcidev, "device_id", 0), 65536)
                )
              )
            end
            if Builtins.haskey(pcidev, "sub_device_id")
              Ops.set(
                newid,
                "subdevice",
                Builtins.tohexstring(
                  Ops.subtract(
                    Ops.get_integer(pcidev, "sub_device_id", 0),
                    65536
                  )
                )
              )
            end
            if Builtins.haskey(pcidev, "vendor_id")
              Ops.set(
                newid,
                "vendor",
                Builtins.tohexstring(
                  Ops.subtract(Ops.get_integer(pcidev, "vendor_id", 0), 65536)
                )
              )
            end
            if Builtins.haskey(pcidev, "sub_vendor_id")
              Ops.set(
                newid,
                "subvendor",
                Builtins.tohexstring(
                  Ops.subtract(
                    Ops.get_integer(pcidev, "sub_vendor_id", 0),
                    65536
                  )
                )
              )
            end
          end
        end
      end

      deep_copy(newid)
    end

    def FormatActivationString(newid)
      newid = deep_copy(newid)
      # create ID string which is passed to the driver
      ret = ""

      pci_any_id = "ffffffff"
      default_class = "0"
      default_mask = "0"

      newid = AddIDs(newid) if Builtins.haskey(newid, "uniq")

      ret = prepend_option(
        remove_hex_prefix(Ops.get_string(newid, "class_mask", "")),
        ret,
        default_mask
      )
      ret = prepend_option(
        remove_hex_prefix(Ops.get_string(newid, "class", "")),
        ret,
        default_class
      )
      ret = prepend_option(
        remove_hex_prefix(Ops.get_string(newid, "subdevice", "")),
        ret,
        pci_any_id
      )
      ret = prepend_option(
        remove_hex_prefix(Ops.get_string(newid, "subvendor", "")),
        ret,
        pci_any_id
      )
      ret = prepend_option(
        remove_hex_prefix(Ops.get_string(newid, "device", "")),
        ret,
        pci_any_id
      )
      ret = prepend_option(
        remove_hex_prefix(Ops.get_string(newid, "vendor", "")),
        ret,
        pci_any_id
      )

      ret
    end

    # Activate value stored in the internal list
    # @return [Boolean] True if all settings were successfuly set
    def Activate
      ret = true

      Builtins.foreach(@new_ids) do |newid|
        modulename = Ops.get_string(newid, "driver", "")
        sysdir = Ops.get_string(newid, "sysdir", "")
        # load kernel module if it isn't already loaded
        if modulename != nil && modulename != ""
          ModuleLoading.Load(
            modulename,
            "", # TODO allow setting of module args?
            # vendor is empty, device name is unknown
            "",
            _("Unknown device"),
            Linuxrc.manual,
            true
          )
        end
        sysdir = modulename if sysdir == nil || sysdir == ""
        targetfile = Builtins.sformat("/sys/bus/pci/drivers/%1/new_id", sysdir)
        # create ID string passed to the driver
        idstring = FormatActivationString(newid)
        # check whether target file exists
        filesize = Convert.to_integer(
          SCR.Read(path(".target.size"), targetfile)
        )
        if Ops.greater_or_equal(filesize, 0)
          # set the new value
          set = Convert.to_integer(
            SCR.Execute(
              path(".target.bash"),
              Builtins.sformat(
                "echo '%1' > '%2'",
                String.Quote(idstring),
                String.Quote(targetfile)
              )
            )
          ) == 0

          if !set
            Builtins.y2error(
              "Setting the new id failed: driver: %1, value: %2",
              targetfile,
              idstring
            )
            ret = false
          else
            Builtins.y2milestone(
              "File %1 - new PCI ID '%2' was succesfully set",
              targetfile,
              idstring
            )
          end
        else
          # Error message
          Report.Error(
            Builtins.sformat(
              _("File '%1' does not exist. Cannot set new PCI ID."),
              targetfile
            )
          )
          ret = false
        end
      end if @new_ids != nil

      ret
    end

    def HwcfgFileName(newid)
      newid = deep_copy(newid)
      ret = ""

      newid = AddIDs(newid) if Builtins.haskey(newid, "uniq")

      vendor = remove_hex_prefix(Ops.get_string(newid, "vendor", ""))
      device = remove_hex_prefix(Ops.get_string(newid, "device", ""))

      if Ops.greater_than(Builtins.size(vendor), 0) &&
          Ops.greater_than(Builtins.size(device), 0)
        ret = Builtins.sformat("vpid-%1-%2", vendor, device)

        subvendor = remove_hex_prefix(Ops.get_string(newid, "subvendor", ""))
        subdevice = remove_hex_prefix(Ops.get_string(newid, "subdevice", ""))

        if Ops.greater_than(Builtins.size(subvendor), 0) &&
            Ops.greater_than(Builtins.size(subdevice), 0)
          ret = Builtins.sformat("%1-%2-%3", ret, subvendor, subdevice)
        end
      end

      Builtins.y2debug("activation string: %1", ret)
      ret
    end

    def WriteHwcfg(newid)
      newid = deep_copy(newid)
      ret = false
      cfgname = HwcfgFileName(newid)
      driver = Ops.get_string(newid, "driver", "")

      Builtins.y2debug("newid: %1", newid)
      Builtins.y2debug("cfgname: %1", cfgname)
      Builtins.y2debug("driver: %1", driver)

      if cfgname != "" && driver != ""
        # prepare hwcfg values
        startmode = "auto"
        module_options = ""

        p = Ops.add(path(".sysconfig.hardware.value"), Builtins.topath(cfgname))

        # write the values
        SCR.Write(Ops.add(p, path(".MODULE")), driver)
        SCR.Write(Ops.add(p, path(".STARTMODE")), startmode)
        SCR.Write(Ops.add(p, path(".MODULE_OPTIONS")), module_options)

        # flush the changes
        SCR.Write(path(".sysconfig.hardware"), nil)
      end

      ret
    end

    def RemoveExistingFile(fname)
      ret = true

      if fname != nil && fname != ""
        # remove old config file if it exists
        if Ops.greater_than(SCR.Read(path(".target.size"), fname), 0)
          res = Convert.to_integer(
            SCR.Execute(path(".target.bash"), Ops.add("/bin/rm ", fname))
          )

          if res != 0
            Builtins.y2warning(
              "Removing of file %1 has failed, exit: %2",
              fname,
              res
            )
          else
            Builtins.y2milestone("Removed file: %1", fname)
          end
        end
      end

      ret
    end

    def Write
      Builtins.y2milestone("Writing PCI ID cofiguration...")

      ret = true

      # content of /etc/sysconfig/hardware/newids
      sysconfig = ""

      # map ID commands to driver
      settings = {}

      # handle removed configurations - remove all modprobe entries
      if Ops.greater_than(Builtins.size(@removed_ids), 0)
        drvs = SCR.Dir(path(".modprobe_newid.install"))

        if drvs != nil && Ops.greater_than(Builtins.size(drvs), 0)
          Builtins.foreach(drvs) do |d|
            SCR.Write(Builtins.add(path(".modprobe_newid.install"), d), nil)
          end
        end
      end

      Builtins.foreach(@new_ids) do |newid|
        modulename = Ops.get_string(newid, "driver", "")
        sysdir = Ops.get_string(newid, "sysdir", "")
        idstring = FormatActivationString(newid)
        # write settings to /etc/modprobe.d/50-newid.conf if the module is known
        # (the module is not compiled into the kernel)
        if modulename != ""
          targetfile = sysdir != "" ? sysdir : modulename
          install_string = Builtins.sformat(
            "echo '%1' > '/sys/bus/pci/drivers/%2/new_id'",
            String.Quote(idstring),
            String.Quote(targetfile)
          )

          current = Ops.get(settings, modulename, [])
          current = Builtins.add(current, install_string)
          Ops.set(settings, modulename, current)
        end
        # write hwcfg file to load the driver
        WriteHwcfg(newid)
        # add to /etc/sysconfig/hardware/newids
        if Builtins.haskey(newid, "comment")
          # add the comment
          sysconfig = Ops.add(
            Ops.add(
              sysconfig,
              Builtins.mergestring(Ops.get_list(newid, "comment", []), "\n")
            ),
            "\n"
          )
        end
        sysconfig = Ops.add(
          Ops.add(Ops.add(sysconfig, idstring), ","),
          modulename
        )
        sysconfig = Ops.add(Ops.add(sysconfig, ","), sysdir) if sysdir != ""
        # add trailing newline
        sysconfig = Ops.add(sysconfig, "\n")
      end if @new_ids != nil

      # write sysconfig settings
      if Ops.greater_than(Builtins.size(sysconfig), 0)
        # write sysconfig file
        ret = ret && SCR.Write(path(".target.string"), @configfile, sysconfig)
      else
        # remove old config file if it exists
        RemoveExistingFile(@configfile)
      end

      # write modprobe settings
      if Ops.greater_than(Builtins.size(settings), 0)
        Builtins.foreach(settings) do |modulename, values|
          install_string = Builtins.sformat(
            "/sbin/modprobe --ignore-install %1; %2",
            modulename,
            Builtins.mergestring(values, "; ")
          )
          ret = ret &&
            SCR.Write(
              Builtins.add(path(".modprobe_newid.install"), modulename),
              install_string
            )
        end 


        # flush changes
        SCR.Write(path(".modprobe_newid"), nil)
      end

      # handle removed configurations - remove hwcfg files
      if Ops.greater_than(Builtins.size(@removed_ids), 0)
        Builtins.foreach(@removed_ids) do |rem|
          fname = HwcfgFileName(rem)
          if fname != ""
            # remove the file
            fname = Ops.add("/etc/sysconfig/hardware/hwcfg-", fname)
            RemoveExistingFile(fname)
          end
        end
      end

      ret
    end

    def GetModelString(uniq)
      ret = ""

      Builtins.foreach(GetPCIdevices()) do |d|
        if Ops.get_string(d, "unique_key", "") == uniq
          ret = Ops.get_string(d, "model", "")
        end
      end 


      ret
    end

    # Return new ID description
    # @return [Array](string) list of hardware desciptions
    def MakeProposal
      ret = []

      Builtins.foreach(@new_ids) do |newid|
        modulename = Ops.get_string(newid, "driver", "")
        sysdir = Ops.get_string(newid, "sysdir", "")
        idstring = FormatActivationString(newid)
        targetfile = sysdir != "" ? sysdir : modulename
        # test for installation proposal
        # %1 - name of kernel driver (e.g. e100)
        # %2 - PCI ID (hexnumbers)
        info = Builtins.sformat(
          _("Driver: %1, New PCI ID: %2"),
          targetfile,
          idstring
        )
        if Builtins.haskey(newid, "uniq")
          model = GetModelString(Ops.get_string(newid, "uniq", ""))

          if model != nil && model != ""
            info = Ops.add(info, Builtins.sformat(" (%1)", model))
          end
        end
        ret = Builtins.add(ret, info)
      end if Ops.greater_than(
        Builtins.size(@new_ids),
        0
      )

      Builtins.y2milestone("NewID proposal: %1", ret)

      # proposal is valid
      @refresh_proposal = false

      deep_copy(ret)
    end

    publish :function => :GetPCIdevices, :type => "list <map> ()"
    publish :function => :AddID, :type => "void (map <string, string>)"
    publish :function => :RemoveID, :type => "void (integer)"
    publish :function => :GetNewIDs, :type => "list <map <string, any>> ()"
    publish :function => :GetNewID, :type => "map <string, any> (integer)"
    publish :function => :SetNewID, :type => "void (map <string, any>, integer)"
    publish :function => :RefreshProposal, :type => "boolean ()"
    publish :function => :Read, :type => "boolean (string)"
    publish :function => :AddIDs, :type => "map (map)"
    publish :function => :Activate, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :GetModelString, :type => "string (string)"
    publish :function => :MakeProposal, :type => "list <string> ()"
  end

  NewID = NewIDClass.new
  NewID.main
end
