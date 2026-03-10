#!/bin/bash
set -e

input_pattern=$1
output_file=$2
if [ -z "$input_pattern" ] || [ -z "$output_file" ]; then
    echo "Usage: $0 <input_pattern> <output_file>"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Error: FFmpeg not found. Installing..."
    apt update
    apt install -y ffmpeg
fi

ffmpeg -framerate 10 -pattern_type glob -i "$input_pattern" -c:v libx264 -crf 0 -pix_fmt yuv420p "$output_file"
