#!/bin/bash
set -e

miniconda_root=~/miniconda3

if [ ! -d "$miniconda_root" ]; then
    miniconda_sh=/tmp/miniconda3.sh
    wget -O "$miniconda_sh" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod u+x "$miniconda_sh"
    bash "$miniconda_sh" -b -u -p "$miniconda_root"
    rm "$miniconda_sh"
    "$miniconda_root/bin/conda" init
fi

# ~/.bashrc has a guard which prevents it from sourcing in a non-interactive session
source "$miniconda_root/etc/profile.d/conda.sh"