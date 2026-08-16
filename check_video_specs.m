% Specify your video file
videoPath = '/Users/sedaakbiyik/Dropbox/Stanford/Projects/dyloc_development/stimuli_to_test/dyloc_faces/Faces_ZZ_04.mp4';

% Create VideoReader object
vr = VideoReader(videoPath);

% Basic properties
numFrames = floor(vr.FrameRate * vr.Duration); % approximate total frames
fps = vr.FrameRate;                            % frames per second
duration = vr.Duration;                        % seconds
width = vr.Width;                              % pixels
height = vr.Height;                            % pixels

% Display
fprintf('Video file: %s\n', videoPath);
fprintf('Duration: %.2f seconds\n', duration);
fprintf('Frame rate: %.2f fps\n', fps);
fprintf('Approx. number of frames: %d\n', numFrames);
fprintf('Resolution: %d x %d\n', width, height);
