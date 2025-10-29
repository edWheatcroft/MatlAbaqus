function [success, msg] = runAbJob(jobName, opts)
%% Function to submit a .inp file to the ABAQUS kernel 
    arguments
        jobName char = 'defaultJobName'             % The name of the job.
        opts.silent (1,1) logical = false           % Set true to suppress output
        opts.cmdLineArgs struct = struct.empty      % A struct specifying command line arguments to send to the Abaqus kernel (see helper funciton below)
        opts.runFrom char = []                      % If specified, the abaqus command is called from this directory
        opts.waitUntilDone (1,1) logical = true     % If specified, funciton won't return until the abaqus command does
        opts.numAttempts int64 = 2                  % The number of times to try submitting the command. Function returns after the first successful run.
        opts.successFun = @nativeSuccessFun         % handle to a function which will be used to determine whether or not the run was successful.
    end
    
    % set the ask_delete attribute to off if the user didn't specify and silent option is set (so the user isn't asked without their knowledge)
    if ~isfield(opts.cmdLineArgs, 'ask_delete') && opts.silent
        opts.cmdLineArgs.ask_delete = 'OFF';
    end
    
    % Make the command string
    cmdString = ['abaqus job=', jobName, convertCmdLnArgs(opts.cmdLineArgs)];
    % Add in the interactive option if we want to hear what's going on, or if we want to hang until the job is completed
    if ~opts.silent || opts.waitUntilDone
        cmdString = [cmdString, ' interactive'];
    end
    
    % change to opts.runFrom is specified..
    if ~isempty(opts.runFrom)
        currDir = pwd;
        cd(opts.runFrom)
    end
    
    % run
    counter = 0;
    success = false;
    while ~success && counter < opts.numAttempts 
        if ~opts.silent
            [failed, msg] = system(cmdString,'-echo');
        else
            [failed, msg] = system(cmdString);
        end
        success = opts.successFun(failed, jobName);
        counter = counter + 1;
    end

    % warn the user if it failed
    if ~success
        warning(['Abaqus job: ', jobName, ' failed to run after ', num2str(counter), 'attempts'])
    end
    
    % change back to home
    if ~isempty(opts.runFrom)
        cd(currDir)
    end
end



function cmdLineArgString = convertCmdLnArgs(argStruct)
    %% Helper to convert the cmdLineArgs argument into the right format to send to the Abaqus kernel
    arguments
        argStruct struct    % A struct specifying the command line arguments. The field names of the struct must be one of 
                            % the valid command line arguments to the abaqus command. The corresponding field value is the 
                            % argument itself, and must be convertible using string().
    end
    
    cmdLineArgString = [];
    
    % loop over the fields of argStruct...
    fNames = fieldnames(argStruct);
    for name = fNames'
        % ...and correctly format the argument
        newArg = [name{1},'=', char(string(argStruct.(name{1})))];
        cmdLineArgString = [cmdLineArgString, ' ', newArg];
    end

    % add the leading space for convenience...
    if ~isempty(cmdLineArgString)
        cmdLineArgString = [' ', cmdLineArgString];
    end
end

function success = nativeSuccessFun(~, jobName)
    %% function to check whether or not a call to the abaqus command was successful.
    % returns true if <jobName>.odb exists in the current directory.
    % first argument intentionally un-used.
    
    % get a list of all the files in the current directory (which is where the command is running)
    fileList = dir(pwd);
    fileNames = {fileList.name};
    odbName = [jobName, '.odb'];

    % check if any of them is an .odb file for this job
    success = any(strcmp(odbName, fileNames),"all");
    
end