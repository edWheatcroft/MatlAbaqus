classdef odbQuery < handle
%% Class to define a query to an abaqus output database
    properties
        name char       % Name of this query
        step char       % Name of the step being queried
        instance char   % Instance being queried. Set as [] if query is at assembly level
        set char        % Node or element set being queried. Can set this to 'globalHistory' to query things like ALLSE and LPF
        variable char   % The name of the abaqus variable being queried, e.g. S for stress, or U for displacement
        compVariant     % The component or invariant being queried. Must be numeric if a component is being queried, must be text name of invariant otherwise.
                        % Note that abaqus python uses camel case for invariant names, e.g. 'mises' or 'minInPlanePrincipal'.

        % output properties
        time
        data
        nodeIDs
        faceIDs
        sectionPoints
        positions
        integrationPoints
        elIDs
        % bit of a bodge - a cell of all the data fields we're going to read from python. This helps us read them all in
        % localUpdateFromStruct
        readNames = {'time', 'data', 'nodeIDs', 'faceIDs', 'sectionPoints', 'positions', 'integrationPoints', 'elIDs'}

    end
    properties (Dependent)
        dataName
    end

    properties (Hidden, Constant)
        % arbitrary names you never need to touch
        pyInpSuffix = '_pyInput.mat'
        pyOutSuffix = '_pyOutput.mat'
        outDataFieldName = 'outputData'
    end

    methods
        function obj = odbQuery(stepName, setName, instName, varName, compVariant, opts)
            %% constructor.
            % The idea here is that you can easily specify an array of this class by calling the constructor many times inside a [].
            % This should provide a quick and readable way to define ODB queries.
            arguments
                stepName char
                setName char
                instName char
                varName char
                compVariant 
                opts.name = []
            end

            % populate the class properties
            obj.step = stepName;
            obj.set = upper(setName);
            obj.instance = upper(instName);
            obj.variable = upper(varName);
            % deal with compVariant maybe being a component or an invariant
            if isa(compVariant, 'char') || isa(compVariant, 'string')
                obj.compVariant = compVariant;
            elseif isnumeric(compVariant) 
                obj.compVariant = compVariant;
            else
                error('CompVariant must be either char, string or numeric')
            end

            % make a helpful name if the user didn't give us one
            if isempty(opts.name)
                obj.name = [stepName, '_' ,setName, '_', obj.dataName];
            else
                obj.name = opts.name;
            end
            if ~isvarname(obj.name)
                if isempty(opts.name)
                    error(['The default name constructed by this class is not a valid fieldname.', newline, ...
                           'Please specify a valid name using the "name" keyword argument to the class constructor'])
                else
                    error('User specified name is not a valid fieldname')
                end
            end

        end

        function [outputStruct, success, msg] = getData(obj, odbName, odbDir, opts)
            %% function to actually execute the data queries defined by an array of this class
            % ouput struct is just obj, but formatted into a struct whose fields correspond to the name properties of obj
            arguments
                obj (1,:)
                odbName char
                odbDir char
                opts.checkExisting = true
                opts.silent = false
            end

            % make the input to the query function (maybe this should be inside the query function, but I coded it this way
            % to begin with...
            numQueries = length(obj);
            queryCell = cell(numQueries, 5);
            for i = 1:numQueries
                queryCell{i,1} = obj(i).step;
                queryCell{i,2} = obj(i).set;
                queryCell{i,3} = obj(i).instance;
                queryCell{i,4} = obj(i).variable;
                queryCell{i,5} = obj(i).compVariant;
            end

            % make the query
            [pyOutput, success, msg] = mtlbAqs.odbQuery.queryODB(odbName, odbDir, queryCell, checkExisting=opts.checkExisting, silent=opts.silent);

            % assign output
            dat = pyOutput.(mtlbAqs.odbQuery.outDataFieldName);
            outputStruct = struct();
            for i = 1:numQueries
                obj(i).localUpdateFromStruct(dat{i});
                outputStruct.(obj(i).name) = obj(i);
            end



        end

        function localUpdateFromStruct(obj, inpStruct)
            %% a helper to populate the properties we read from abaqus from the struct python provides us
            arguments
                obj (1,1)
                inpStruct
            end

            for fName = obj.readNames
                if isfield(inpStruct, fName{1})
                    obj.(fName{1}) = inpStruct.(fName{1});
                end
            end

        end

        function val = get.dataName(obj)
            if isnumeric(obj.compVariant)
                val = [obj.variable, int2str(obj.compVariant)];
            else
                val = [obj.variable, obj.compVariant];
            end
        end

    end
    
    methods (Static)
        [output, success, msg] = queryODB(obj, odbName, odbDir, queries, opts)
    end

end