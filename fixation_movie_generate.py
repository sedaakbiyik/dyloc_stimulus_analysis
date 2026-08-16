from moviepy.editor import *
import numpy as np
import random

# --- Parameters ---
duration = 6                      # total video duration (seconds)
fix_duration = 1.5                # fixation on duration
gap_duration = 0.5                # blank gap duration
frame_rate = 30                   # output fps
size = (800, 800)                 # video size (pixels)
fix_colors = [(255,0,0), (0,255,0), (0,0,255), (255,255,0), (255,0,255)]  # red, green, blue, yellow, magenta

# --- Background color changes every second ---
def bg_color_at_time(t):
    random.seed(int(t))  # deterministic per second
    return tuple(np.random.randint(0,256,3))

# --- Generate fixation schedule ---
events = []
t = 0
while t < duration:
    events.append((t, 'fix'))
    t += fix_duration
    if t < duration:
        events.append((t, 'gap'))
        t += gap_duration

# --- Frame drawing function ---
def make_frame(t):
    # background changes every second
    bg = bg_color_at_time(t)
    frame = np.ones((size[1], size[0], 3), dtype=np.uint8) * np.array(bg, dtype=np.uint8)

    # determine if fixation should be visible
    cumulative = 0
    current_event = None
    for start, label in events:
        if t >= start:
            current_event = label
    if current_event == 'fix':
        # determine which fixation number
        fix_index = sum(1 for start, label in events if label == 'fix' and start <= t) - 1
        color = fix_colors[fix_index % len(fix_colors)]  # assign color per fixation (wrap if needed)
        # draw fixation cross
        cross_len = 40
        cross_thick = 6
        x0, y0 = size[0]//2, size[1]//2
        frame[y0-cross_thick//2:y0+cross_thick//2, x0-cross_len//2:x0+cross_len//2] = color
        frame[y0-cross_len//2:y0+cross_len//2, x0-cross_thick//2:x0+cross_thick//2] = color
    return frame

# --- Create and save movie ---
clip = VideoClip(make_frame, duration=duration)
clip.write_videofile("fixation_movie.mp4", fps=frame_rate)
