function varargout = printstruct(S, varargin)
    % PRINTSTRUCT Recursively print hierarchical outline of structure contents
    %
    %  This is a minor adaptation of the File Exchange contribution "Structure
    %  outline" written by B. Roossien <roossien@ecn.nl> and available here:
    %  http://mathworks.com/matlabcentral/fileexchange/13500-structure-outline
    % __________________________________________________________________________
    %  USAGE: pS = printstruct(S, varargin)
    %
    %    IN:   S = structure variable to print
    %  OUT*:  pS = cell array containing printed structure
    %
    %   *If defined, result will NOT display in command window
    % __________________________________________________________________________
    %  OPTIONAL VARARGIN* [entered as 'name', value pairs]:
    %   *Run printstruct w/no arguments to see default values
    %
    %   NLEVELS:        N levels to print. If negative, all levels printed.
    %   NINDENT:        number of tab indents for each line of printed struct
    %   STRUCTNAME:     top level name (if empty, variable name will be used)
    %   PRINTCONTENTS:  flag to print field values/contents as well
    %   SORTFIELDS:     flag to sort fields within each  dtype (by level)
    %   MAXARRAYLENGTH: for fields containing arrays, sets max number of values to
    %   print. Values of a 2D (m,n) array are printed if the number of
    %   elements (mxn) is less than or equal to maxarraylength. This is ignored
    %   if printcontents is set to 0.
    % _______________________________
    % EXAMPLES
    %
    %   pS = printstruct(S, 'maxarray', 100);
    %   printstruct(S, 'nlevels', 2, 'printcontents', 0, 'nindent', 3)
    %

    % ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
    %	Created:  2015-08-13
    %	Email:    spunt@caltech.edu
    % __________________________________________________________________________
    def = { ...
    	'nlevels',              -1,             ...
    	'printcontents',		 1,             ...
        'nindent',               0,             ...
        'structname',           '',             ...
        'sortfields',           1,              ...
        'maxarraylength',       75              ...
    	};
    vals = setargs(def, varargin);
    if nargin==0, mfile_showhelp; fprintf('\t| - VARARGIN DEFAULTS - |\n'); disp(vals); return; end
    if iscell(S)
        if all(cellfun(@isstruct, S))
            fprintf(' - detected cell array of structs. printing iteratively...\n\n');
        end
    else
        S = {S};
    end
    if nlevels==0, nlevels = -1; end;
    if isempty(structname), structname = inputname(1); end
    pS = [];
    for i = 1:length(S)
        cS = S{i};
        if sortfields, cS = orderfields(cS); end
        if length(cS)==1
            str = recFieldPrint(cS, nindent, nlevels, printcontents, maxarraylength, structname, sortfields);
            str = [cellstr(structname); str];
        else
            str = [];
            for i = 1:length(cS)
                tmpstr = recFieldPrint(cS(i), nindent, nlevels, printcontents, maxarraylength, structname, sortfields);
                str = [str; cellstr(sprintf('%s(%d)', structname, i)); tmpstr];
                if i<length(cS), str = [str; {' '}]; end
            end
        end
        
        if nargout==0
            for i = 1:length(str), disp(cell2mat(str(i, 1))); end
        else
            varargout{1} = [pS; str];
        end
    end
    end
% ==========================================================================
% SUBFUNCTIONS ------------------------------------------------------------=
% ==========================================================================
function mfile_showhelp(varargin)
    % MFILE_SHOWHELP
    ST = dbstack('-completenames');
    if isempty(ST), fprintf('\nYou must call this within a function\n\n'); return; end
    eval(sprintf('help %s', ST(2).file));
    end
function argstruct = setargs(defaults, optargs)
    % SETARGS Name/value parsing and assignment of varargin with default values
    %
    % This is a utility for setting the value of optional arguments to a
    % function. The first argument is required and should be a cell array of
    % "name, default value" pairs for all optional arguments. The second
    % argument is optional and should be a cell array of "name, custom value"
    % pairs for at least one of the optional arguments.
    %
    %  USAGE: argstruct = setargs(defaults, args)
    % __________________________________________________________________________
    %  OUTPUT
    %
    % 	argstruct: structure containing the final argument values
    % __________________________________________________________________________
    %  INPUTS
    %
    % 	defaults:
    %       cell array of "name, default value" pairs for all optional arguments
    %
    % 	optargs [optional]
    %       cell array of "name, custom value" pairs for at least one of the
    %       optional arguments. this will typically be the "varargin" array.
    % __________________________________________________________________________
    %  USAGE EXAMPLE (WITHIN FUNCTION)
    %
    %     defaults    = {'arg1', 0, 'arg2', 'words', 'arg3', rand};
    %     argstruct   = setargs(defaults, varargin)
    %
    if nargin < 1, mfile_showhelp; return; end
    if nargin < 2, optargs = []; end
    defaults = reshape(defaults, 2, length(defaults)/2)';
    if ~isempty(optargs)
        if mod(length(optargs), 2)
            error('Optional inputs must be entered as Name, Value pairs, e.g., myfunction(''name'', value)');
        end
        arg = reshape(optargs, 2, length(optargs)/2)';
        for i = 1:size(arg,1)
           idx = strncmpi(defaults(:,1), arg{i,1}, length(arg{i,1}));
           if sum(idx) > 1
               error(['Input "%s" matches multiple valid inputs:' repmat('  %s', 1, sum(idx))], arg{i,1}, defaults{idx, 1});
           elseif ~any(idx)
               error('Input "%s" does not match a valid input.', arg{i,1});
           else
               defaults{idx,2} = arg{i,2};
           end
        end
    end
    for i = 1:size(defaults,1), assignin('caller', defaults{i,1}, defaults{i,2}); end
    if nargout>0, argstruct = cell2struct(defaults(:,2), defaults(:,1)); end
    end
% ==========================================================================
% ADAPTED FROM FROM STRUCDISP - fileexchange/13831-structure-display -------
% ==========================================================================
function listStr  = recFieldPrint(Structure, indent, depth, printValues, maxArrayLength, structname, sortfields)
    % RECFIELDPRINT Recursive printing of a structure variable
    %   This function and its dependencies were taken from:
    %       STRUCDISP.m by
    %       Contact author: B. Roossien <roossien@ecn.nl>
    %       (c) ECN 2007-2008
    %       Version 1.3.0
    %

    if sortfields, Structure = orderfields(Structure); end

    listStr = {};
    if length(Structure) > 1
        if (printValues == 0)
            varStr = createArraySize(Structure, structname);
            listStr = [{' '}; {[structname, varStr]}];
            body = recFieldPrint(Structure(1), indent, depth, ...
                                 printValues, maxArrayLength, '', sortfields);
            listStr = [listStr; body];
        else
            for iStruc = 1 : length(Structure)
                listStr = [listStr; {' '}; {sprintf('%s(%d)', structname, iStruc)}];
                body = recFieldPrint(Structure(iStruc), indent, depth, ...
                                     printValues, maxArrayLength, '', sortfields);
                listStr = [listStr; body];
            end
        end
        return
    end

    fields      = fieldnames(Structure);
    isStruct    = structfun(@isstruct, Structure);
    strucFields = fields(isStruct == 1);
    strIndent   = getIndentation(indent + 1);
    listStr     = [listStr; {strIndent}];
    strIndent   = getIndentation(indent);
    for iField = 1 : length(strucFields)

        fieldName = cell2mat(strucFields(iField));
        Field =  Structure.(fieldName);

        % Empty structure
        if isempty(Field)
            strSize = createArraySize(Field, 'Structure');
            line = sprintf('%s   |--- %s :%s', ...
                           strIndent, fieldName, strSize);
            listStr = [listStr; {line}];
        % Scalar structure
        elseif isscalar(Field)
            line = sprintf('%s   |--- %s', strIndent, fieldName);
            % Recall this function if the tree depth is not reached yet
            if (depth < 0) || (indent + 1 < depth)
                lines = recFieldPrint(Field, indent + 1, depth, ...
                                      printValues, maxArrayLength, '', sortfields);
                listStr = [listStr; {line}; lines];
            else
                listStr = [listStr; {line}];
            end
        % Short vector structure of which the values should be printed
        elseif (isvector(Field)) &&  ...
               (printValues > 0) && ...
               (length(Field) < maxArrayLength) && ...
               ((depth < 0) || (indent + 1 < depth))
            % Use a for-loop to print all structures in the array
            for iFieldElement = 1 : length(Field)
                line = sprintf('%s   |--- %s(%g)', ...
                               strIndent, fieldName, iFieldElement);
                lines = recFieldPrint(Field(iFieldElement), indent + 1, ...
                                     depth, printValues, maxArrayLength, '', sortfields);
                listStr = [listStr; {line}; lines];
                if iFieldElement ~= length(Field)
                    listStr = [listStr; {[strIndent '   |    ']}];
                end
            end
        % Structure is a matrix or long vector
        % No values have to be printed or depth limit is reached
        else
            varStr = createArraySize(Field, 'Structure');
            line = sprintf('%s   |--- %s :%s', ...
                           strIndent, fieldName, varStr);
            lines = recFieldPrint(Field(1), indent + 1, depth, ...
                                  0, maxArrayLength, '', sortfields);
            listStr = [listStr; {line}; lines];
        end
        % Some extra blank lines to increase readability
        listStr = [listStr; {[strIndent '   |    ']}];

    end % End iField for-loop
    %% Field Filler
    % To properly align the field names, a filler is required. To know how long
    % the filler must be, the length of the longest fieldname must be found.
    % Because 'fields' is a cell array, the function 'cellfun' can be used to
    % extract the lengths of all fields.
    maxFieldLength = max(cellfun(@length, fields));
    %% Print non-structure fields without values
    % Print non-structure fields without the values. This can be done very
    % quick.
    if printValues == 0
        noStrucFields = fields(isStruct == 0);
        for iField  = 1 : length(noStrucFields)
            Field   = cell2mat(noStrucFields(iField));
            filler  = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
            listStr = [listStr; {[strIndent '   |' filler ' ' Field]}];
        end
        return
    end
    %% Select non-structure fields (to print with values)
    % Select fields that are not a structure and group them by data type. The
    % following groups are distinguished:
    %   - characters and strings
    %   - numeric arrays
    %   - logical
    %   - empty arrays
    %   - matrices
    %   - numeric scalars
    %   - cell arrays
    %   - other data types
    % Character or string (array of characters)
    isChar        = structfun(@ischar, Structure);
    charFields    = fields(isChar == 1);
    % Function
    isFunction     = structfun(@(x) isa(x,'function_handle'), Structure);
    functionFields = fields(isFunction == 1);
    % Numeric fields
    isNumeric     = structfun(@isnumeric, Structure);
    % Numeric scalars
    isScalar      = structfun(@isscalar, Structure);
    isScalar      = isScalar .* isNumeric;
    scalarFields  = fields(isScalar == 1);
    % Numeric vectors (arrays)
    isVector      = structfun(@isvector, Structure);
    isVector      = isVector .* isNumeric .* not(isScalar);
    vectorFields  = fields(isVector == 1);
    % Logical fields
    isLogical     = structfun(@islogical, Structure);
    logicalFields = fields(isLogical == 1);
    % Empty arrays
    isEmpty       = structfun(@isempty, Structure) & ~isChar;
    emptyFields   = fields(isEmpty == 1);
    % Numeric matrix with dimension size 2 or higher
    isMatrix      = structfun(@(x) ndims(x) >= 2, Structure);
    isMatrix      = isMatrix .* isNumeric .* not(isVector) .* not(isScalar) .* not(isEmpty);
    matrixFields  = fields(isMatrix == 1);
    % Cell array
    isCell        = structfun(@iscell, Structure);
    cellFields    = fields(isCell == 1);
    % Datatypes that are not checked for
    isOther       = not(isChar + isFunction + isNumeric + isCell + isStruct + isLogical + isEmpty);
    otherFields   = fields(isOther == 1);
    %% Print non-structure fields
    % Print all the selected non structure fields
    % - Strings are printed to a certain amount of characters
    % - Vectors are printed as long as they are shorter than maxArrayLength
    % - Matrices are printed if they have less elements than maxArrayLength
    % - The values of cells are not printed
    % Start with printing strings and characters. To avoid the display screen
    % becoming a mess, the part of the string that is printed is limited to 31
    % characters. In the future this might become an optional parameter in this
    % function, but for now, it is placed in the code itself.
    % if the string is longer than 31 characters, only the first 31  characters
    % are printed, plus three dots to denote that the string is longer than
    % printed.
    maxStrLength = 31;
    for iField = 1 : length(charFields)
        Field   = cell2mat(charFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        if (size(Structure.(Field), 1) > 1) && (size(Structure.(Field), 2) > 1)
            varStr = createArraySize(Structure.(Field), 'char');
        elseif length(Structure.(Field)) > maxStrLength
            Val   = Structure.(Field);
            varStr = sprintf(' ''%s ...''', Val(1:maxStrLength));
        else
            varStr = sprintf(' ''%s''', Structure.(Field));
        end
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' :' varStr]}];
    end
    for iField = 1 : length(functionFields)
        Field   = cell2mat(functionFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        Val    = func2str(Structure.(Field));
        if Val(1) ~= '@'
            % Because func2str only shows @ for anonymous functions:
            %  func2str(@sum) -> 'sum'
            % but
            %  func2str(@(x) x+x) -> '@x'
            % This prefixes all function handle strings with '@' and is
            % consistent with how MATLAB displays them in structure both
            % prefixed with @, i.e.,
            % S = struct('a',@x,'b',@(y) y*y)
            Val = ['@',Val];
        end
        if length(Val) > maxStrLength
            varStr = sprintf(' %s...', Val(1:maxStrLength));
        else
            varStr = sprintf(' %s', Val);
        end
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' :' varStr]}];
    end    
    % Print empty fields
    for iField = 1 : length(emptyFields)
        Field = cell2mat(emptyFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' : [ ]' ]}];
    end
    % Print logicals. If it is a scalar, print true/false, else print vector
    % information
    for iField = 1 : length(logicalFields)
        Field = cell2mat(logicalFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        if isscalar(Structure.(Field))
            logicalValue = {'False', 'True'};
            varStr = sprintf(' %s', logicalValue{Structure.(Field) + 1});
        else
            varStr = createArraySize(Structure.(Field), 'Logic array');
        end
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' :' varStr]}];
    end
    % Print numeric scalar field. The %g format is used, so that integers,
    % floats and exponential numbers are printed in their own format.
    for iField = 1 : length(scalarFields)
        Field = cell2mat(scalarFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        varStr = sprintf(' %g', Structure.(Field));
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' :' varStr]}];
    end
    % Print numeric array. If the length of the array is smaller then
    % maxArrayLength, then the values are printed. Else, print the length of
    % the array.
    for iField = 1 : length(vectorFields)
        Field = cell2mat(vectorFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        if length(Structure.(Field)) > maxArrayLength
            varStr = createArraySize(Structure.(Field), 'Array');
        else
            varStr = sprintf('%g ', Structure.(Field));
            varStr = ['[' varStr(1:length(varStr) - 1) ']'];
        end
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' : ' varStr]}];
    end
    % Print numeric matrices. If the matrix is two-dimensional and has more
    % than maxArrayLength elements, only its size is printed.
    % If the matrix is 'small', the elements are printed in a matrix structure.
    % The top and the bottom of the matrix is indicated by a horizontal line of
    % dashes. The elements are also lined out by using a fixed format
    % (%#10.2e). Because the name of the matrix is only printed on the first
    % line, the space is occupied by this name must be filled up on the other
    % lines. This is done by defining a 'filler2'.
    % This method was developed by S. Wegerich.
    for iField = 1 : length(matrixFields)
        Field = cell2mat(matrixFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        if numel(Structure.(Field)) > maxArrayLength
            varStr = createArraySize(Structure.(Field), 'Array');
            varCell = {[strIndent '   |' filler ' ' Field ' :' varStr]};
        else
            matrixSize = size(Structure.(Field));
            filler2 = char(ones(1, maxFieldLength + 6) * 32);
            dashes = char(ones(1, 12 * matrixSize(2) + 1) * 45);
            varCell = {[strIndent '   |' filler2 dashes]};

            % first line with field name
            varStr = sprintf('%#10.2e |', Structure.(Field)(1, :));
            varCell = [varCell; {[strIndent '   |' filler ' ' ...
                                  Field ' : |' varStr]}];
            % second and higher number rows
            for j = 2 : matrixSize(1)
                varStr = sprintf('%#10.2e |', Structure.(Field)(j, :));
                varCell = [varCell; {[strIndent '   |' filler2 '|' varStr]}];
            end
            varCell = [varCell; {[strIndent '   |' filler2 dashes]}];

        end

        listStr = [listStr; varCell];
    end
    % Print cell array information, i.e. the size of the cell array. The
    % content of the cell array is not printed.
    for iField = 1 : length(cellFields)
        Field = cell2mat(cellFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        varStr = createArraySize(Structure.(Field), 'Cell');
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' :' varStr]}];
    end
    % Print unknown datatypes. These include objects and user-defined classes
    for iField = 1 : length(otherFields)
        Field = cell2mat(otherFields(iField));
        filler = char(ones(1, maxFieldLength - length(Field) + 2) * 45);
        varStr = createArraySize(Structure.(Field), 'Unknown');
        listStr = [listStr; {[strIndent '   |' filler ' ' Field ' :' varStr]}];
    end
    end
function str    = getIndentation(indent)
        x = '   |    ';
        str = '';

        for i = 1 : indent
            str = cat(2, str, x);
        end
    end
function varStr = createArraySize(varName, type)
        varSize = size(varName);

        arraySizeStr = sprintf('%gx', varSize);
        arraySizeStr(length(arraySizeStr)) = [];

        varStr = [' [' arraySizeStr ' ' type ']'];
    end
