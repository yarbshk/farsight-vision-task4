# farsight-vision-task4 (VIPE Gaussian Splatting Demo)

This project helps to convert a bunch of photos of a building to a 3D model of the building.

## Prerequisites

Required:
- Ubuntu 24.04
- Python 3.13.12
- bash 5.2.21(1)-release

Optional (will be automatically installed if missing):
- ffmpeg 6.1.1-3ubuntu5
- conda 26.1.1
- [vipe](https://github.com/nv-tlabs/vipe) latest

## Live Demo

Run on RunPod.io:
```
git clone https://github.com/yarbshk/farsight-vision-task4
./farsight-vision-task4/run-task.sh
```

The `run-task.sh` script will do the following:
1. Set up the environment and install all dependencies required to run VIPE
2. Prepare the dataset in the format required by VIPE
3. Run VIPE to obtain a Gaussian Splatting representation of the scene
4. Render a short trajectory / camera path using the resulting Gaussian Splatting model

The script will install all missing dependencies automatically.
