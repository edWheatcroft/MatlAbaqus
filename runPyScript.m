function [success, msg] = runPyScript(pathToScript, caeKernel, opts)
    %% function to run an Abaqus python script from MATLAB
    arguments
        pathToScript char                   % The path to the script you are running from opts.runFrom. If opts.runFrom is not specified, pathToScript is the path to the script from wherever you called the present function.
        caeKernel (1,1) logical = true      % set true if script requires cae modules. false otherwise. true is safe if you are unsure.
        opts.silent = false                 % true to suppress all command line output
        opts.runFrom = []                   % specify a path here to run the script from a particular directory
        opts.userArgs struct = []           % Struct specifying any arguments you wish to pass to your script using sys.argv (see below helper)
        opts.numAttempts int64 = 2          % Number of times the function tried to execute the script.
        opts.successFun = @nativeSuccessFun % handle to a function which will be used to determine whether or not the run was successful.
    end

    % build the basic command
    if caeKernel
        cmdString = 'abaqus cae noGUI=';
    else
        cmdString = 'abaqus python ';
    end

    % construct the additional argument string
    userArgString = convertUserArgs(opts.userArgs);

    % construct the final command string
    cmdString = [cmdString, pathToScript, userArgString];
    if caeKernel && opts.silent
        % cmdString = [cmdString, ' > NUL 2>&1'];
        cmdString = [cmdString, ' 1>NUL 2>NUL'];
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
        success = opts.successFun(failed, pathToScript);
        counter = counter + 1;
    end

    % warn the user if it failed
    if ~success
        warning(['Abaqus python script ', pathToScript, ' failed to run after ', num2str(counter), 'attempts'])
    end

    % change back to home
    if ~isempty(opts.runFrom)
        cd(currDir)
    end

end

function userArgString = convertUserArgs(userArgs)
    %% helper to convert the userArgs argument into the right format to send to an Abaqus python script
    % Output arguments will be in the same order as the fields of userArgs, which is the order in which they were
    % created
    arguments
        userArgs struct % struct specifying the user arguments. Struct fields must be strings or convertable using string().
                        % Fieldnames are not used by this function.
    end
    
    userArgString = [];
    
    % loop over the fields of userArgs...
    fNames = fieldnames(userArgs);
    for name = fNames'
        % ...and correctly format the argument
        newArg = ['"', char(string(userArgs.(name{1}))),'"'];
        userArgString = [userArgString, ' ', newArg];
    end
    
    if ~isempty(userArgString)
        userArgString = [' --',userArgString];
    end

end

function success = nativeSuccessFun(systemOut, ~)
    %% default function to determine whether or not the call to abaqus command was successful.
    % second argument is intentionally un-used. The idea is that the user's own success function might need to utilise
    % pathToScript

    success = ~systemOut;
end