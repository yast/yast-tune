# encoding: utf-8

#
# Module:	Initial HW info module
#
# Author:	Ladislav Slezak <lslezak@suse.cz>
#
# $Id$
#
# Collect and store hardware information.
require "yast"

module Yast
  class InitHWinfoClass < Module
    def main
      Yast.import "UI"

      Yast.import "String"
      Yast.import "Confirm"
      Yast.import "Progress"
      Yast.import "Arch"
      Yast.import "SystemSettings"

      Yast.include self, "hwinfo/routines.rb"

      textdomain "tune"

      @initialized = false

      # CPU summary string
      @cpu_string = ""
      # memory size
      @memory_size = 0
      # system summary string
      @system_string = ""

      # list of detected devices
      @detectedHW = nil

      # default is "/dev/fd0" floppy device (used when floppy detection is skipped as a fallback)
      @floppy = { "/dev/fd0" => _("Floppy disk") }
    end

    # Start hardware detection (only CPU and main memory)
    # @param [Boolean] force If true then start detection again (discard cached values)
    # @return [Boolean] True on success
    def Initialize(force)
      return true if @initialized == true && force == false

      # initialize procesor string
      cpu_result = Convert.convert(
        SCR.Read(path(".probe.cpu")),
        :from => "any",
        :to   => "list <map>"
      )
      cpus = {}

      Builtins.foreach(cpu_result) do |info|
        str = Ops.get_locale(info, "name", _("Unknown processor"))
        counter = Ops.get(cpus, str, 0)
        Ops.set(cpus, str, Ops.add(counter, 1))
      end 


      first = true
      @cpu_string = ""

      Builtins.foreach(cpus) do |cpu, count|
        if !first
          @cpu_string = Ops.add(@cpu_string, ", ")
        else
          first = false
        end
        if Ops.greater_than(count, 1)
          # create processor count string
          # %1 is integer number (greater than 1)
          # %2 is processor model name
          @cpu_string = Ops.add(
            @cpu_string,
            Builtins.sformat(_("%1x %2"), count, cpu)
          )
        else
          @cpu_string = Ops.add(@cpu_string, cpu)
        end
      end 


      memory = Convert.convert(
        SCR.Read(path(".probe.memory")),
        :from => "any",
        :to   => "list <map>"
      )

      Builtins.y2milestone("memory: %1", memory)
      @memory_size = 0

      Builtins.foreach(memory) do |info|
        # internal class, main memory
        if Ops.get_integer(info, "class_id", 0) == 257 &&
            Ops.get_integer(info, "sub_class_id", 0) == 2
          minf = Ops.get_list(info, ["resource", "phys_mem"], [])
          Builtins.foreach(minf) do |i|
            @memory_size = Ops.add(@memory_size, Ops.get_integer(i, "range", 0))
          end
        end
      end 


      # initialize system string
      bios = Convert.to_list(SCR.Read(path(".probe.bios")))

      if Builtins.size(bios) != 1
        Builtins.y2warning("Warning: BIOS list size is %1", Builtins.size(bios))
      end

      biosinfo = Ops.get_map(bios, 0, {})
      smbios = Ops.get_list(biosinfo, "smbios", [])

      sysinfo = {}

      Builtins.foreach(smbios) do |inf|
        sysinfo = deep_copy(inf) if Ops.get_string(inf, "type", "") == "sysinfo"
      end 


      @system_string = ""

      if Ops.greater_than(Builtins.size(sysinfo), 0)
        # system manufacturer is unknown
        manufacturer = Ops.get_locale(sysinfo, "manufacturer", _("Unknown"))
        # system product name is unknown
        product = Ops.get_locale(sysinfo, "product", _("Unknown"))
        version = Ops.get_string(sysinfo, "version", "")

        @system_string = Builtins.sformat("%1 - %2", manufacturer, product)

        if Ops.greater_than(Builtins.size(version), 0)
          @system_string = Ops.add(
            @system_string,
            Builtins.sformat(" (%1)", version)
          )
        end
      # PPC architecture - use board and generation information
      elsif Arch.ppc
        board = ""
        generation = ""

        systemProbe = Convert.convert(
          SCR.Read(path(".probe.system")),
          :from => "any",
          :to   => "list <map>"
        )
        systemProbe = [] if systemProbe == nil

        Builtins.foreach(systemProbe) do |systemEntry|
          board_tmp = Ops.get_string(systemEntry, "system", "")
          board = board_tmp if board_tmp != nil && board_tmp != ""
          generation_tmp = Ops.get_string(systemEntry, "generation", "")
          if generation_tmp != nil && generation_tmp != ""
            generation = generation_tmp
          end
        end

        @system_string = board

        if @system_string != "" && generation != ""
          @system_string = Ops.add(
            @system_string,
            Builtins.sformat(" (%1)", generation)
          )
        end
      end

      Builtins.y2milestone("System string: %1", @system_string)

      @initialized = true

      true
    end

    # Return short system description
    # @param [Boolean] reset If reset is true then always do hardware detection
    # @return [Array](string) list of hardware desciptions
    def MakeProposal(reset)
      Initialize(reset)

      # the installation proposal item
      # %1 is processor name
      ret = [
        Builtins.sformat(_("Processor: %1"), @cpu_string),
        # the installation proposal item
        # %1 is memory size string
        Builtins.sformat(
          _("Main Memory: %1"),
          String.FormatSizeWithPrecision(@memory_size, 2, true)
        )
      ]

      # add system string
      if Ops.greater_than(Builtins.size(@system_string), 0)
        # the installation proposal item
        # %1 is system name
        ret = Builtins.prepend(
          ret,
          Builtins.sformat(_("System: %1"), @system_string)
        )
      end

      # add SysRq status line
      if SystemSettings.GetSysRqKeysEnabled
        # item in the installation proposal (displayed only when SysRq key is enabled
        ret = Builtins.add(ret, _("SysRq Key: Enabled"))
      end

      Builtins.y2milestone("proposal: %1", ret)

      deep_copy(ret)
    end

    # Detect all hardware present in the system
    # @param [Boolean] force If force is true then detection is always started (cached value is discarded)
    # @return [Array] list of maps - detected hardware items ()
    def DetectedHardware(force, abort)
      abort = deep_copy(abort)
      # return cached values if possible
      return deep_copy(@detectedHW) if @detectedHW != nil && force != true

      @detectedHW = []

      # probe devices, store model, class, uniq. ID for each device

      # probe by bus
      # list(string) paths = [ "cpu", "memory", "ide", "pci", "scsi", "isapnp", "floppy", "usb", "monitor" ];

      # probe by device class
      paths = [
        "cpu",
        "memory",
        "disk",
        "display",
        "mouse",
        "keyboard",
        "storage",
        "netcard",
        "monitor",
        "braille",
        "bios"
      ]

      if !Arch.is_uml
        paths = Convert.convert(
          Builtins.union(
            paths,
            [
              "cdrom",
              "floppy",
              "sound",
              "isdn",
              "modem",
              "printer",
              "tv",
              "dvb",
              "scanner",
              "camera",
              "chipcard",
              "usbctrl",
              "ieee1394ctrl",
              "hub",
              "joystick",
              "pppoe"
            ]
          ),
          :from => "list",
          :to   => "list <string>"
        )
      end

      Progress.New(
        _("Hardware Detection"),
        "",
        Builtins.size(paths),
        [_("Detect hardware")],
        [_("Detecting hardware...")],
        _("Hardware detection is in progress. Please wait.")
      )

      Progress.NextStage

      aborted = false

      Builtins.foreach(paths) do |subpath|
        aborted = Builtins.eval(abort) if abort != nil && aborted != true
        Builtins.y2debug("aborted: %1", aborted)
        if !aborted
          p = Builtins.add(path(".probe"), subpath)

          # translate path name
          pathname = trans_str(subpath)

          # use untranslated string if translation failed
          pathname = subpath if pathname == nil

          # set progress bar label
          Progress.Title(Builtins.sformat(_("%1..."), pathname))

          # don't ask for probing CPU and memory, they were already probed and detection should be harmless
          detect = subpath == "cpu" || subpath == "memory" ?
            true :
            Confirm.Detection(pathname, nil)

          # confirm hardware detection in the manual mode
          if detect == true
            Builtins.y2milestone("Probing: %1", p)
            result = Convert.convert(
              SCR.Read(p),
              :from => "any",
              :to   => "list <map <string, any>>"
            )

            # store floppy devices, used in hwinfo output saving
            if subpath == "floppy"
              # reset list of floppies
              @floppy = {}

              if result != nil && Ops.greater_than(Builtins.size(result), 0)
                Builtins.foreach(result) do |f|
                  device = Ops.get_string(f, "dev_name")
                  model = Ops.get_string(f, "model")
                  if device != nil && model != nil
                    Ops.set(@floppy, device, model)
                  end
                end
              end

              Builtins.y2milestone("Detected floppy devices: %1", @floppy)
            end

            if Ops.greater_than(Builtins.size(result), 0)
              Builtins.foreach(result) do |info|
                # device name (CPU model name string has key "name" instead of "model")
                model = subpath == "cpu" ?
                  Ops.get_locale(info, "name", _("Unknown device")) :
                  Ops.get_locale(info, "model", _("Unknown device"))
                Builtins.y2debug("Model: %1", model)
                @detectedHW = Builtins.add(
                  @detectedHW,
                  { "model" => model, "info" => info }
                )
              end
            end
          end

          # update progress bar
          Progress.NextStep
        end
      end 


      if aborted == true
        # set to non-initialized state when detection is aborted
        @detectedHW = nil
      end

      Builtins.y2milestone("Detected HW: %1", @detectedHW)

      deep_copy(@detectedHW)
    end

    publish :variable => :floppy, :type => "map <string, string>"
    publish :function => :Initialize, :type => "boolean (boolean)"
    publish :function => :MakeProposal, :type => "list <string> (boolean)"
    publish :function => :DetectedHardware, :type => "list <map> (boolean, block <boolean>)"
  end

  InitHWinfo = InitHWinfoClass.new
  InitHWinfo.main
end
