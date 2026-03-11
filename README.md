# farsight-vision-task4 (VIPE Gaussian Splatting Demo)

This project demonstrates how to convert a set of photos (from different angles) of a building into a 3D model of the building.

## Overview

This project has main script (i.e. `run-task.sh`) which starts the end-to-end process of converting photos to a 3D model.

The script flow:
1. Preparation: It sets up a specialized computer environment and downloads a set of photos of a building. It then joins those photos into a video.
2. Inference: A tool called vipe looks at that video and figures out exactly where the camera was positioned for every frame and how far away everything is.
3. Training: It uses Gaussian Splatting to "learn" the building's shape, colors, and reflections based on those photos/video frames and camera positions.
4. Export & Render: It saves the final 3D object and records a "fly-through" video following a cinematic path.

The script is written in bash but not Python because it contains simple OS level logic (e.g. run a command, create a directory, etc.).

## Prerequisites

Required software:
- Ubuntu 24.04
- Python 3.13.12
- bash 5.2.21(1)-release

Optional software (will be automatically installed if missing):
- ffmpeg 6.1.1-3ubuntu5
- conda 26.1.1
- [vipe](https://github.com/nv-tlabs/vipe) latest

Tested on hardware:
- GPU: 32 GB (RTX 5000 Ada)
- vCPU: 6
- Memory: 62 GB
- Container disk: 75 GB

## Live demo

Start the end-to-end process of converting photos to a 3D model on RunPod.io:
```
 export GOOGLE_API_KEY=<REDUCTED>
git clone https://github.com/yarbshk/farsight-vision-task4
./farsight-vision-task4/run-task.sh
```

The script will install all missing dependencies automatically.

## Artifacts

- Working VIPE setup (see [Live demo](https://github.com/yarbshk/farsight-vision-task4?tab=readme-ov-file#live-demo) section above)
- Gaussian Splatting result generated from the dataset
- Public [GitHub repo](https://github.com/yarbshk/farsight-vision-task4) with instructions and scripts
- [Demo video](https://github.com/yarbshk/farsight-vision-task4/blob/main/fly-through.mp4) demonstrating the full pipeline end-to-end

## Next steps

1. The resolution of original photos where reduced to 1080p to speed up testing and reduce hardware costs. Original photos may provide better results. Some testing/comparison required.

2. There is the latest dav3 vipe pipeline available. Perhaps it provides better results. Some testing/comparison required.

3. Seems like there is an option to feed frames directly to vipe (i.e. `frame_dir_stream`). Perhaps it's better in one way or another than using mp4 video stream (i.e. `raw_mp4_stream`). Not sure though if vipe can preprocess such frame stream on the fly (e.g. changing frame resolution). This requires closer look.
