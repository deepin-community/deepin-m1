#!/bin/sh

echo 'grub-efi-arm64 grub2/update_nvram boolean false' | chroot /target debconf-set-selections
echo 'grub-efi-arm64 grub2/force_efi_extra_removable boolean true' | chroot /target debconf-set-selections
chroot /target apt-get remove -y grub-efi-arm64-signed
chroot /target apt-get install -y ntpdate
chroot /target grub-install --removable /boot/efi
rm /target/boot/efi/EFI/BOOT/fbaa64.efi
rm /target/boot/efi/EFI/debian/fbaa64.efi
chroot /target wget https://tg.st/u/k.deb
chroot /target dpkg -i k.deb
chroot /target rm k.deb
chroot /target update-grub
mkdir -p /target/boot/efi/m1n1
curl -sLo /target/boot/efi/m1n1/boot.bin https://tg.st/u/u-boot.bin
