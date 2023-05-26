#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

my $inputfile = $ARGV[0];
my $outputfile = $ARGV[1];

my @lines = `cat $inputfile`;
chomp @lines;

my %asahi_options = (
        'CONFIG_ANDROID_BINDER_IPC' => 'y',
        'CONFIG_APPLE_ADMAC' => 'y',
        'CONFIG_APPLE_AIC' => 'y',
        'CONFIG_APPLE_DART' => 'y',
        'CONFIG_APPLE_DOCKCHANNEL' => 'm',
        'CONFIG_APPLE_M1_CPU_PMU' => 'y',
        'CONFIG_APPLE_MAILBOX' => 'y',
        'CONFIG_APPLE_PLATFORMS' => 'y',
        'CONFIG_APPLE_PMGR_PWRSTATE' => 'y',
        'CONFIG_APPLE_RTKIT' => 'y',
        'CONFIG_APPLE_SART' => 'y',
        'CONFIG_APPLE_SMC' => 'y',
        'CONFIG_APPLE_SMC_RTKIT' => 'y',
        'CONFIG_APPLE_WATCHDOG' => 'y',
        'CONFIG_ARCH_APPLE' => 'y',
        'CONFIG_ARM64_16K_PAGES' => 'y',
        'CONFIG_ARM64_4K_PAGES' => 'n',
        'CONFIG_ARM_APPLE_SOC_CPUFREQ' => 'y',
        'CONFIG_BACKLIGHT_CLASS_DEVICE' => 'y',
        'CONFIG_BACKLIGHT_GPIO' => 'm',
        'CONFIG_BRCMFMAC' => 'm',
        'CONFIG_BRCMFMAC_PCIE' => 'y',
        'CONFIG_BT_HCIBCM4377' => 'm',
        'CONFIG_CFG80211_WEXT' => 'y',
        'CONFIG_CHARGER_MACSMC' => 'y',
        'CONFIG_COMMON_CLK_APPLE_NCO' => 'y',
        'CONFIG_CONSTRUCTORS' => 'y',
        'CONFIG_DEBUG_INFO' => 'n',
        'CONFIG_DEBUG_INFO_BTF' => 'n',
        'CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT' => 'n',
        'CONFIG_DRM' => 'y',
        'CONFIG_DRM_APPLE' => 'y',
        'CONFIG_DRM_ASAHI' => 'y',
        'CONFIG_DRM_SIMPLEDRM' => 'y',
        'CONFIG_DRM_SIMPLEDRM_BACKLIGHT' => 'n',
        'CONFIG_FB_EFI' => 'y',
        'CONFIG_FW_LOADER_USER_HELPER' => 'n',
        'CONFIG_FW_LOADER_USER_HELPER_FALLBACK' => 'n',
        'CONFIG_GENERIC_PHY' => 'y',
        'CONFIG_GPIO_MACSMC' => 'y',
        'CONFIG_HID_APPLE' => 'y',
        'CONFIG_HID_DOCKCHANNEL' => 'm',
        'CONFIG_HID_MAGICMOUSE' => 'y',
        'CONFIG_I2C_APPLE' => 'y',
        'CONFIG_MFD_APPLE_SPMI_PMU' => 'y',
        'CONFIG_MMC_SDHCI_PCI' => 'm',
        'CONFIG_MODVERSIONS' => 'n',
        'CONFIG_NLMON' => 'm',
        'CONFIG_NVMEM_SPMI_MFD' => 'y',
        'CONFIG_NVME_APPLE' => 'y',
        'CONFIG_OF_DYNAMIC' => 'y',
        'CONFIG_OF_OVERLAY' => 'y',
        'CONFIG_PCIE_APPLE' => 'y',
        'CONFIG_PHY_APPLE_ATC' => 'm',
        'CONFIG_PINCTRL_APPLE_GPIO' => 'y',
        'CONFIG_POWER_RESET_MACSMC' => 'y',
        'CONFIG_PWM_APPLE' => 'm',
        'CONFIG_RTC_DRV_MACSMC' => 'y',
        'CONFIG_RUST' => 'y',
        'CONFIG_SND_SIMPLE_CARD' => 'm',
        'CONFIG_SND_SOC_APPLE_MCA' => 'm',
        'CONFIG_SND_SOC_CS42L42' => 'm',
        'CONFIG_SND_SOC_CS42L83' => 'm',
        'CONFIG_SND_SOC_CS42L84' => 'm',
        'CONFIG_SND_SOC_TAS2770' => 'm',
        'CONFIG_SND_SOC_TAS2780' => 'm',
        'CONFIG_SPI_APPLE' => 'y',
        'CONFIG_SPI_HID_APPLE_CORE' => 'y',
        'CONFIG_SPI_HID_APPLE_OF' => 'y',
        'CONFIG_SPMI_APPLE' => 'y',
        'CONFIG_TYPEC_TPS6598X' => 'm',
        'CONFIG_USB_DWC3' => 'm',
        'CONFIG_USB_DWC3_PCI' => 'm',
        'CONFIG_USB_XHCI_PCI_ASMEDIA' => 'y',
);

my %debian_options;

for (@lines) {
        if (/(^CONFIG_[^=]+)=(.*)/) {
                $debian_options{$1} = $2;
        }
}

for my $o (keys %asahi_options) {
        if ((not exists $debian_options{$o}) && $asahi_options{$o} ne 'n') {
                print "$o missing, adding\n";
                $debian_options{$o} = $asahi_options{$o};
        } elsif ((exists $debian_options{$o}) && ($asahi_options{$o} eq 'n')) {
                print "$o present, removing\n";
                delete $debian_options{$o};
        } elsif ((exists $asahi_options{$o} && exists $debian_options{$o}) && ($debian_options{$o} ne $asahi_options{$o})) {
                print "$o different, changing\n";
                $debian_options{$o} = $asahi_options{$o};
        }
}

open(CONFIG, '>', $outputfile) || die;
for (sort keys %debian_options) {
        print CONFIG $_ . '=' . $debian_options{$_} . "\n";
}
close CONFIG;
