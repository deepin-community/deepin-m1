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

cd build

test -d speakersafetyd/ || git clone https://github.com/AsahiLinux/speakersafetyd
cd speakersafetyd/
git fetch -a -t
git reset --hard origin/HEAD

cat <<'EOF' >> Cargo.toml
[package.metadata.deb]
maintainer = "Thomas Glanzmann <thomas@glanzmann.de>"
copyright = "The Asahi Linux Contributors"
license-file = ["LICENSE", "0"]
depends = "$auto"
assets = [
        ["LICENSE", "/var/lib/speakersafetyd/blackbox/", "644"],
        ["target/release/speakersafetyd", "/usr/bin/speakersafetyd", "755"],
        ["95-speakersafetyd.rules", "/usr/lib/udev/rules.d/95-speakersafetyd.rules", "644"],
        ["speakersafetyd.service", "/usr/lib/systemd/system/speakersafetyd.service", "644"],
        ["conf/apple/*", "/usr/share/speakersafetyd/apple/", "644"],
]
EOF

make
cargo install cargo-deb
cargo deb
