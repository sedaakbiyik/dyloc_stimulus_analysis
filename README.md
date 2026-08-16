# Dynamic Localizer Stimulus Analysis

Code for editing, standardizing, and analyzing video stimuli used in a dynamic
functional localizer (faces, bodies, objects, scenes, words).

Scripts expect a `stimuli/` folder (path configurable via the `DYLOC_STIMULI_DIR`
environment variable) containing one subfolder per category:
`dyloc_bodies`, `dyloc_faces`, `dyloc_objects`, `dyloc_scenes`, `dyloc_words`.

## Contents

- `check_video_specs.m` — scan all stimulus videos and build a table of specs (duration, fps, resolution, frame count) to catch inconsistencies in a supposedly standardized set.
- `standardize_videos.sh` — standardize stimulus video format/resolution/duration via ffmpeg.
- `Dyloc_Stimuli_Editing_RDMs_SKA_Jan252026.ipynb` — stimulus property editing and representational dissimilarity matrix (RDM) analysis (pixelwise color, pixelwise grayscale, optic-flow motion).
- `Dyloc_Stimuli_MotionEnergy_SKA_Jan252026.ipynb` — motion energy analysis of stimulus videos using [pymoten](https://gallantlab.org/pymoten/).
