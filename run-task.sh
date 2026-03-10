#!/bin/bash
set -e

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "Error: GOOGLE_API_KEY environment variable is not set"
    exit 1
fi

project_root=$(realpath $(dirname "${BASH_SOURCE[0]}"))
vipe_dir=~/vipe
dataset_dir=~/dataset
dataset_video=$dataset_dir/building_360.mp4

# Step 1. Set up the environment and install all dependencies required to run VIPE
source $project_root/setup-conda.sh
if [ ! -d "$vipe_dir" ]; then
    source $project_root/install-vipe.sh "$vipe_dir"
fi

# Step 2. Prepare the dataset in the format required by VIPE
if [ ! -f "$dataset_video" ]; then
    # $project_root/download-dataset.py --folder-id 1wPpU0irWLunZCCKR5TSk_bhofioQQ8eV --output-dir "$dataset_dir"
    $project_root/make-video-from-dataset.sh "$dataset_dir/dji_*.jpg" "$dataset_video"
fi

# Step 3. Run VIPE to obtain a Gaussian Splatting representation of the scene
pushd "$vipe_dir"
conda run -n vipe python run.py pipeline=default \
    streams=raw_mp4_stream \
    streams.base_path="$dataset_video" \
    pipeline.output.skip_exists=True \
    pipeline.output.save_artifacts=True \
    pipeline.output.save_slam_map=True
conda run -n vipe --no-capture-output python scripts/vipe_to_colmap.py vipe_results/ --sequence building_360
popd

conda create --name nerfstudio -y python=3.10
conda run -n nerfstudio --no-capture-output pip install torch==2.1.2+cu118 torchvision==0.16.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118
conda install -n nerfstudio --no-capture-output -c "nvidia/label/cuda-11.8.0" cuda-toolkit -y
conda run -n nerfstudio --no-capture-output pip install --no-build-isolation ninja git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch
conda run -n nerfstudio --no-capture-output pip install nerfstudio

# Step 4. Render a short trajectory / camera path using the resulting Gaussian Splatting mode
# TODO