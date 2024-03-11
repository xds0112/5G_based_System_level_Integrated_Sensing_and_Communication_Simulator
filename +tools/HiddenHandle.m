classdef HiddenHandle < handle
    %HiddenHandle is basically a handle class with all its methods hidden
    %  this solution is based on an answer at
    %  https://de.mathworks.com/matlabcentral/answers/47751-looking-for-a-way-to-mask-handle-functions-when-calling-methods-or-doc
    % seems like it is impossible to hide the "isvalid" method tough

    properties
    end

    methods
        % Make a copy of a handle object.
        function new = copy(obj)
            % Instantiate new object of the same class.
            new = feval(class(obj));

            %class(obj)
            privateSetProperties = tools.findAttrValue(obj,'SetAccess','protected');
            usePrivateCopy = ~isempty(privateSetProperties);

            % Copy all non-hidden properties.
            allProperties = properties(obj);
            if usePrivateCopy
                p = setdiff(allProperties, privateSetProperties);
            else
                p = allProperties;
            end

            for i = 1:length(p)
                %if is
                if isobject(obj.(p{i})) %&& ~isenum(obj.(p{i}))
                    tmp = metaclass(obj.(p{i}));
                    if ~tmp.Enumeration
                        if ~isempty(obj.(p{i})) % add check if this is array here
                            if length(obj.(p{i})) > 1
                                tmpOld = obj.(p{i});
                                for jj = 1:length(tmpOld)
                                    tmpObj(jj) = tmpOld(jj).copy();
                                end
                                new.(p{i}) = tmpObj;
                                clear tmpObj;
                            else
                                new.(p{i}) = obj.(p{i}).copy();
                            end
                        end
                    else
                        new.(p{i}) = obj.(p{i});
                    end
                else
                    new.(p{i}) = obj.(p{i});
                end
            end

            if usePrivateCopy
                new.copyPrivate(obj);
            end
        end
    end

    methods (Hidden)
        function addlistener(varargin)
            addlistener@handle(varargin{:})
        end

        function r = eq(varargin)
            r = eq@handle(varargin{:});
        end

        function findobj(varargin)
            findobj@handle(varargin{:})
        end

        function findprop(varargin)
            findprop@handle(varargin{:})
        end

        function ge(varargin)
            ge@handle(varargin{:})
        end

        function gt(varargin)
            gt@handle(varargin{:})
        end

        function le(varargin)
            le@handle(varargin{:})
        end

        function lt(varargin)
            lt@handle(varargin{:})
        end

        function r = ne(varargin)
            r = ne@handle(varargin{:});
        end

        function notify(varargin)
            notify@handle(varargin{:})
        end
    end
end

