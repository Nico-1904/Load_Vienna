% Get a list of toolboxes on which the current version of the 5G SL Simulator currently depends
%
% Generates dependencies.csv with a list of toolboxes and the files in
% which they are called.
%
%NOTE: parfor loops are not included in the generated list
%
% initial author: Armand Nabavi

% get a list of all m-files of the simulator
listing = dir('**/*.m');

% assemble the full paths of all files
p = cell(1, numel(listing));

for ii = 1:numel(listing) %for all files
    temp = [listing(ii).folder, '\', listing(ii).name];
    if ~contains(temp, 'tests') % exclude files in tests folder
        p{ii} = [listing(ii).folder, '\', listing(ii).name]; % concatenate folder path and file name
    end
end

p(cellfun('isempty', p)) = []; %delete empty entries

% use an internal function that is called in dependency reports
[data, ~] = internal.matlab.reports.parseDependencyInfo(p);

callData = struct();

for ii = 1:numel(data)
    callData.filename{ii} = data{ii}.fullname;
    callData.calledFcns{ii} = data{ii}.subs{1}.calls;
end

% iterate over calls and eliminate everything that is not of the type
% 'toolbox/*' (only write interesting data to new struct)

filteredCallData = struct();

counter1 = 1;
counter2 = 1;

for jj = 1:numel(callData.filename)
    contained_toolbox_call = false;
    counter2 = 1; % reset call counter
    for kk = 1:numel(callData.calledFcns{jj})
        if contains(callData.calledFcns{jj}(kk).type, 'toolbox') && ~contains(callData.calledFcns{jj}(kk).type, 'toolbox/matlab')
            contained_toolbox_call = true;
            % write data to new struct
            filteredCallData.filename{counter1} = callData.filename{jj};
            filteredCallData.calledFcns{counter1}{counter2} = callData.calledFcns{jj}(kk);
            counter2 = counter2+1;
        end
    end
    if contained_toolbox_call
        counter1 = counter1 + 1;
    end
end

tbxFiles = {}; % create empty cell array
% extract names of all toolbox files called
for ll = 1:numel(filteredCallData.filename)
    for mm = 1:numel(filteredCallData.calledFcns{ll})
        tbxFiles = [tbxFiles, filteredCallData.calledFcns{ll}{mm}.name];
    end
end

tbxFilesUnique = unique(tbxFiles);
tbxFilesUnique = tbxFilesUnique';

% now that the information has been extracted, it is rearranged in a more
% convenient way
% for each toolbox file, get a list of all occurences (file name and line)

nDependencies = numel(tbxFiles); % total number of toolbox file usage (>= number of toolbox files used)
results = {};

for ll = 1:numel(filteredCallData.filename)
    for mm = 1:numel(filteredCallData.calledFcns{ll})
        temp_name     = filteredCallData.calledFcns{ll}{mm}.name;
        temp_filename = filteredCallData.filename{ll};
        % shorten path info in file names used in results
        currentFolder = pwd;
        lastBackslashInd = max(strfind(currentFolder, '\')); % find index of last '\' to get only the folder name without the rest of the path
        temp_filename = strrep(temp_filename, currentFolder(1:lastBackslashInd-1), ''); % delete first part of the path
        temp_line     = filteredCallData.calledFcns{ll}{mm}.line;

        temp_struct = struct('function', temp_name, 'file', temp_filename, 'line', temp_line);
        results = [results, temp_struct];
    end
end

% write results to text file
fid = fopen('dependencies.csv', 'w');
fprintf(fid, 'function \t file \t line\n');
nResults = numel(results);
for ii = 1:nResults
    fprintf(fid, '%s \t %s \t %ld\n', results{ii}.function, results{ii}.file, results{ii}.line);
end
fclose(fid);

