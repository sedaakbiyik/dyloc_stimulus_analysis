function specTable = check_video_specs(baseDir, categories)
    % Report video specs (duration, fps, resolution, frame count) for every
    % .mp4 in each category subfolder of baseDir, as a table.
    %
    % specTable = check_video_specs(baseDir, categories)
    %
    % baseDir    - folder containing one subfolder per category (default: './stimuli')
    % categories - cell array of subfolder names to scan
    %              (default: {'dyloc_bodies','dyloc_faces','dyloc_objects','dyloc_scenes','dyloc_words'})

    if nargin < 1 || isempty(baseDir)
        baseDir = fullfile(pwd, 'stimuli');
    end
    if nargin < 2 || isempty(categories)
        categories = {'dyloc_bodies','dyloc_faces','dyloc_objects','dyloc_scenes','dyloc_words'};
    end

    category_col = {};
    file_col = {};
    duration_col = [];
    fps_col = [];
    numFrames_col = [];
    width_col = [];
    height_col = [];

    for i = 1:numel(categories)
        cat = categories{i};
        folder = fullfile(baseDir, cat);
        d = dir(fullfile(folder, '*.mp4'));

        for k = 1:numel(d)
            videoPath = fullfile(folder, d(k).name);
            vr = VideoReader(videoPath);

            category_col{end+1,1} = cat;                          %#ok<AGROW>
            file_col{end+1,1} = d(k).name;                        %#ok<AGROW>
            duration_col(end+1,1) = vr.Duration;                  %#ok<AGROW>
            fps_col(end+1,1) = vr.FrameRate;                      %#ok<AGROW>
            numFrames_col(end+1,1) = floor(vr.FrameRate * vr.Duration); %#ok<AGROW>
            width_col(end+1,1) = vr.Width;                        %#ok<AGROW>
            height_col(end+1,1) = vr.Height;                      %#ok<AGROW>
        end
    end

    specTable = table(category_col, file_col, duration_col, fps_col, numFrames_col, width_col, height_col, ...
        'VariableNames', {'category','file','duration_s','fps','num_frames','width','height'});

    fprintf('Scanned %d videos across %d categories.\n', height(specTable), numel(categories));
    disp(specTable)

    % Flag videos that deviate from the category norm (e.g. bad conversions,
    % mismatched fps/resolution across an otherwise standardized set)
    fprintf('\nSpec ranges (should be a single value each if stimuli are standardized):\n');
    fprintf('  duration_s: %.3f - %.3f\n', min(specTable.duration_s), max(specTable.duration_s));
    fprintf('  fps:        %.3f - %.3f\n', min(specTable.fps), max(specTable.fps));
    fprintf('  resolution: %d unique width/height pairs\n', size(unique([specTable.width, specTable.height], 'rows'), 1));
end
