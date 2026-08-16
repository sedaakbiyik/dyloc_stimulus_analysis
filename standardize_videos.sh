#!/usr/bin/env bash
# Standardize category videos to 30fps, 2s (padded/trimmed), silent, faststart mp4.
# Usage: ./standardize_videos.sh [baseDir]
#   baseDir - folder containing one subfolder per category (default: ./stimuli)

set -euo pipefail

base_dir="${1:-./stimuli}"
out_dir="${base_dir}/../stimuli_std"

for cat in dyloc_bodies dyloc_objects dyloc_faces dyloc_scenes dyloc_words; do
  mkdir -p "$out_dir/$cat"
  for f in "$base_dir/$cat"/*.mp4; do
    [ -e "$f" ] || continue
    ffmpeg -y -i "$f" \
      -vf "fps=30,tpad=stop_mode=clone:stop_duration=0.5" \
      -t 2 \
      -c:v libx264 -preset slow -pix_fmt yuv420p \
      -b:v 1000k -maxrate 1100k -bufsize 2000k \
      -g 30 -keyint_min 30 -sc_threshold 0 \
      -an -movflags +faststart \
      "$out_dir/$cat/$(basename "$f")"
  done
done
