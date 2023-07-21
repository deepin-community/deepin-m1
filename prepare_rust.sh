#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

cd "$(dirname "$0")"

unset LC_CTYPE
unset LANG

export CARGO_HOME="$HOME/.cargo/bin"
export LLVM_HOME="/usr/lib/llvm-14/bin"
export PATH=$CARGO_HOME:$LLVM_HOME:$PATH
sudo apt install -y rustc rust-src cargo
cargo install --locked --version=0.56.0 bindgen
