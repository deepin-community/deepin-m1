#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

cd "$(dirname "$0")"

unset LC_CTYPE
unset LANG

export TAG=asahi-20240228


mkdir -p build
cd build

# devscripts needed for dch and dcmd
dpkg -s devscripts >/dev/null 2>&1 || sudo apt-get install devscripts

command -v git >/dev/null || sudo apt-get -y install git
sudo apt install -y libllvmspirvlib-15-dev
test -d mesa || git clone https://gitlab.freedesktop.org/asahi/mesa.git
cd mesa
git fetch -a -t
# 17:17 <marcan> also for mesa, use the latest versioned tag I made, *not* any
# live branch. mesa and kernel live branches are not kept in sync. generally
# the latest mesa tag will be in sync with the latest kernel tag and usually
# also the latest live kernel (except when I'm about to do a release)
# 17:18 <marcan> if those two desync it'll refuse to initialize
git reset --hard 
rm -rf debian
cp -a ../../mesa-debian debian
EMAIL=mengyutao@deepin.org dch -v 24.1.0-"$TAG"-`date +%Y%m%d%H%M` 'asahi wip'
sudo apt-get build-dep -y .
dpkg-buildpackage -uc -us -a arm64 --build=binary
