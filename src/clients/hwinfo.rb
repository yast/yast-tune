# encoding: utf-8

# File:	clients/hwinfo.ycp
# Module:	Hardware information
# Summary:	Main file
# Authors:	Dan Meszaros <dmeszar@suse.cz>
#		Ladislav Slezak <lslezak@suse.cz>
#		Michal Svec <msvec@suse.cz>
#
# $Id$
module Yast
  class HwinfoClient < Client
    include Yast::Logger

    def main
      Yast.import "UI"

      textdomain "tune"
      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "Arch"
      Yast.import "Directory"
      Yast.import "CommandLine"
      Yast.import "Icon"
      Yast.import "Package"
      Yast.import "Mode"
      Yast.import "Report"

      #include "hwinfo/classnames.ycp";
      Yast.include self, "hwinfo/routines.rb"

      # this global variable is needed for skipping out from recursed function
      @abortPressed = false

      # these paths will be excluded from probing.
      # .probe.mouse doesn't like running X
      # other paths are not user-interesting
      @exclude_list = [
        path(".probe.byclass"),
        path(".probe.bybus"),
        path(".probe.ihw_data"),
        path(".probe.system"),
        path(".probe.status"),
        path(".probe.cdb_isdn"),
        path(".probe.boot_disk")
      ]

      @cmdline_description = {
        "id"         => "hwinfo",
        # Command line help text for the hardware detection module, %1 is "hwinfo"
        "help"       => Builtins.sformat(
          _(
            "Hardware Detection - this module does not support the command line interface, use '%1' instead."
          ),
          "hwinfo"
        ),
        "guihandler" => fun_ref(method(:StartGUI), "symbol ()")
      }

      CommandLine.Run(@cmdline_description)


      # EOF
    end

    # open progress bar window
    def OpenProbingPopup
      UI.OpenDialog(
        HBox(
          VSpacing(7),
          VBox(
            HSpacing(40),
            HBox(
              HSquash(MarginBox(0.5, 0.2, Icon.Image("yast-hwinfo", {}))),
              # translators: popup heading
              Left(Heading(Id(:heading), _("Probing Hardware...")))
            ),
            # progress bar label
            ProgressBar(Id(:initProg), _("Progress"), 1000, 0),
            VSpacing(0.5),
            PushButton(Id(:abort), Opt(:key_F9), Label.AbortButton)
          )
        )
      )

      nil
    end

    def CloseProbingPopup
      UI.CloseDialog

      nil
    end


    def InitProbeList
      if Arch.is_uml
        # exclude more path in UML system, UML supports/emulates only few devices
        @exclude_list = Builtins.union(
          @exclude_list,
          [
            path(".probe.scsi"),
            path(".probe.camera"),
            path(".probe.pppoe"),
            path(".probe.isapnp"),
            path(".probe.tape"),
            path(".probe.joystick"),
            path(".probe.usb"),
            path(".probe.ieee1394ctrl"),
            path(".probe.usbctrl"),
            path(".probe.cdrom"),
            path(".probe.floppy"),
            path(".probe.chipcard"),
            path(".probe.mouse")
          ]
        )
      end

      # if xserver is running, don't probe for mouse and chipcard
      # because it has bad side effect (moving cursor)
      if SCR.Execute(path(".target.bash"), "/bin/ps -C Xorg") == 0
        log.warn "X server is running - mouse and chipcard will not be probed"
        @exclude_list << path(".probe.mouse")

        # .probe.chipcard has same effect as .probe.mouse
        @exclude_list << path(".probe.chipcard")
      end

      nil
    end

    # Add extra CPU info from .proc.cpuinfo to data read from .probe agent
    # @param [Array<Hash>] cpuinfo CPU information returned by .probe agent
    # @return [Array] input with additional CPU information

    def add_cpu_info(cpuinfo)
      cpuinfo = deep_copy(cpuinfo)
      # add information from /proc/cpuinfo for each CPU
      cpu_index = 0

      ret = Builtins.maplist(cpuinfo) do |probe_cpuinfo|
        # get all keys for selected processor
        keys = SCR.Dir(
          Builtins.add(
            path(".proc.cpuinfo.value"),
            Builtins.sformat("%1", cpu_index)
          )
        )
        if keys != nil
          # read values
          Builtins.foreach(keys) do |key|
            probe_cpuinfo = Builtins.add(
              probe_cpuinfo,
              key,
              SCR.Read(
                Builtins.add(
                  Builtins.add(
                    path(".proc.cpuinfo.value"),
                    Builtins.sformat("%1", cpu_index)
                  ),
                  key
                )
              )
            )
          end


          # add processor index
          probe_cpuinfo = Builtins.add(probe_cpuinfo, "Processor", cpu_index)
        end
        cpu_index = Ops.add(cpu_index, 1)
        deep_copy(probe_cpuinfo)
      end

      deep_copy(ret)
    end

    # returns string that is behind the last dot of given string (extract last part of path)
    # @param [String] str path in string form
    # @return [String] last path element

    def afterLast(str)
      strs = Builtins.splitstring(str, ".")
      Ops.get_string(strs, Ops.subtract(Builtins.size(strs), 1), "")
    end

    # Returns list of values read from path p
    # @param [Fixnum] progMin minimum value used in progressbar
    # @param [Fixnum] progMax maximum value used in progressbar
    # @param [String] p read path p
    # @return [Yast::Term] tree widget content

    def buildHwTree(p, progMin, progMax)
      Builtins.y2debug("buildHwTree path: %1", p)

      a = UI.PollInput
      if a == :cancel || a == :abort
        @abortPressed = true
        return nil
      end

      node = afterLast(p)
      node_translated = trans_str(node)

      UI.ChangeWidget(Id(:initProg), :Label, node_translated)
      Builtins.y2milestone("Probing %1 (%2)...", node, node_translated)
      pat = Builtins.topath(p)

      Builtins.y2debug("Reading path: %1", p)

      return nil if Builtins.contains(@exclude_list, pat)

      dir = SCR.Dir(pat)

      if dir == nil
        val = SCR.Read(pat)

        # SMBIOS entries cleanup
        clean_bios_tree(val) if pat == path(".probe.bios")

        if scalar(val)
          return Item(
            Builtins.sformat("%1: %2", trans_str(afterLast(p)), trans_bool(val))
          )
        elsif val == nil || val == [] || val == {}
          return nil
        else
          if afterLast(p) == "cpu"
            val = add_cpu_info(
              Convert.convert(val, :from => "any", :to => "list <map>")
            )
          end
          return Item(trans_str(afterLast(p)), expandTree(val))
        end
      else
        # remove duplicates from the list
        uniq = []

        Builtins.foreach(dir) do |d|
          uniq = Builtins.add(uniq, d) if !Builtins.contains(uniq, d)
        end


        dir = deep_copy(uniq)

        step = 1000
        if Builtins.size(dir) != 0
          step = Ops.divide(Ops.subtract(progMax, progMin), Builtins.size(dir))
        end
        prog = progMin

        pos = Ops.subtract(Builtins.size(dir), 1)
        lout = []
        itm = nil
        while Ops.greater_or_equal(pos, 0)
          itm = buildHwTree(
            Ops.add(Ops.add(p, "."), Ops.get(dir, pos)),
            prog,
            Ops.add(prog, step)
          )
          return nil if @abortPressed
          lout = Builtins.add(lout, itm) if itm != nil
          pos = Ops.subtract(pos, 1)
          prog = Ops.add(prog, step)
          UI.ChangeWidget(Id(:initProg), :Value, prog)
        end
        return Item(afterLast(p), Builtins.sort(lout))
      end
      nil
    end

    # remove empty nodes with type "unknown" from BIOS detection
    # the removed items are Hashes like this:
    # {"type" =>"unknown", "type_id" => 217}
    def clean_bios_tree(bios_tree)
      return unless bios_tree.is_a?(Array)

      bios_tree.each do |v|
        next unless v.is_a?(Hash)
        smbios = v["smbios"]
        next unless smbios.is_a?(Array)

        log.info "smbios items: #{smbios.size}"
        # do not remove the "unknown" items if there are some more data (size > 2)
        smbios.reject!{ |node| node.is_a?(Hash) && node.size <= 2 && node["type"] == "unknown" }
        log.info "smbios items after cleanup: #{smbios.size}"
      end
    end

    # Check if the "hwinfo" package or binary is available and possibly offer
    # to install it.
    #
    # @return [Boolean] true if success, false if error
    #
    def ensure_hwinfo_available
      return true unless Mode.normal

      return true if Package.CheckAndInstallPackages(["hwinfo"])

      Report.Error(Message.CannotContinueWithoutPackagesInstalled)
      false
    end


    # Main
    def StartGUI
      return :back unless ensure_hwinfo_available

      # display progress popup
      OpenProbingPopup()

      # set the paths to probe
      InitProbeList()

      # tree item list
      items = nil
      # default initial path
      pat = path(".probe")

      # build the tree
      items = buildHwTree(Builtins.sformat("%1", pat), 0, 1000)

      # close the popup
      CloseProbingPopup()

      # interrupted
      return :abort if @abortPressed

      # title label
      title = _("&All Entries")
      con = Tree(
        Id(:idTree),
        Opt(:vstretch, :hstretch),
        title,
        Ops.get(items, 1)
      )

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("org.opensuse.yast.HWInfo")


      Wizard.SetBackButton(:save, _("&Save to File..."))
      Wizard.SetNextButton(:next, Label.CloseButton)

      # abort is not needed, module is read-only
      Wizard.HideAbortButton


      # dialog header
      Wizard.SetContents(
        _("Hardware Information"),
        con,
        # help text
        _(
          "<P>The <B>Hardware Information</B> module displays the hardware\ndetails of your computer. Click any node for more information.</p>\n"
        ) +
          _(
            "<P>You can save hardware information to a file. Click <B>Save to File</B> and enter the filename.</P>"
          ),
        true,
        true
      )

      UI.SetFocus(Id(:idTree))

      event = nil

      # wait for finish
      while event != :abort && event != :next && event != :cancel
        event = UI.UserInput

        if event == :save
          # store hwinfo output to the file
          save_hwinfo_to_file("/")
        end
      end
      Wizard.CloseDialog
      :next
    end
  end
end

Yast::HwinfoClient.new.main
