#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "SystemSettings"
Yast.import "Bootloader"

describe "Yast::SystemSettings" do
  KERNEL_SYSRQ_FILE = "/proc/sys/kernel/sysrq"

  subject(:settings) { Yast::SystemSettings }
  let(:rd_zdev)       { "no-auto" }
  let(:sysctl_config) { CFA::SysctlConfig.new }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(Yast::Bootloader).to receive(:Read)
    allow(Yast::Bootloader).to receive(:kernel_param)
      .with(:common, "rd.zdev").and_return(rd_zdev)
    allow(CFA::SysctlConfig).to receive(:new).and_return(sysctl_config)
    allow(sysctl_config).to receive(:load)
    allow(sysctl_config).to receive(:save)
    settings.main
  end

  describe "#Read" do
    let(:kernel_sysrq)  { "1" }
    let(:sysctl_sysrq)  { "1" }
    let(:mode) { "normal" }

    before do
      allow(sysctl_config).to receive(:kernel_sysrq).and_return(sysctl_sysrq)
      allow(File).to receive(:read).with(KERNEL_SYSRQ_FILE)
        .and_return(kernel_sysrq)
      allow(Yast::Bootloader).to receive(:kernel_param)
        .with(:common, "rd.zdev").and_return(rd_zdev)
      allow(Yast::Mode).to receive(:mode).and_return(mode)
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

    context "when rd.zdev kernel option is set" do
      let(:rd_zdev) { "no-auto" }

      it "I/O autoconfig is disabled" do
        settings.Read
        expect(settings.GetAutoConf).to eq(false)
      end
    end

    context "when rd.zdev kernel option is not set" do
      let(:rd_zdev) { :missing }

      it "I/O autoconfig is enabled" do
        settings.Read
        expect(settings.GetAutoConf).to eq(true)
      end
    end
  end

  describe "#Activate" do
    let(:sysrq_keys) { false }

    before do
      settings.SetSysRqKeysEnabled(sysrq_keys)
      allow(File).to receive(:write).with(KERNEL_SYSRQ_FILE, anything)
      allow(Yast::Bootloader).to receive(:modify_kernel_params)
      allow(Yast::Bootloader).to receive(:proposed_cfg_changed=)
      allow(Dir).to receive(:[]).with("/usr/share/YaST2/locale/*").and_return([])
    end

    context "when SysRq keys status is unknown" do
      it "does not update /proc/sys/kernel/sysrq" do
        settings.main
        expect(File).to_not receive(:write).with(/sysrq/, anything)
        settings.Activate
      end
    end

    context "when SysRq keys are enabled" do
      let(:sysrq_keys) { true }

      it "writes '1' to /proc/sys/kernel/sysrq" do
        expect(File).to receive(:write).with(KERNEL_SYSRQ_FILE, "1\n")
        settings.Activate
      end
    end

    context "when SysRq keys is disabled" do
      it "writes '0' to /proc/sys/kernel/sysrq" do
        expect(::File).to receive(:write).with(KERNEL_SYSRQ_FILE, "0\n")
        settings.Activate
      end
    end

    context "when I/O device autoconfig is enabled" do
      it "removes rd.zdev kernel option" do
        expect(Yast::Bootloader).to receive(:modify_kernel_params)
          .with("rd.zdev" => :missing)
        settings.SetAutoConf(true)
        settings.Activate
      end
    end

    context "when I/O device autoconfig is disabled" do
      it "sets rd.zdev kernel option to no-auto" do
        expect(Yast::Bootloader).to receive(:modify_kernel_params)
          .with("rd.zdev" => "no-auto")
        settings.SetAutoConf(false)
        settings.Activate
      end
    end
  end

  describe "#Write" do
    let(:sysctl_sysrq) { "0" }
    let(:mode) { "normal" }

    before do
      allow(Yast::Mode).to receive(:mode).and_return(mode)
      allow(Yast::Bootloader).to receive(:Write)
      allow(Yast::SCR).to receive(:Read).and_call_original
      allow(sysctl_config).to receive(:kernel_sysrq).and_return(sysctl_sysrq)
    end

    context "when system settings has been read" do
      before { settings.Read }

      context "when SysRq keys status is valid" do
        let(:sysctl_sysrq) { "0" }

        it "updates sysctl configuration" do
          expect(sysctl_config).to receive(:kernel_sysrq=).with(sysctl_sysrq)
          settings.Write
        end
      end

      context "when SysRq keys status is not valid" do
        let(:sysctl_sysrq) { "-1" }

        it "does not update sysctl configuration" do
          expect(sysctl_config).to_not receive(:kernel_sysrq=)
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
        expect(sysctl_config).to_not receive(:kernel_sysrq=)
        settings.Write
      end
    end
  end

  describe "#SetSysRqKeysEnabled" do
    before do
      allow(Yast::SCR).to receive(:Read).and_call_original
      allow(sysctl_config).to receive(:kernel_sysrq).and_return(sysctl_sysrq)
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
