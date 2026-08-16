cd /Users/sedaakbiyik/Desktop/DBP_ResolutionPilot/DynamicLocalizer/stimuli

for cat in dyloc_bodies dyloc_objects dyloc_faces dyloc_scenes dyloc_words; do
  mkdir -p "../stimuli_std/$cat"
  for f in "$cat"/*.mp4; do
    ffmpeg -y -i "$f" \
      -vf "fps=30,tpad=stop_mode=clone:stop_duration=0.5" \
      -t 2 \
      -c:v libx264 -preset slow -pix_fmt yuv420p \
      -b:v 1000k -maxrate 1100k -bufsize 2000k \
      -g 30 -keyint_min 30 -sc_threshold 0 \
      -an -movflags +faststart \
      "../stimuli_std/$f"
  done
done

