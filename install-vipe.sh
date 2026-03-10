#!/bin/bash
set -e

vipe_dir=$1
if [ -z "$vipe_dir" ]; then
    echo "Usage: $0 <vipe_dir>"
    exit 1
fi

git clone https://github.com/nv-tlabs/vipe.git "$vipe_dir"
cd "$vipe_dir"
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
conda env create -f envs/base.yml -y
conda activate vipe
pip install -r envs/requirements.txt --extra-index-url https://download.pytorch.org/whl/cu128
pip install --no-build-isolation -e .
