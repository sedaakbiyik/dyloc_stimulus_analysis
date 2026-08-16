function match_brightness_contrast(dirPath)
    % Match brightness/contrast across all category videos in subfolders
    % Categories: faces, bodies, objects, scenes, words

    categories = {'faces', 'bodies', 'objects', 'scenes', 'words'};

    % --- Get list of all mp4 files recursively ---
    allFiles = dir(fullfile(dirPath, '**', '*.mp4'));

    % --- Filter by category names ---
    targetFiles = {};
    for i = 1:length(allFiles)
        fnameLower = lower(allFiles(i).name);
        for c = 1:length(categories)
            if contains(fnameLower, categories{c})
                targetFiles{end+1} = fullfile(allFiles(i).folder, allFiles(i).name);
                break;
            end
        end
    end

    if isempty(targetFiles)
        error('No matching category videos found in %s', dirPath);
    end

    % --- Compute global grayscale stats across all selected videos ---
    allMeans = [];
    allStds = [];

    for i = 1:length(targetFiles)
        vr = VideoReader(targetFiles{i});
        while hasFrame(vr)
            frame = im2double(readFrame(vr));
            gray = rgb2gray(frame);
            allMeans(end+1) = mean(gray, 'all');
            allStds(end+1) = std(gray, 0, 'all');
        end
    end

    refMean = mean(allMeans);
    refStd = mean(allStds);

    % --- Normalize each video and save under mirrored folder structure ---
    for i = 1:length(targetFiles)
        inputFile = targetFiles{i};
        [inputFolder, name, ~] = fileparts(inputFile);

        % Create normalized output folder maintaining subfolder structure
        relPath = strrep(inputFolder, dirPath, '');
        outputDir = fullfile(dirPath, 'normalized', relPath);
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        outputFile = fullfile(outputDir, [name '_normalized.mp4']);
        fprintf('Normalizing %s --> %s\n', name, outputFile);
        normalize_one_video(inputFile, outputFile, refMean, refStd);
    end
end


function normalize_one_video(inputFile, outputFile, refMean, refStd)
    vr = VideoReader(inputFile);
    vw = VideoWriter(outputFile, 'MPEG-4');
    vw.FrameRate = vr.FrameRate;
    open(vw);

    while hasFrame(vr)
        frame = im2double(readFrame(vr));
        gray = rgb2gray(frame);
        m = mean(gray, 'all');
        s = std(gray, 0, 'all');

        % Normalize grayscale image
        grayNorm = (gray - m) / (s + 1e-6);
        grayNorm = grayNorm * refStd + refMean;
        grayNorm = min(max(grayNorm, 0), 1);

        % Scale original RGB frame
        scale = grayNorm ./ (gray + 1e-6);
        frameNorm = frame .* scale;
        frameNorm = min(max(frameNorm, 0), 1);

        writeVideo(vw, frameNorm);
    end

    close(vw);
end
