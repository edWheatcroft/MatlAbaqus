function [stepSummary, EVsummary, stabSummary] = readMSG(fileName, filePath, printFlag)
% A function to read the abaqus *.MSG file 'fileName', in the location
% specified by 'filePath'. The function extracts the
% number of negative eigenvalues in each increment of the analysis.
% 
% Note that, in Abaqus parlance, each analysis 'step' is made up of many
% 'increments'. These incements are what you see in the output. Each
% increment may require several 'iterations' for equilibrium to converge
% within tolerance. If Abaqus detects that the solution is diverging then it
% will abort the analysis, reduce the arc length, and begin a new 'attempt'.
% In this script, stability is determined based on whether any negative EV
% warnings appear in any iteration of the final attempt at an increment (the
% final attempt being the one which converges succesfully). Note that only 
% CONVERGED increments are counted and analysed.
% 
% Written by Ed Wheatcroft, University of Bristol, ed.wheatcroft@bristol.ac.uk
% Cite as: 
% Wheatcroft, E.D. (2022). readMSG(). MATLAB function.
% 
% 
% Arguments:
% Name           Description                                                                 Example
% fileName       Name of the MSG file (WITHOUT the '.msg' extension)                         'my_Abaqus_Job'
% filePath       Directory where the MSG is stored                                           'C:\Users\user_name\Abaqus_Working_Directory'
% printflag      [optional] true if you want Matlab to print a summary to the command line   true
% 
% Outputs:
% Name           datatype        Description
% stepSummary    double array    Array is #steps x 2. Column 1 gives the number of increments, column 2 gives the number of warnings (as Abaqus counts them, so some issues get double counted)
% EVsummary      cell array      Cell is #steps x 1. Each row contains a double array which is #increments x 1, each entry of which gives the number of negative eigenvalues in that increment
% stabSummary    cell array      Cell is #steps x 1. As per EVsummary, except each array entry is 1 if there are zero negative EVs, and 2 otherwise.

arguments
    fileName string
    filePath string
    printFlag logical = false
end



%% import the data from the .MSG

programFolder = filePath;
jobName = [fileName, '.msg'];   %tell this script the name of your job, and by extension the .MSG file
MSGfilePath = fullfile(programFolder, jobName); %[programFolder,'/',jobName,'.msg'];


% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 1);

% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = "";
% Specify column names and types
opts.VariableNames = "VarName1";
opts.VariableTypes = "char"; % change to "string" to import as a string array
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "VarName1", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "VarName1", "EmptyFieldRule", "auto");
% Import the data
msg = readmatrix(MSGfilePath, opts);
% Clear temporary variables
clear opts


%% compute and print the number of STEPS in this job (as distinct from increments)       
rowsLog = contains(msg,'S T E P');          % logical array which is 1 if the row contains the string 'S T E P'
rows = find(rowsLog);                       % an array containing only the indicies of the rows containing.....
numSteps = size(rows,1); 
stepSummary = zeros(numSteps,2);            % initialise stepSummary
if printFlag
    disp(['%%%%%%%%%% Reading .MSG for job "', fileName, '" %%%%%%%%%%'])
    disp('%')
    disp(['The number of steps in this job is ', num2str(numSteps)])
    disp(['%';'%'])
end

%% print the number of increments & warnings in each step
fileEnd = find(contains(msg,'ANALYSIS SUMMARY'));     % index of the analysis summary at the end of the .MSG

% create a quick array containing the limts of each step within the .MSG
next = [rows(2:end); fileEnd + 1];          
stepDelim = [rows, next - 1];
% some arrays/cell arrays to store some useful info
warnLog = zeros(numSteps,1);
incLog = cell(numSteps,2);
incTotLog = zeros(numSteps,1);
% loop over the steps and print the incements/warnings
for i = 1:numSteps
    if printFlag
        disp(['STEP ', num2str(i)])
    end
    stepText = msg(stepDelim(i,1):stepDelim(i,2));                      % isolate the text pertaining to this step from msg
    incs = find(contains(stepText,'STARTS.'));                          % we're looking for the bit where the file reads 'increment xxx starts'
    incStart = incs; 
    incEnd = find([false(6,1);contains(stepText,'ITERATION SUMMARY')]); % add 6 rows to the bit where we find the ITERATION (NOT increment) summary so we get all the text related to the step. Note that Abaqus appears to rigorously only produce the summary once per increment regardless of the number of attempts, so incEnd is a reliable way of counting the number of increments. This also excludes the final increment if it causes the analysis to exit with errors.
    realStart = zeros(size(incEnd,1),1);                                % initialise an array to store the 'real' indicies at the start of each increment (i.e. only the ones at the start of the final attempt for that increment)
    offset = 0; 
    for j = 1:size(incEnd,1)                                            % loop over all the increments
        incText = stepText(incStart(j+offset):incEnd(j));                   % pull the text for that increment (ignore the offset for now..)
        att = find(contains(incText,'ATTEMPT'));                            % pull the 'attempts'
        if size(att,1) > 1                                                  % if we needed more than one attempt for this increment...
            realStart(j) = att(end) - 1 + incStart(j+offset);                   % ...then the real starting index of the increment should be the start of the final attempt. we need the -1 to avoid counting the start of the increment twice. The +incStart(... puts us back into the 'reference frame' of the step rather than just the increment
            offset = offset + size(att,1) - 1;                                  % increase the offset so next time we index into incStart we skip over the un-converged attempts
            if printFlag
                disp(['Increment ', num2str(j), ' required ', num2str(size(att,1)), ' attempts'])
            end
        else                                                                % if not...
            realStart(j) = incStart(j+offset);                                  % ...then incStart was already correct, adjusted for any multi-attempt increments we already found.
        end
    end
    if offset ~= 0 && ~printFlag
        warning(['Some increments in step ',num2str(i),' of job "',fileName ,'" required multiple attempts to achieve convergence. Run with printFlag = true for a summary of which ones.'])
    end
    incStart = realStart;                           % overwrite incStart
    incLog{i,1} = incStart;                         % store the row index of each increment start within each step in incLog
    incLog{i,2} = incEnd;                           % and again for the ends....
    numIncs = size(incStart,1);                      
    incTotLog(i) = numIncs;                         % write the nmumber of increments to a separate array for convenience

    % make some checks to see if the final increment converged and warn the user if it didn't
    finalAttemptLine = regexp(stepText(incs(end)),'\S*','Match');           % get the last line in the step where 'STARTS.' was printed and split it into words. This will give us the last attempt started, which may or may not have converged
    numIncsStarted = str2double(finalAttemptLine{1}{2});                       % extract the actual increment number as a number
    numIncsFinished = size(incEnd,1);
    if numIncsStarted == numIncsFinished + 1
        warning(['It is likely that the final increment (increment ',num2str(numIncsStarted),') of step ', num2str(i), ' in job ', fileName, ' did not converge. Therefore the final increment output in the corresponding .dat may be untrustworthy.'])
    elseif size(incStart,1) ~= size(incEnd,1)
        error(['Something has gone wrong in readMSG(): readMSG thinks that ', num2str(size(incStart,1)), ' increments began, but ', num2str(size(incEnd,1)), ' finished in step ', num2str(i), ' of job ', fileName])
    end

    warn = find(contains(stepText,'warning','IgnoreCase',true));       % extract the rows with warnings, I THINK Abaqus warns you about each thing once per attempt, so there might be multiple negative EV warnings per increment                 
    numWarn = size(warn,1);
    warnLog(i) = numWarn;
    stepSummary(i,1) = numIncs;
    stepSummary(i,2) = numWarn;
    if printFlag
        disp(['Total Converged Increments: ', num2str(numIncs)])
        disp(['Total Warnings: ', num2str(numWarn)])
        disp('%')
    end
end

%% use negative eigenvalue warnings to determine stability
if printFlag
    disp('%')
    disp('Negative Eigenvalue Summary:')
    disp('Note that if a given increment required multiple ATTEMPTS (distinct from ITERATIONS) then only warnings which appear in the final attempt are considered') %Most increments will require multiple 'iterations', however if Abaqus decides the solution is diverging then it starts a completely new 'attempt', presumably with a smaller arc length increment 
    disp('%')
end
EVsummary = cell(numSteps,1);
stabSummary = cell(numSteps,1);
for i = 1:numSteps                                         % loop over the steps...
    if warnLog(i)                                                       % ...if there were any warnings of any kind within the step...
        stepText = msg(stepDelim(i,1):stepDelim(i,2));                  % extract the step text
        % set up some delimiters so we can extract each increment's text
        incDelim = [incLog{i,1}, incLog{i,2}];
        countNegEV = zeros(size(incDelim,1),1);
        for j = 1:size(incDelim,1)                                  % loop over very increment within this step..
            incText = stepText(incDelim(j,1):incDelim(j,2));            % extract the text pertaining to every increment
            EVwarn = contains(incText,'WARNING: THE SYSTEM MATRIX HAS');  % look for the warning
            warnRow = find(EVwarn);                                                         % convert to row index
            if any(EVwarn)                      % if we found the warning anywhere... 
                numNeg = regexp(incText(warnRow(end)),'\d*','Match');        % look for anything in the warning string which is a number, and use the final warning in the increment if there is more than one..
                countNegEV(j) = str2double(numNeg{1});                              % write that number to the count
            end
        end

        % we now have a vector, countNegEV which tells us how many negative
        % EVs there are at every increment.
        % we can now use this to print some useful stuff
        EVsummary{i} = countNegEV;
        stabSummary{i} = double(logical(countNegEV)) + 1;
        

        % code to detect a change in the number of negative EVs
        if size(incDelim,1) > 0             % from future Ed: I added this check to prevent crashes when there are zero converged increments in a step
            shiftedCopy = [countNegEV(1); countNegEV(1:end-1)];             % a copoy of NegEV with evything shifted forward by one index, and a copy of entry 1 at the start
            changeMask = logical(countNegEV - shiftedCopy);                 % a mask to detect where all the changes are
            changeDicies = find(changeMask);                                % convert to indicies
            loop = 0;                                                       % for loop counter
            changeDicies_ = [changeDicies; size(countNegEV,1) + 1];         % for the printing, create this _ version of changeDicies which is needed so we print the result correctly
            if printFlag
                disp(['Step ', num2str(i),':'])
                for k = 1:size(changeDicies_,1)                                 % Print the result
                    if loop == 0
                        disp(['From increment 1 to increment ', num2str(changeDicies_(k)-1), ' there are ', num2str(countNegEV(changeDicies_(k)-1)), ' negative eigenvalues'])
                    else
                        disp(['From increment ', num2str(changeDicies_(k-1)),' to increment ', num2str(changeDicies_(k)-1), ' there are ', num2str(countNegEV(changeDicies_(k-1))), ' negative eigenvalues'])
                    end
                    loop = loop + 1;
                end
                disp('%')
            end
        else
            if printFlag
                disp(['Step ', num2str(i),':'])
                disp('Step contains no converged increments');
                disp('%')
            end
        end
    else
        EVsummary{i} = zeros(incTotLog(i),1);
        stabSummary{i} = ones(incTotLog(i),1);
        if printFlag
            disp(['Step ', num2str(i),':'])
            disp(['From increment 1 to increment ', num2str(incTotLog(i)), ' there are 0 negative eigenvalues'])
            disp('%')
        end
    end
end

%% Check we have the correct number of increments & warnings and see if there are any warnings for things other than -ve EVs
summary = msg(fileEnd:end);                             % extract summary text
% extract number of increments according to summary
sumIncsText = contains(summary,'INCREMENTS');
sumIncs = regexp(summary(sumIncsText),'\d*','Match');
sumIncs = str2double(sumIncs{1});
% extract number of warnings according to summary
sumWarnText = contains(summary,'WARNING MESSAGES DURING ANALYSIS');
sumWarn = regexp(summary(sumWarnText),'\d*','Match');
sumWarn = str2double(sumWarn{1});
% check that the last increment converged
incsRead = sum(incTotLog);
if sumIncs ~= sumIncs && sumIncs ~= incsRead + 1
    disp('%')
    disp('ERROR:')
    disp(['Increments read by code = ', num2str(incsRead)])
    disp(['Increments in MSG summary = ', num2str(sumIncs)])
    error(['The number of increments read by readMSG does not equal the total in the MSG file summary on line ', num2str(fileEnd)])
end
% if the summary and what we calculated disagree, AND if the final increment DIDN'T fail (because the abaqus summary counts this as an increment but we don't) then break
if sumWarn ~= sum(warnLog)
    disp('%')
    disp('*****WARNING:******')
    disp(['Warnings read by this function = ', num2str(sum(warnLog))])
    disp(['Warnings in MSG summary = ', num2str(sumWarn)])
    warning(['The number of warnings read by readMSG does not equal the total printed in the MSG file summary on line ', num2str(fileEnd),'.',newline,'If this job is a restart analysis then this might not be a problem, because the ABAQUS is counting all the warnings in the original job which are not printed here.'])
end
% warn if there are warnings for stuff other than negative EVs
nonEVwarn = contains(summary,'ANALYSIS WARNINGS ARE NUMERICAL PROBLEM MESSAGES');
nonEVwarn = regexp(summary(nonEVwarn),'\d*','Match');
nonEVwarn = str2double(nonEVwarn{1});
if nonEVwarn ~= 0
    warning(['There are ', num2str(nonEVwarn) ,' warnings in the MSG file which are NOT for negative eigenvalues'])
end
if printFlag
    disp('%%%%%%%%%% .MSG read complete %%%%%%%%%%')

end
