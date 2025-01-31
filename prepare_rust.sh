#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

cd "$(dirname "$0")"

unset LC_CTYPE
unset LANG

mkdir -p "$(pwd)/build"
export CARGO_HOME="$(pwd)/build/cargo"
export RUSTUP_HOME="$(pwd)/build/rust"
rm -rf ${CARGO_HOME} ${RUSTUP_HOME}
curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path --default-toolchain none
source "$(pwd)/build/cargo/env"
rustup override set 1.84.1
rustup default 1.84.1
rustup component add rust-src
cargo install --locked --version 0.71.1 bindgen-cli
rustup component add rustfmt
rustup component add clippy
