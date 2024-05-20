#!/usr/bin/env bash

# SPDX-License-Identifier: MIT

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

cd "$(dirname "$0")"

export CARGO_HOME="$(pwd)/build/cargo"
export RUSTUP_HOME="$(pwd)/build/rust"
source "$(pwd)/build/cargo/env"

unset LC_CTYPE
unset LANG

export M1N1_VERSION=1.4.14
export KERNEL_VERSION=asahi-6.8.9-1
export UBOOT_VERSION=asahi-v2024.04-1
export ARCH=arm64

build_linux()
{
(
        test -d linux || git clone https://github.com/AsahiLinux/linux
        cd linux
        git fetch -a -t
        git reset --hard $KERNEL_VERSION
        git clean -f -x -d > /dev/null
        cat ../../config.txt > .config
        make LLVM=-15 rustavailable
        make LLVM=-15 olddefconfig
        make -j `nproc` LLVM=-15 V=0 bindeb-pkg > /dev/null
)
}

build_m1n1()
{
(
        test -d m1n1 || git clone --recursive https://github.com/AsahiLinux/m1n1
        cd m1n1
        git fetch -a -t
        git reset --hard v${M1N1_VERSION};
        git clean -f -x -d > /dev/null
        make -j `nproc`
)
}

build_uboot()
{
(
        test -d u-boot || git clone https://github.com/AsahiLinux/u-boot
        cd u-boot
        git fetch -a -t
        git reset --hard $UBOOT_VERSION
        git clean -f -x -d > /dev/null

        make apple_m1_defconfig
        make -j `nproc`
)
        cat m1n1/build/m1n1.bin   `find linux/arch/arm64/boot/dts/apple/ -name \*.dtb` <(gzip -c u-boot/u-boot-nodtb.bin) > u-boot.bin
}

package_boot_bin()
{
(
        rm -rf m1n1_${M1N1_VERSION}_arm64
        mkdir -p m1n1_${M1N1_VERSION}_arm64/DEBIAN m1n1_${M1N1_VERSION}_arm64/usr/lib/m1n1/
        cp u-boot.bin m1n1_${M1N1_VERSION}_arm64/usr/lib/m1n1/boot.bin
        cat <<EOF > m1n1_${M1N1_VERSION}_arm64/DEBIAN/control
Package: m1n1
Version: $M1N1_VERSION
Section: base
Priority: optional
Architecture: arm64
Maintainer: Thomas Glanzmann <thomas@glanzmann.de>
Description: Apple silicon boot loader
 Next to m1n1 this also contains the device trees and u-boot.
EOF

        cat > m1n1_${M1N1_VERSION}_arm64/DEBIAN/postinst <<'EOF'
#!/bin/bash

export PATH=/bin
if [ -f /boot/efi/m1n1/boot.bin ]; then
        cp /boot/efi/m1n1/boot.bin /boot/efi/m1n1/`date +%Y%m%d%H%M`.bin
fi
mkdir -p /boot/efi/m1n1/
cp /usr/lib/m1n1/boot.bin /boot/efi/m1n1/
EOF

        chmod 755 m1n1_${M1N1_VERSION}_arm64/DEBIAN/postinst
        dpkg-deb --build m1n1_${M1N1_VERSION}_arm64
)
}

mkdir -p build
cd build

build_linux
build_m1n1
build_uboot
package_boot_bin
