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

handle_crosscompile()
{
        if [ "`uname -m`" != 'aarch64' ]; then
                export ARCH=arm64
                export CROSS_COMPILE=aarch64-linux-gnu-
                sudo apt install -y libc6-dev-arm64-cross
        fi
}

build_linux()
{
(
        handle_crosscompile
        test -d linux || git clone https://github.com/AsahiLinux/linux
        cd linux
        git fetch -a -t
        git reset --hard origin/asahi-wip;
        curl -sL https://tg.st/u/5ec32cdb6555bf935fd621ef8923410a1f51b5b9.patch | git am -
        curl -sL https://tg.st/u/c65f0ecca767f7853bf33f1710d7637f11b70403.patch | git am -
        cat ../../config.txt > .config
        make LLVM=${CLANG_VERSION} rustavailable
        make LLVM=${CLANG_VERSION} olddefconfig
        make -j `nproc` LLVM=${CLANG_VERSION} V=0 bindeb-pkg > /dev/null
)
}

build_m1n1()
{
(
        test -d m1n1 || git clone --recursive https://github.com/AsahiLinux/m1n1
        cd m1n1
        git fetch -a -t
        git reset --hard v1.2.7-7-g076217a;
        make -j `nproc`
)
}

build_uboot()
{
(
        handle_crosscompile
        test -d u-boot || git clone https://github.com/AsahiLinux/u-boot
        cd u-boot
        git fetch -a -t
        git reset --hard asahi-v2023.01-3;

        make apple_m1_defconfig
        make -j `nproc`
)
        cat m1n1/build/m1n1.bin   `find linux/arch/arm64/boot/dts/apple/ -name \*.dtb` <(gzip -c u-boot/u-boot-nodtb.bin) > u-boot.bin
}

package_boot_bin()
{
(
        export M1N1_VERSION=1.2.7-3
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

if type clang-15; then
        export CLANG_VERSION=-15
elif type clang-11; then
        export CLANG_VERSION=-11
fi

mkdir -p build
cd build

build_linux
build_m1n1
build_uboot
package_boot_bin
