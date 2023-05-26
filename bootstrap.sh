#!/usr/bin/env bash

# SPDX-License-Identifier: MIT

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

cd "$(dirname "$0")"

unset LC_CTYPE
unset LANG

export DEBOOTSTRAP=debootstrap
MIRROR=https://community-packages.deepin.com/beige/

build_rootfs()
{
(
        sudo rm -rf testing
        mkdir -p cache
        sudo eatmydata ${DEBOOTSTRAP} --keyring /usr/share/keyrings/deepin-archive-camel-keyring.gpg --cache-dir=`pwd`/cache --arch=arm64 --include pciutils,wpasupplicant,vim,tmux,vlan,parted,curl,wget,grub-efi-arm64,dbus,ca-certificates,sudo,openssh-client,mtools,gdisk,cryptsetup,wireless-regdb,zstd beige testing $MIRROR


        cd testing

        sudo mkdir -p boot/efi/m1n1 etc/X11/xorg.conf.d

        sudo bash -c 'echo deepin > etc/hostname'

        sudo bash -c 'echo > etc/motd'

	sudo cat ../../files/sources.list > etc/apt/sources.list

	sudo chroot . apt update
	sudo chroot . apt upgrade -y

        sudo cp ../../files/glanzmann.list etc/apt/sources.list.d/
        sudo cp ../../files/thomas-glanzmann.gpg etc/apt/trusted.gpg.d/
        sudo cp ../../files/hosts etc/hosts
        sudo cp ../../files/resolv.conf etc/resolv.conf
        sudo cp ../../files/quickstart.txt root/
        sudo cp ../../files/interfaces etc/network/interfaces
        sudo cp ../../files/wpa.conf etc/wpa_supplicant/wpa_supplicant.conf
        sudo cp ../../files/rc.local etc/rc.local
        sudo cp ../../files/30-modeset.conf etc/X11/xorg.conf.d/30-modeset.conf
        sudo cp ../../files/blacklist.conf etc/modprobe.d/

        sudo perl -p -i -e 's/"quiet"/"net.ifnames=0"/ if /^GRUB_CMDLINE_LINUX_DEFAULT=/' etc/default/grub

        sudo bash -c 'chroot . apt update'
        sudo bash -c 'chroot . apt install -y linux-firmware network-manager'

        sudo -- perl -p -i -e 's/root:x:/root::/' etc/passwd

        sudo -- ln -s lib/systemd/systemd init

        sudo chroot . apt update
        sudo chroot . apt install -y m1n1 linux-image-asahi
        sudo chroot . apt clean
        sudo rm var/lib/apt/lists/* || true
)
}

build_dd()
{
(
        rm -f media
        dd if=/dev/zero of=media bs=1 count=0 seek=2G
        mkdir -p mnt
        mkfs.ext4 media
        tune2fs -O extents,uninit_bg,dir_index -m 0 -c 0 -i 0 media
        sudo mount -o loop media mnt
	sudo cp -a testing/* mnt/
        sudo rm -rf mnt/init mnt/boot/efi/m1n1
        sudo umount mnt
        tar cf - media | pigz -9 > m1.tgz
)
}

build_efi()
{
(
        rm -rf EFI
        mkdir -p EFI/boot EFI/debian
	cp testing/usr/lib/grub/arm64-efi/monolithic/grubaa64.efi EFI/boot/bootaa64.efi
        export INITRD=`ls -1 testing/boot/ | grep initrd`
        export VMLINUZ=`ls -1 testing/boot/ | grep vmlinuz`
        export UUID=`blkid -s UUID -o value media`
        cat > EFI/debian/grub.cfg <<EOF
search.fs_uuid ${UUID} root
linux (\$root)/boot/${VMLINUZ} root=UUID=${UUID} rw net.ifnames=0
initrd (\$root)/boot/${INITRD}
boot
EOF
)
}

build_asahi_installer_image()
{
(
        rm -rf aii
        mkdir -p aii/esp/m1n1
        cp -a EFI aii/esp/
        cp testing/usr/lib/m1n1/boot.bin aii/esp/m1n1/boot.bin
        ln media aii/media
        cd aii
        zip -r9 ../deepin-base.zip esp media
)
}

mkdir -p build
cd build

build_rootfs
build_dd
build_efi
build_asahi_installer_image