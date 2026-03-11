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

## Live demo

Run task on RunPod.io:
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

## Artifacts

TODO

## Next steps

1. Seems like there is an option to feed frames directly to vipe (i.e. `frame_dir_stream`). Perhaps it's better in one way or another than using mp4 video stream (i.e. `raw_mp4_stream`). Not sure if vipe can preprocess such frame stream on the fly (e.g. changing frame resolution). This requires closer look.
