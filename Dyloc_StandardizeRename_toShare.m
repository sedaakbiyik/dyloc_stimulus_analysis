%% settings (edit these, then run this section)
sourceFolder = fullfile(pwd, 'stimuli');
outputFolder = fullfile(sourceFolder, 'dyloc_stimuli_std');
outputFolderHQ = fullfile(sourceFolder, 'dyloc_stimuli_stdHQ');
mappingCsv   = fullfile(outputFolder, 'dyloc_rename_mapping.csv');

categories = {'dyloc_bodies','dyloc_objects','dyloc_faces','dyloc_scenes','dyloc_words'};

% MATLAB's system() calls don't load your shell's .zshrc/.zprofile, so
% Homebrew-installed tools like ffmpeg are often invisible even though
% they work fine in Terminal. Extend PATH here to cover common locations.
% If ffmpeg still isn't found, run `which ffmpeg` in Terminal and paste
% the full path into ffmpegPath below instead of just 'ffmpeg'.
ffmpegPath = '/opt/homebrew/bin/ffmpeg';  % confirmed via 'which ffmpeg' in Terminal
if ismac
    extraPaths = {'/opt/homebrew/bin', '/usr/local/bin'};
    setenv('PATH', [getenv('PATH') ':' strjoin(extraPaths, ':')]);
end

%% parsing rules per category
% Everything except words looks like: <Category>_<identifier>_<number>.mp4
% Words look like: Words_<NL>_<word>.mp4 and stay unchanged.
genericPattern = '^(?<cat>[A-Za-z]+)_(?<ident>[A-Za-z0-9]+)_(?<num>\d+)\.mp4$';
wordsPattern   = '^Words_(?<len>\d+L)_(?<word>[A-Za-z]+)\.mp4$';

%% scan each category folder and parse filenames
parsed = struct();

for i = 1:numel(categories)
    cat = categories{i};
    folder = fullfile(sourceFolder, cat);
    d = dir(fullfile(folder, '*.mp4'));
    files = sort({d.name});

    rows = struct('old_name', {}, 'ident', {}, 'num', {}, 'len_token', {}, 'word', {});
    for k = 1:numel(files)
        f = files{k};
        if strcmp(cat, 'dyloc_words')
            tok = regexp(f, wordsPattern, 'names');
            if isempty(tok)
                warning('"%s" in %s did not match the expected words pattern, skipping', f, cat);
                continue
            end
            rows(end+1) = struct('old_name', f, 'ident', '', 'num', '', ...
                                  'len_token', tok.len, 'word', tok.word); %#ok<AGROW>
        else
            tok = regexp(f, genericPattern, 'names');
            if isempty(tok)
                warning('"%s" in %s did not match the expected pattern, skipping', f, cat);
                continue
            end
            rows(end+1) = struct('old_name', f, 'ident', tok.ident, 'num', tok.num, ...
                                  'len_token', '', 'word', ''); %#ok<AGROW>
        end
    end
    parsed.(cat) = rows;
    fprintf('%s: %d files found, %d parsed\n', cat, numel(files), numel(rows));
end

%% build anonymized identifier codes (per category, independent numbering)
% Faces -> A01, A02 ...   Bodies -> A01, A02 ...   Objects -> O01, O02 ...   Scenes -> S01, S02 ...
codePrefix = containers.Map({'dyloc_faces','dyloc_bodies','dyloc_objects','dyloc_scenes'}, ...
                             {'A','A','C','S'});

identMaps = containers.Map();  % category -> containers.Map(oldIdent -> newCode)
anonCats = {'dyloc_faces','dyloc_bodies','dyloc_objects','dyloc_scenes'};

for i = 1:numel(anonCats)
    cat = anonCats{i};
    rows = parsed.(cat);
    idents = unique({rows.ident});   % unique() also sorts alphabetically
    prefix = codePrefix(cat);

    m = containers.Map();
    width = max(2, numel(num2str(numel(idents))));  % zero-pad so ordering stays correct (01, 02... not 1, 2)
    for j = 1:numel(idents)
        m(idents{j}) = sprintf('%s%0*d', prefix, width, j);
    end
    identMaps(cat) = m;

    fprintf('\n%s identifier mapping:\n', cat);
    for j = 1:numel(idents)
        fprintf('  %s -> %s\n', idents{j}, m(idents{j}));
    end
end

%% build the full old_name -> new_name table for every file
% Numbers are renumbered sequentially (1, 2, 3...) per identifier, with no
% gaps -- so e.g. if EK had 01,02,03,04,05,07,08,09 (missing 06), the new
% codes become 01 through 08 with no gap.
dispName = containers.Map({'dyloc_faces','dyloc_bodies','dyloc_objects','dyloc_scenes','dyloc_words'}, ...
                           {'Faces','Bodies','Objects','Scenes','Words'});

category_col = {};
old_name_col = {};
new_name_col = {};

for i = 1:numel(categories)
    cat = categories{i};
    disp_ = dispName(cat);
    rows = parsed.(cat);

    if strcmp(cat, 'dyloc_words')
        for k = 1:numel(rows)
            r = rows(k);
            category_col{end+1,1} = cat;         %#ok<AGROW>
            old_name_col{end+1,1} = r.old_name;   %#ok<AGROW>
            new_name_col{end+1,1} = r.old_name;   %#ok<AGROW> % unchanged
        end
    else
        % group rows by identifier, sort each group by its original
        % number, then assign fresh sequential numbers
        idents = unique({rows.ident});
        m = identMaps(cat);
        for ii = 1:numel(idents)
            ident = idents{ii};
            groupMask = strcmp({rows.ident}, ident);
            groupRows = rows(groupMask);
            nums = arrayfun(@(r) str2double(r.num), groupRows);
            [~, order] = sort(nums);
            groupRows = groupRows(order);

            newCode = m(ident);
            for seq = 1:numel(groupRows)
                r = groupRows(seq);
                newNum = sprintf('%02d', seq);
                newName = sprintf('%s_%s_%s.mp4', disp_, newCode, newNum);
                category_col{end+1,1} = cat;       %#ok<AGROW>
                old_name_col{end+1,1} = r.old_name; %#ok<AGROW>
                new_name_col{end+1,1} = newName;    %#ok<AGROW>
            end
        end
    end
end

renameTable = table(category_col, old_name_col, new_name_col, ...
    'VariableNames', {'category','old_name','new_name'});
fprintf('\nTotal files to process: %d\n', height(renameTable));
disp(renameTable)

%% sanity check: any new-name collisions within a category?
keyStrings = strcat(renameTable.category, '||', renameTable.new_name);
[~, ~, ic] = unique(keyStrings);
counts = accumarray(ic, 1);
dupRows = counts(ic) > 1;

if any(dupRows)
    warning('Collisions found -- fix these before proceeding:');
    disp(renameTable(dupRows, :));
else
    disp('No collisions -- safe to proceed.');
end

%% save the mapping (old name -> new name) for your records
% NOTE: for faces/bodies this file links anonymized codes back to real actor
% initials -- keep it somewhere private, not in the shared stimuli folder.
writetable(renameTable, mappingCsv);
fprintf('Saved mapping to %s\n', mappingCsv);

%% run ffmpeg standardization + rename, category by category
% Mirrors your original bash loop, but writes directly to the new anonymized
% filename and saves under outputFolder on your Desktop.
dryRun = false;  % keep true to just print the commands first; set false to actually run ffmpeg

for i = 1:numel(categories)
    cat = categories{i};
    outDir = fullfile(outputFolder, cat);
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    catRows = renameTable(strcmp(renameTable.category, cat), :);
    for k = 1:height(catRows)
        oldName = catRows.old_name{k};
        newName = catRows.new_name{k};
        src = fullfile(sourceFolder, cat, oldName);
        dst = fullfile(outDir, newName);

        cmd = sprintf(['ffmpeg -y -i "%s" -vf "fps=30,tpad=stop_mode=clone:stop_duration=0.5" ' ...
                       '-t 2 -c:v libx264 -preset slow -pix_fmt yuv420p -b:v 1000k -maxrate 1100k ' ...
                       '-bufsize 2000k -g 30 -keyint_min 30 -sc_threshold 0 -an -movflags +faststart "%s"'], ...
                       src, dst);

        if dryRun
            fprintf('[dry-run] %s\n', cmd);
        else
            [status, cmdout] = system(cmd);
            if status ~= 0
                fprintf('FAILED: %s -> %s\n', oldName, newName);
                disp(cmdout(max(1, end-500):end));
            else
                fprintf('OK: %s -> %s\n', oldName, newName);
            end
        end
    end
end

if dryRun
    fprintf('\nThis was a DRY RUN -- no videos were processed. Set dryRun = false and re-run this section.\n');
end


%% run ffmpeg near-lossless standardization (duration/fps checked, quality preserved)
% Same renumbered/anonymized filenames as above, same duration/fps
% enforcement (30fps, padded/trimmed to 2s, silent), but WITHOUT the
% aggressive bitrate cap -- uses a very low CRF instead, which keeps
% quality close to the original source at the cost of larger files.
dryRunHQ = false;  % keep true to just print the commands first; set false to actually run ffmpeg
 
for i = 1:numel(categories)
    cat = categories{i};
    outDir = fullfile(outputFolderHQ, cat);
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
 
    catRows = renameTable(strcmp(renameTable.category, cat), :);
    for k = 1:size(catRows, 1)
        oldName = catRows.old_name{k};
        newName = catRows.new_name{k};
        src = fullfile(sourceFolder, cat, oldName);
        dst = fullfile(outDir, newName);
 
        cmd = sprintf(['"%s" -y -i "%s" -vf "fps=30,tpad=stop_mode=clone:stop_duration=0.5" ' ...
                       '-t 2 -c:v libx264 -preset slow -crf 15 -pix_fmt yuv420p ' ...
                       '-an -movflags +faststart "%s"'], ...
                       ffmpegPath, src, dst);
 
        if dryRunHQ
            fprintf('[dry-run] %s\n', cmd);
        else
            [status, cmdout] = system(cmd);
            if status ~= 0
                fprintf('FAILED: %s -> %s\n', oldName, newName);
                disp(cmdout(max(1, end-500):end));
            else
                fprintf('OK: %s -> %s\n', oldName, newName);
            end
        end
    end
end
 
if dryRunHQ
    fprintf('\nThis was a DRY RUN -- no videos were processed. Set dryRunHQ = false and re-run this section.\n');
end
 