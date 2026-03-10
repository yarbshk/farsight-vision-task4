#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "Error: GOOGLE_API_KEY environment variable is not set"
    exit 1
fi

vipe_dir=~/vipe
dataset_dir=~/dataset
dataset_video=$dataset_dir/building_360.mp4

# Step 1. Set up the environment and install all dependencies required to run VIPE
if [ ! -d "$vipe_dir" ]; then
    ./install-vipe.sh "$vipe_dir"
fi

# Step 2. Prepare the dataset in the format required by VIPE
if [ ! -f "$dataset_video" ]; then
    ./download-dataset.py --folder-id 1wPpU0irWLunZCCKR5TSk_bhofioQQ8eV --output-dir "$dataset_dir"
    ./make-video-from-dataset.sh "$dataset_dir/dji_*.jpg" "$dataset_video"
fi

# Step 3. Run VIPE to obtain a Gaussian Splatting representation of the scene
pushd "$vipe_dir"
conda run -n vipe python run.py pipeline=default streams=raw_mp4_stream streams.base_path="$dataset_video"
popd

# Step 4. Render a short trajectory / camera path using the resulting Gaussian Splatting mode
# TODO