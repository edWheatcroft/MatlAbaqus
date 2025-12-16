function [output, success, msg] = queryODB(odbName, odbDir, queries, opts)
%% function to query an ODB file. The steps, sets and data to query are set by queries
arguments
    odbName char
    odbDir char
    queries cell
    opts.checkExisting = true
    opts.silent = false
end
% add trailing.odb if not there
if ~endsWith(odbName, '.odb')
    odbName = [odbName, '.odb'];
end
[~, jobName, ~] = fileparts(odbName);

%%%% HARD CODED STUFF %%%%
inName = [jobName, mtlbAqs.odbQuery.pyInpSuffix];
outName = [jobName, mtlbAqs.odbQuery.pyOutSuffix];
% logFileName = 'queryODBLogs';
%%%%%%%%%%% END %%%%%%%%%%

% useful paths
odbPath = fullfile(odbDir, odbName);
inPath = fullfile(odbDir, inName);
outPath = fullfile(odbDir, outName);
% logPath = fullfile(odbDir, logFileName);

%% write the input for python to read
% check the odb exists
if ~exist(odbPath,"file")
    error(['No ODB file found at: ', newline, odbPath])
end

inpData.queries = queries;
inpData.odbPath = odbPath;
inpData.outPath = outPath;
inpData.outDataFieldName = mtlbAqs.odbQuery.outDataFieldName;

% save the input
if exist(inPath, 'file')
    delete(inPath)
end
save(inPath, '-STRUCT', "inpData")

%% run the pyScript to query the odb
% the python command is mega simple, so we can just hard code it here
pyCommand = strcat('-c "from py2 import queryODB; ', ...
            " queryODB(", "r'", inPath, "')", '"');
userSuccessFun = @(~, msg, ~) isempty(msg);     % we should see nothing at the command line if the script is successful, otherwise we'll get the error

% if there's a file already then ask the user if we should create a new one
if exist(outPath,'file')
    if opts.checkExisting
        prompt = [newline, 'A matlab file already exists for this output database.', newline, '%', newline ...
                'Press Y to overwrite the existing file,', newline ,...
                'Press any other key to use the existing file.', newline];
        usr = input(prompt,'s');
        if ~strcmpi(usr,'y')
            runFlag = false;    % don't run if the user did anything other than press 'y'
        else
            runFlag = true;     % run if they did press 'y', and delete the old file for safety.
            delete(outPath)
        end
    else
        % if you weren't told to check for old files but one exists, then delete it and run.
        runFlag = true;
        delete(outPath)
    end
else
    runFlag = true;
end

if runFlag
    % feed the command as the path argument, works just fine 
    timer = tic;
    [success, msg] = mtlbAqs.runPyScript(pyCommand, false, runFrom=odbDir, silent=opts.silent, successFun=userSuccessFun);
    delete(inPath)
    disp(['Time taken to query ODB: ', num2str(toc(timer), 2), 's'])
else
    success = true;
    msg = '';
end

%% read what python wrote for us
outData = load(outPath);

output = outData;




