#!/bin/bash

VENV_DIR=$HOME/.kas-venv
KAS_WORKDIR=$HOME/kas-workdir
TARGET_MACHINE=arm64vm

sudo apt install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 lz4 locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd python3-venv python3-websockets

python3 -m venv "$VENV_DIR"
source "${VENV_DIR}/bin/activate"
pip install kas
pip install websockets

mkdir -p "$KAS_WORKDIR"
cp -r meta-everest-dev "$KAS_WORKDIR"
cd "$KAS_WORKDIR"
kas build "meta-everest-dev/${TARGET_MACHINE}.yml"

