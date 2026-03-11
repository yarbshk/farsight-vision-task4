#!/bin/bash
set -e

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "Error: GOOGLE_API_KEY environment variable is not set"
    exit 1
fi

project_root=$(realpath $(dirname "${BASH_SOURCE[0]}"))
vipe_dir=~/vipe
dataset_dir=~/dataset
dataset_sequence=building_360
dataset_video=$dataset_dir/$dataset_sequence.mp4

# Step 1. Set up the environment and install all dependencies required to run VIPE
miniconda_root=~/miniconda3
if [ ! -d "$miniconda_root" ]; then
    miniconda_sh=/tmp/miniconda3.sh
    wget -O "$miniconda_sh" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod u+x "$miniconda_sh"
    bash "$miniconda_sh" -b -u -p "$miniconda_root"
    rm "$miniconda_sh"
    "$miniconda_root/bin/conda" init
fi
source "$miniconda_root/etc/profile.d/conda.sh"

if [ ! -d "$vipe_dir" ]; then
    git clone https://github.com/nv-tlabs/vipe.git "$vipe_dir"
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
    conda env create -f "$vipe_dir"/envs/base.yml -y
    conda run -n vipe --no-capture-output pip install -r envs/requirements.txt \
        --extra-index-url https://download.pytorch.org/whl/cu128
    conda run -n vipe --no-capture-output pip install --no-build-isolation -e .
fi

# Step 2. Prepare the dataset in the format required by VIPE
if [ ! -f "$dataset_video" ]; then
    $project_root/download-dataset.py --folder-id 1wPpU0irWLunZCCKR5TSk_bhofioQQ8eV \
        --output-dir "$dataset_dir"
    if ! command -v ffmpeg &> /dev/null; then
        echo "FFmpeg not found. Installing..."
        apt update
        apt install -y ffmpeg
    fi
    ffmpeg -framerate 1 -pattern_type glob -i "$dataset_dir/dji_*.jpg" -c:v libx264 \
        -pix_fmt yuv420p -vf "scale=1920:-2" "$dataset_video"
fi

# Step 3. Run VIPE to obtain a Gaussian Splatting representation of the scene
vipe_results=$vipe_dir/vipe_results
if [ ! -d "$vipe_results" ]; then
    conda run -n vipe --no-capture-output python "$vipe_dir"/run.py pipeline=default \
        streams=raw_mp4_stream \
        streams.base_path="$dataset_video" \
        pipeline.output.path="$vipe_results" \
        pipeline.output.skip_exists=True \
        pipeline.output.save_artifacts=True \
        pipeline.output.save_slam_map=True
fi

vipe_results_colormap=$vipe_dir/vipe_results_colmap
if [ ! -d "$vipe_results_colormap" ]; then
    conda run -n vipe --no-capture-output python "$vipe_dir"/scripts/vipe_to_colmap.py \
        $vipe_results --sequence $dataset_sequence --output "$vipe_results_colormap"
fi

nerfstudio_workdir=~/nerfstudio
nerfstudio_colormap=$nerfstudio_workdir/colmap
if [ ! -d "$nerfstudio_colormap" ]; then
    mkdir -p "$nerfstudio_colormap"/colmap/sparse/0
    cp "$vipe_results_colormap/$dataset_sequence"/*.txt "$nerfstudio_colormap"/colmap/sparse/0/
    mkdir "$nerfstudio_colormap"/images/images/
    cp "$vipe_results_colormap/$dataset_sequence"/images/*.jpg "$nerfstudio_colormap"/images/images/
fi

nerfstudio_outputs=$nerfstudio_workdir/outputs
if [ ! -d "$nerfstudio_outputs" ]; then
    conda create --name nerfstudio -y python=3.10
    conda run -n nerfstudio --no-capture-output pip install torch==2.1.2+cu118 \
        torchvision==0.16.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118
    conda install -n nerfstudio -c "nvidia/label/cuda-11.8.0" cuda-toolkit -y
    conda run -n nerfstudio --no-capture-output pip install --no-build-isolation ninja \
        git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch
    conda run -n nerfstudio --no-capture-output pip install nerfstudio
    conda run -n nerfstudio --no-capture-output ns-train splatfacto \
        --data "$nerfstudio_colormap" colmap --downscale-factor 1 \
        --output-dir "$nerfstudio_outputs" --viewer.quit-on-train-completion True
fi

training_conf_dir=$nerfstudio_outputs/$dataset_sequence/splatfacto
last_training_ts=$(ls -1t "$training_conf_dir" | head -n1)
training_conf=$training_conf_dir/$last_training_ts/config.yml
gaussian_splat_path=$nerfstudio_outputs/splat.ply
if [ ! -f "$gaussian_splat_path" ]; then
    conda run -n nerfstudio ns-export gaussian-splat --load-config "$training_conf" \
        --output-dir "$(dirname "$gaussian_splat_path")" \
        --output-filename "$(basename "$gaussian_splat_path")"
fi

# Step 4. Render a short trajectory / camera path using the resulting Gaussian Splatting mode
rendered_video=$nerfstudio_outputs/rendered_$dataset_sequence.mp4
if [ ! -f "$rendered_video" ]; then
    conda run -n nerfstudio --no-capture-output ns-render camera-path \
        --load-config "$training_conf" --camera-path-filename "$project_root/camera-path.json" \
        --output-path "$rendered_video"
fi
