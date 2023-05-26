#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

my $firmware_tarball = '/mnt/vendorfw/firmware.tar';
my @vfat_devices;

for (`blkid`) {
        if (/^([^:]+):.*vfat/) {
                push @vfat_devices, $1;
        }
}

for my $dev (@vfat_devices) {
        system("mount -o ro $dev /mnt");
        if (-f $firmware_tarball) {
                system("tar -C /lib/firmware/ -xf $firmware_tarball");
                unlink('/etc/modprobe.d/blacklist.conf');
                system('modprobe brcmfmac');
        }
        system('umount /mnt');
}
