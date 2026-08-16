# Dynamic Localizer Stimulus Analysis

Code for editing, standardizing, and analyzing video stimuli used in a dynamic
functional localizer (faces, bodies, objects, scenes, words).

## Contents

- `check_video_specs.m` — inspect video properties (resolution, frame rate, duration).
- `standardize_videos.m` — standardize stimulus video format/resolution.
- `match_brightness_contrast.m` — match luminance/contrast across stimulus videos.
- `Dyloc_StandardizeRename_toShare.m` — batch rename/organize stimuli into a shareable, standardized set.
- `Dyloc_Stimuli_Editing_RDMs_SKA_Jan252026.ipynb` — stimulus property editing and representational dissimilarity matrix (RDM) analysis.
- `Dyloc_Stimuli_MotionEnergy_SKA_Jan252026.ipynb` — motion energy analysis of stimulus videos.
- `fixation_movie_generate.py` / `.ipynb` — generate fixation-cross movies for use between stimulus blocks.
