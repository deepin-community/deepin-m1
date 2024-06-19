# deepin-m1

[![Build rootfs](https://github.com/deepin-community/deepin-m1/actions/workflows/build-rootfs.yml/badge.svg)](https://github.com/deepin-community/deepin-m1/actions/workflows/build-rootfs.yml)

[中文](README.md)

## Important References

Asahi Linux: https://asahilinux.org/

Asahi Linux Wiki: https://github.com/AsahiLinux/docs/wiki/

Asahi Linux Debian Installer: https://git.zerfleddert.de/cgi-bin/gitweb.cgi/m1-debian

## Introduction

Installing deepin on m1 devices requires preparing a rootfs for deepin installation, leveraging public kernel patches from Asahi and the m1n1 for system booting.

To successfully install and use deepin on Mac m1 devices, the following components are required:

- [x] deepin rootfs
- [x] m1n1
- [ ] Kernel patches
    - Apply upstream patches and drivers for m1 compatibility to the deepin maintained kernel
- [x] Modified version of Mesa with M1 GPU supports
    - [x] Correctly enable appledrm module in the kernel
    - [x] Window manager effects supports on M1 GPU
- [ ] Driver for speakers
    - [ ] Correctly enable snd_soc_macaudio module in the kernel
- [x] DDE desktop
- [x] Graphical installation wizard
    - [x] Installer user configuration program is enabled
- [x] ARM repository
    - Currently, deepin v23 has already got an arm64 repository

To further enhance supports for deepin on m1 devices, continued efforts are needed:

- [ ] Reverse-engineer device drivers
- [ ] Touchbar adaptation
    - Initially, a simulated interface can be implemented, pending driver adaptation
- [ ] Fingerprint support
    - Due to the lack of a driver for the Apple Secure Chip, fingerprint devices cannot be used
- [ ] Software support for 16k memory page size
- [ ] Optimize scheduler
    - m1 uses heterogeneous design, and the scheduler needs to assign appropriate tasks to the large and small cores for execution

Supported devices:

- [ ] MacBook Pro M1
- [ ] MacBook Pro M1 Pro/Max
- [x] Mac Mini M1

## Installation

The deepin ci repository provides ready-to-use installation scripts. Alternatively, you can install it by setting up your own installation repository.

If you don't mind getting your hands dirty, you can also install by installing only the official m1n1 + uboot boot first and then inserting a custom deepin installation USB stick.

Currently available installation methods:

- Using the online installation script
  - Using official deepin repository
  - Setting up own installation repository
- Installing UEFI, and then using an USB installation disk

### 1. Using the deepin official Installation Repository

Open Terminal on MacOS and run the following command to execute the installation script.

```zsh
curl https://ci.deepin.com/repo/deepin/deepin-ports/deepin-m1/deepin.install | sh
```

- Note: After running the script, it will prompt you to shut down. (For Mac Mini) When power on, **holding the power button** until the boot menu appears. Select deepin and follow the script instructions to set deepin as the default boot option.
- ~~The default user for deepin is hiweed with a password of 1~~
- Currently, you can create a new user during user configuration. **The root user still has no password and can log in automatically.**

### 2. Setting up Your Own Installation Repository

#### Preparations

The required rootfs for installation can be either pre-packaged or custom-built.

##### Using Pre-packaged rootfs

[![Build rootfs](https://github.com/deepin-community/deepin-m1/actions/workflows/build-rootfs.yml/badge.svg)](https://github.com/deepin-community/deepin-m1/actions/workflows/build-rootfs.yml)

The GitHub action in the repository automatically builds rootfs every Monday. You can find the download link at the bottom of the successfully completed workflow page.

https://github.com/deepin-community/deepin-m1/actions/workflows/build-rootfs.yml

##### Manually Packaging rootfs

- The rootfs package creation has been tested only on Linux (deepin V20, deepin V23, Arch Linux). It has not been tested on Mac OS. For detailed packaging steps, refer to [.github/workflows/build-rootfs.yml](.github/workflows/build-rootfs.yml).

- Install Necessary Dependencies:
	- debootstrap
	- eatmydata
	- pigz
	- qemu-user-static (required ion a non-ARM machine)
- Create Script Link: Create a symbolic link pointing to /usr/share/debootstrap/scripts/buster as /usr/share/debootstrap/scripts/beige.

```bash
    sudo ln -s /usr/share/debootstrap/scripts/buster /usr/share/debootstrap/scripts/beige
```

- For Non-deepin Distributions:
	- Keyring: Obtain the keyring located at /usr/share/keyrings/deepin-archive-camel-keyring.gpg. For non-deepin distributions, you can get it by unpacking the deepin-keyring package.
	- Arch or Other Non-Debian-Based Distributions: In /usr/share/debootstrap/scripts/debian-common, **comment out** the switch-case block that adds the usr-is-merged dependency.

#### Setting Up the Repository

First, because the installation script uses an online installation way, you need to set up an installation repository (HTTP is recommended; other methods like local have not been tested. According to justforlxz, the local method might fail at a certain step, though I haven't tried it myself). (**A server set up using Python's `http.server` cannot be used by the installation script, as I've tested. Instead, I used Apache2's HTTP service.**)

1. The repository structure is as follows:

   ```bash
   /path/to/repo
   ├── asahilinux.install     # Optional; typically modify the official installation script to use the file server address containing the repo
   ├── installer_data.json    # Provided with this project
   └── os
       ├── deepin-base.zip    # Generated in the build directory after running bootstrap.sh from this project
       └── deepin-desktop.zip # Generated in the build directory after running bootstrap.sh from this project

After setting up the repository, refer to the [official tutorial](https://asahilinux.org/2022/03/asahi-linux-alpha-release/) for installation. Here is a brief overview of the process:

1. **Run the Asahi Linux installation script**. Generally, you can use the [official script](https://alx.sh) and modify the `INSTALLER_DATA` variable to use the deepin installation repository URL, or you may change the `REPO_BASE` in the `asahilinux.install` file from this project.

   ```bash
   # Assuming the installation script is placed in the root directory of your repository
   curl protocol://hostname:port/path/to/repo/asahilinux.install | sh
   ```

2. **Follow the script's instructions**. :)

### 3. Using the deepin 23 for M1 Installation Disk

The deepin installation disk mentioned here is **not the usual ISO image used for standard machines.** You only need to **create a FAT partition on a USB drive** and **write the installation content to the root directory**.

Steps to create the installation disk are as followings:

- **Create the Installation Disk**:

  - According to the m1-debian instructions, run the following commands to create the partition.

    ```bash
    # Replace with your USB drive's corresponding device
    DEVICE=/dev/sdX
    sudo parted -a optimal $DEVICE mklabel msdos
    sudo parted -a optimal $DEVICE mkpart primary fat32 2048s 100%
    sudo mkfs.vfat ${DEVICE}1
    sudo mount ${DEVICE}1 /mnt
    ```

  - Download the installation disk archive from [here](https://ci.deepin.com/repo/deepin/deepin-ports/deepin-m1/deepin-m1-usb-installer.zip) and extract it to the **root directory** of the **USB drive's FAT partition**.

- **Install m1n1 + U-Boot Bootloader on Mac**. (In the Asahi Linux official installation script, select the  option: UEFI environment only, m1n1 + U-Boot + ESP)

  ```bash
  curl https://alx.sh/ | sh

- Follow the script's instructions to install the boot system and set it as the default boot option.
- Insert an USB drive and boot as usual. If the USB drive is not recognized, run `usb reset` command in the U-Boot interface to refresh.
- During installation, choose **custom installation and select the free disk space** for installation.

**(!!! Do not choose full disk installation or advanced installation. This will erase the existing macOS system and bootloader, potentially bricking the machine and requiring a recovery flash. !!!)**

**(!!! Do not choose full disk installation or advanced installation. This will erase the existing macOS system and bootloader, potentially bricking the machine and requiring a recovery flash. !!!)**

**(!!! Do not choose full disk installation or advanced installation. This will erase the existing macOS system and bootloader, potentially bricking the machine and requiring a recovery flash. !!!)**

## Progress on Porting DDE Desktop

The current packaging script generates a `deepin-desktop.zip` file, which contains the rootfs package with a pre-installed desktop environment.

For the base package, it generally requires installing the following: dde-session-ui, deepin-desktop-environment-core, deepin-desktop-environment-base, dde-session-shell, libssl-dev.(Note: Packaging for libssl has some issues; `libssl.so` is not provided and needs fixing)

~~The default user is `hiweed` with the password `1`~~. Now you can create a new user upon first boot.

(When installing the desktop environment from the deepin-base package, sound might work initially but becomes non-functional after a reboot.)

### Known Issues

- The cross compilation of m1n1, uboot and kernel on X86 cannot work. The CI builds can only be a reference of compiling process rather than practical use.
- The system cannot detect any sound devices, resulting in no sound playback. There is a small chance that sound works right after installation.
- The USB installation method can only use custom installation and cannot alter any existing partitions, or the machine might be bricked.
- No hibernation function.
- No applications available in the app store.
- Changing brightness has no effect.
- Adjusting color temperature has no effect.
- Misalignment and overlapping in the Deepin Home application title bar.
- Unable to mount partitions of other operating systems in the file manager.

## FAQ

#### Q: After a reboot, my system suddenly blacked out and rebooted during a local policy update.

**A:** Refer to [Asahi Linux: How Do I Uninstall It?](https://asahilinux.org/2022/03/asahi-linux-alpha-release/#how-do-i-uninstall-it). In short, you need to run the official `cleanbp.sh` script to clear boot policies, either in recoveryOS or with SIP disabled.

To open Terminal in recoveryOS: `shift+win+t` (on a standard en_US keyboard).

#### Q: How do I uninstall the installed Linux system?

**A:** You can use the [wipe-linux.sh](https://github.com/AsahiLinux/asahi-installer/blob/main/tools/wipe-linux.sh) script.
