This pages explains how to install Debian on Apple Silicon machines.

# Tripwires
The USB-A Port on the Mac Mini will not work in u-boot and grub.  The two
additional USB-3 ports on the iMac 4 port model don't work in u-boot, grub
and Linux. In order to install Linux on a FileVault-enabled Mac run the
installer from Recovery open Disk Utility > Expanding "Macintosh HD" >
Selecting locked volume > click "Mount". Debian does not include the choosen
EFI patch. As a result it will always pick the first ESP partition. This can be
problematic if you're using multiple ESP partitions for example when having
multiple Linux and BSD installations.

# Artefacts
If you don't want to use the prebuild artefacts, you can build them yourself
using the following scripts:

        - prepare_rust.sh - Prepares a rust installation suitable for kernel compilation
        - m1n1_uboot_kernel.sh - Builds m1n1, u-boot and the kernel including gpu support.
        - mesa.sh - Creates mesa packages
        - bootstrap.sh - Creates Debian root and live filesystem
        - meta.sh - Meta package which makes sure that we always get latest and greatest kernel.

# Asahi installer

[Video Recording](https://tg.st/u/debian_asahi_installer.mp4)

* Poweroff your Mac. Hold and press the power button until you see a wheel chain and Options written below. Approx 20 seconds.

* In the boot picker, choose Options. Once loaded, open a Terminal under Utilities > Terminal

* Run the asahi installer and select Debian:

        curl -sL https://tg.st/d | sh

* Follow the installer instructions.

* Once Debian is booted log in as root without password and set a root password

        passwd
        pwconv

* Configure wifi by editing the wpa_supplicant.conf, enabling the interface and remove the # before allow-hotplug to enable it during boot.

        vi /etc/wpa_supplicant/wpa_supplicant.conf
        ifup wlan0
        vi /etc/network/interfaces

* Reboot to see if grub was correctly installed

        reboot

* Install a desktop environment for example blackbox

        apt-get update
        apt-get install -y xinit blackbox xterm firefox-esr lightdm

* Create yourself an unprivileged user

        useradd -m -c 'Firstname Lastname' -s /bin/bash <username>
        passwd <username>

* Optional install sshd. You can not log in as root, but only with your unprivileged user

        apt update
        apt install -y openssh-server

* Consult the **[/root/quickstart.txt](https://git.zerfleddert.de/cgi-bin/gitweb.cgi/m1-debian/blob_plain/refs/heads/master:/files/quickstart.txt)** file to find out how to do other interesting things.

# Livesystem

[Video Recording](https://tg.st/u/live.mp4)

* Prerequisites

        - USB Stick. this is what this guide assumes, but it is also possible
          to run the Debian livesystem from another PC using m1n1 chainloading.
          But if you know how to do that, you probably don't need this guide.
        - If possible use an Ethernet Dongle, less typing.

* Create USB Stick with a single vfat partition on it and untar the modified Debian installer on it. Instructions for Linux:

        # Identify the usb stick device
        lsblk

        DEVICE=/dev/sdX
        parted -a optimal $DEVICE mklabel msdos
        parted -a optimal $DEVICE mkpart primary fat32 2048s 100%
        mkfs.vfat ${DEVICE}1
        mount ${DEVICE}1 /mnt
        curl -sL https://tg.st/u/asahi-debian-live.tar | tar -C /mnt -xf -
        umount /mnt

In order to format the usb stick under Macos, open the disk utility, right-click on the usb stick (usually the lowest device in the list) and select erase. Choose the following options:

        Name: LIVE
        Format: MS-DOS (FAT)
        Scheme: Master Boot Record

Than open a terminal, and run the following commands:

        sudo su -
        cd /Volumes/LIVE
        curl -sL https://tg.st/u/asahi-debian-live.tar | tar -xf -

* You need to run the asahi installer and have either an OS installed or m1n1+UEFI.

* If you have a EFI binary on the NVMe and want to boot from the usb stick, you need to interrupt u-boot on the countdown by pressing any key and run the following comamnd to boot from usb:

        run bootcmd_usb0

* Reboot with the USB stick connected, the Debian livesystem should automatically start, if it doesn't load the kernel and initrd manually, you can use tab. For x try 0,1,2,...

        linux (hdX,msdos1)/vmlinuz
        initrd (hdX,msdos1)/initrd.gz
        boot

* Log in as **root** without password.

* Consult the **[/root/quickstart.txt](https://git.zerfleddert.de/cgi-bin/gitweb.cgi/m1-debian/blob_plain/refs/heads/master:/files/quickstart.txt)** file to find out how to get the networking up, etc.

# FAQ

* If I install Debian, will it be easy to update the Asahi work as it develops?

Yes, long answer below.

To update the kernel to the lastest "stable" asahi branch you need to run
as root:

        apt update
        apt upgrade

For installations before 2022-12-12, see <https://thomas.glanzmann.de/asahi/README.txt>

Later it might be necessary to upgrade the stub parition in order to
support the GPU code. As soon as that happens, I'll add the
instructions and a video in order to do so, but short version is:

        - Backup /boot/efi/EFI
        - Delete the old stub and efi/esp partition
        - Rerun the asahi installer with m1n1+u-boot option
        - Put the /boot/efi/EFI back

So, you never need to reinstall Debian. Kernel updates are easy, stub
updates are a little bit more cumbersome but also seldom.
