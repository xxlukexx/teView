classdef teViewpaneCollection < teCollection
    
%     properties (SetAccess = private)
%         EnforceClass = @teViewpane
%     end
    
    properties (Dependent, SetAccess = private)
        TexPtr
    end
    
    methods
        
        function val = get.TexPtr(obj)
            % if collection is empty, return empty
            if isempty(obj), val = []; end
            % check that all elements are teViewpanes (otherwise we're
            % about to query a property of a different class that may not
            % exist
            if ~all(cellfun(@(x) isa(x, 'teViewpane')))
                error('All elements must be teViewpanes.')
            end
            % query the TexPtr property of each element
            
        end
        
    end
    
end