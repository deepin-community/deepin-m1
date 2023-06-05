#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

cd "$(dirname "$0")"

unset LC_CTYPE
unset LANG

mkdir -p build
cd build
export META_VERSION=6.3.0-4
rm -rf linux-image-asahi_${META_VERSION}_arm64
mkdir -p linux-image-asahi_${META_VERSION}_arm64/DEBIAN
cat > linux-image-asahi_${META_VERSION}_arm64/DEBIAN/control <<EOF
Package: linux-image-asahi
Version: $META_VERSION
Section: base
Depends: linux-image-6.3.0-asahi-00668-g1a9452fde941
Provides: wireguard-modules (= 1.0.0)
Priority: optional
Architecture: arm64
Maintainer: Thomas Glanzmann <thomas@glanzmann.de>
Description: Linux for 64-bit apple silicon machines (meta-package)
EOF
dpkg-deb --build linux-image-asahi_${META_VERSION}_arm64
