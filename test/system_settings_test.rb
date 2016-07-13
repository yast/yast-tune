#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "SystemSettings"

describe "Yast::SystemSettings" do
  Yast.import "Bootloader"

  subject(:settings) { Yast::SystemSettings }

  before { settings.main }

  describe "#GetPossibleElevatorValues" do
    it "returns an array with possible schedulers" do
      expect(settings.GetPossibleElevatorValues).to eq(["cfq", "noop", "deadline"])
    end
  end

  describe "#Read" do
    let(:kernel_sysrq)  { "1" }
    let(:sysctl_sysrq)  { "1" }
    let(:scheduler)     { "cfq" }

    before do
      allow(Yast::SCR).to receive(:Read).and_call_original
      allow(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".etc.sysctl_conf.\"kernel.sysrq\""))
        .and_return(sysctl_sysrq)
      allow(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".target.string"), "/proc/sys/kernel/sysrq")
        .and_return(kernel_sysrq)
      allow(Yast::Bootloader).to receive(:kernel_param)
        .with(:common, "elevator").and_return(scheduler)
    end

    context "when SysRq keys are enabled via sysctl" do
      let(:sysctl_sysrq) { "1" }

      it "enables SysRq keys" do
        settings.Read
        expect(settings.GetSysRqKeysEnabled).to eq(true)
      end
    end

    context "when SysRq keys are disabled via sysctl" do
      let(:sysctl_sysrq) { "0" }

      it "disables SysRq keys" do
        settings.Read
        expect(settings.GetSysRqKeysEnabled).to eq(false)
      end
    end

    context "when SysRq keys configuration cannot be read" do
      let(:kernel_sysrq) { "0" }
      let(:sysctl_sysrq) { nil }

      it "uses kernel value" do
        settings.Read
        expect(settings.GetSysRqKeysEnabled).to eq(false)
      end
    end

    context "when scheduler parameter is missing" do
      let(:scheduler) { :missing }

      it "unsets IO scheduler" do
        settings.Read
        expect(settings.GetIOScheduler).to eq("")
      end
    end

    context "when scheduler parameter is present but does not have a value" do
      let(:scheduler) { :present }

      it "unsets IO scheduler" do
        settings.Read
        expect(settings.GetIOScheduler).to eq("")
      end
    end

    context "when scheduler parameter has a valid value" do
      it "sets IO scheduler to that value" do
        settings.Read
        expect(settings.GetIOScheduler).to eq(scheduler)
      end
    end

    context "when scheduler parameter has an invalid value" do
      let(:scheduler) { "some-scheduler" }

      it "unsets IO scheduler" do
        settings.Read
        expect(settings.GetIOScheduler).to eq("")
      end
    end

    it "reads bootloader configuration" do
      expect(Yast::Bootloader).to receive(:Read)
      settings.Read
    end

    context "is not in normal mode" do
      before do
        allow(Yast::Mode).to receive(:mode).and_return("installation")
      end

      it "does not read bootloader configuration" do
        expect(Yast::Bootloader).to_not receive(:Read)
        settings.Read
      end

    end
  end

  describe "#Activate" do
    let(:sysrq_keys) { false }
    let(:scheduler)  { "" }
    let(:disk)       { "/sys/block/sda/queue/scheduler" }

    before do
      settings.SetSysRqKeysEnabled(sysrq_keys)
      settings.SetIOScheduler(scheduler)
      allow(Yast::Bootloader).to receive(:modify_kernel_params)
      allow(Yast::Bootloader).to receive(:proposed_cfg_changed=)
      allow(Dir).to receive(:[]).with(/scheduler/).and_return([disk])
    end

    context "given that SysRq keys status is unknown" do
      it "does not update /proc/sys/kernel/sysrq" do
        settings.main
        expect(Yast::SCR).to_not receive(:Execute)
          .with(Yast::Path.new(".target.bash"), /sysrq/)
        settings.Activate
      end
    end

    context "given that SysRq keys are enabled" do
      let(:sysrq_keys) { true }

      it "writes '1' to /proc/sys/kernel/sysrq" do
        expect(Yast::SCR).to receive(:Execute)
          .with(Yast::Path.new(".target.bash"), "echo '1' > /proc/sys/kernel/sysrq")
        settings.Activate
      end
    end

    context "given that SysRq keys is disabled" do
      it "writes '0' to /proc/sys/kernel/sysrq" do
        expect(Yast::SCR).to receive(:Execute)
          .with(Yast::Path.new(".target.bash"), "echo '0' > /proc/sys/kernel/sysrq")
        settings.Activate
      end
    end

    context "given that a scheduler is set" do
      let(:scheduler) { "cfq" }

      it "updates bootloader configuration" do
        expect(Yast::Bootloader).to receive(:modify_kernel_params)
          .with("elevator" => scheduler)
        expect(Yast::Bootloader).to receive(:proposed_cfg_changed=).with(true)
        allow(File).to receive(:write)
        settings.Activate
      end

      it "activates scheduler for all disk devices" do
        expect(File).to receive(:write).with(disk, scheduler)
        settings.Activate
      end
    end

    context "given that no scheduler is set" do
      let(:scheduler) { "" }

      it "removes parameter from bootloader configuration" do
        expect(Yast::Bootloader).to receive(:modify_kernel_params)
          .with("elevator" => :missing)
        expect(Yast::Bootloader).to receive(:proposed_cfg_changed=).with(true)
        settings.Activate
      end

      it "does not activate scheduler" do
        expect(File).to_not receive(:write)
        settings.Activate
      end
    end
  end

  describe "#Write" do
    let(:sysctl_sysrq) { "0" }
    let(:mode) { "normal" }

    before do
      allow(Yast::Mode).to receive(:mode).and_return(mode)
      allow(Yast::SCR).to receive(:Read).and_call_original
      allow(Yast::Bootloader).to receive(:Write)
      allow(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".etc.sysctl_conf.\"kernel.sysrq\""))
        .and_return(sysctl_sysrq)
    end

    context "when system settings has been read" do
      before { settings.Read }

      context "when SysRq keys status is valid" do
        let(:sysctl_sysrq) { "0" }

        it "updates sysctl configuration" do
          expect(Yast::SCR).to receive(:Write)
            .with(Yast::Path.new(".etc.sysctl_conf.\"kernel.sysrq\""), sysctl_sysrq)
          expect(Yast::SCR).to receive(:Write)
            .with(Yast::Path.new(".etc.sysctl_conf"), nil)
          settings.Write
        end
      end

      context "when SysRq keys status is not valid" do
        let(:sysctl_sysrq) { "-1" }

        it "does not update sysctl configuration" do
          expect(Yast::SCR).to_not receive(:Write)
            .with(Yast::Path.new(".etc.sysctl_conf.\"kernel.sysrq\""), sysctl_sysrq)
          settings.Write
        end
      end
    end

    it "writes bootloader configuration" do
      expect(Yast::Bootloader).to receive(:Write)
      settings.Write
    end

    context "is not in normal mode" do
      let(:mode) { "installation" }

      it "does not write bootloader configuration" do
        expect(Yast::Bootloader).to_not receive(:Write)
        settings.Write
      end
    end

    context "when system settings hadn't been read" do
      it "does not update sysctl configuration" do
        expect(Yast::SCR).to_not receive(:Write)
          .with(Yast::Path.new(".etc.sysctl_conf.\"kernel_sysrq\""), anything)
        settings.Write
      end
    end
  end

  describe "#SetIOScheduler" do
    context "when scheduler is a known one" do
      it "sets the scheduler to the given value" do
        settings.SetIOScheduler("cfq")
        expect(settings.GetIOScheduler).to eq("cfq")
      end
    end

    context "when scheduler is an unknown one" do
      before do
        settings.SetIOScheduler("cfq")
      end

      it "does not modify the scheduler" do
        settings.SetIOScheduler("some-scheduler")
        expect(settings.GetIOScheduler).to eq("cfq")
      end
    end

    context "when new scheduler is different from previous one" do
      before do
        allow(Yast::Bootloader).to receive(:kernel_param)
          .with(:common, "elevator").and_return("cfq")
        settings.Read
      end

      it "sets the module as modified" do
        expect { settings.SetIOScheduler("noop") }.to change { settings.Modified }
          .from(false).to(true)
      end
    end
  end

  describe "#SetSysRqKeysEnabled" do
    before do
      allow(Yast::SCR).to receive(:Read).and_call_original
      allow(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".etc.sysctl_conf.\"kernel.sysrq\""))
        .and_return(sysctl_sysrq)
      settings.Read
    end

    context "when SysRq is nil" do
      let(:sysctl_sysrq) { "1" }

      it "does not modify SysRq keys configuration" do
        expect { settings.SetSysRqKeysEnabled(nil) }.to_not change { settings.GetSysRqKeysEnabled }
      end

      it "does not set the module as modified" do
        expect { settings.SetSysRqKeysEnabled(nil) }.to_not change { settings.Modified }
      end
    end

    context "when SysRq keys are disabled" do
      let(:sysctl_sysrq) { "0" }

      context "and 'false' is given" do
        it "disables SysRq keys" do
          settings.SetSysRqKeysEnabled(false)
          expect(settings.GetSysRqKeysEnabled).to eq(false)
        end

        it "does not set the module as modified" do
          expect { settings.SetSysRqKeysEnabled(false) }.to_not change { settings.Modified }
        end
      end

      context "and 'true' is given" do
        it "enables SysRq keys" do
          settings.SetSysRqKeysEnabled(true)
          expect(settings.GetSysRqKeysEnabled).to eq(true)
        end

        it "sets the module as modified" do
          expect { settings.SetSysRqKeysEnabled(true) }.to change { settings.Modified }
            .from(false).to(true)
        end
      end
    end

    context "when SysRq keys are enabled" do
      let(:sysctl_sysrq) { "1" }

      context "and 'false' is given" do
        it "disables SysRq keys" do
          settings.SetSysRqKeysEnabled(false)
          expect(settings.GetSysRqKeysEnabled).to eq(false)
        end

        it "sets the module as modified" do
          expect { settings.SetSysRqKeysEnabled(false) }.to change { settings.Modified }
            .from(false).to(true)
        end
      end

      context "and 'true' is given" do
        it "enables SysRq keys" do
          settings.SetSysRqKeysEnabled(true)
          expect(settings.GetSysRqKeysEnabled).to eq(true)
        end

        it "does not set the module as modified" do
          expect { settings.SetSysRqKeysEnabled(true) }.to_not change { settings.Modified }
        end
      end
    end
  end
end
