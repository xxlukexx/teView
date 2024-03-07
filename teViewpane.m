classdef (Abstract) teViewpane < handle
    
    properties 
        Type = 'layer'
        Ptr 
        Alpha = 1
        ZPosition = 50
    end
    
    properties (SetAccess = ?teViewport)
        Parent teViewport
        ParentPtr
        Size 
    end
       
    properties (Dependent, SetAccess = ?teViewport)
        UIEvents
    end
    
    properties (Dependent, SetAccess = private)
        Width
        Height
        AspectRatio
    end
    
    properties (Access = private)
        lsMouseDown
        lsMouseDrag
        prUIEvents
    end
    
    properties (Abstract, Dependent, SetAccess = private)
        Valid
    end
    
    events
        HasDrawn
    end
    
    methods
        
        function obj = teViewpane%(zPosition)
            
%             if exist('zPosition', 'var') && ~isempty(zPosition) 
%                 if ~isnumeric(zPosition) || ~isscalar(zPosition) ||...
%                         zPosition < 1
%                     error('If setting a zPosition, it must be a positive numeric scalar.')
%                 else                
%                     obj.ZPosition = zPosition;
%                 end
%             else
%                 obj.ZPosition = 50;
%             end
            
        end
        
        function Clear(obj)
            Screen('BlendFunction', obj.Ptr, GL_ONE, GL_ZERO);
            Screen('FillRect', obj.Ptr, [0, 0, 0, 0])
            Screen('BlendFunction', obj.Ptr, GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);
        end
        
        function set.Ptr(obj, val)
            if ~isnumeric(val) || ~isscalar(val) || val < 0
                error('texPtr must be a positive numeric scalar.')
            end            
            obj.Ptr = val;
        end
        
        function set.Size(obj, val)
            if ~isnumeric(val) || ~isvector(val) || length(val) ~= 2 ||...
                    any(val < 0)
                error('size must be a positive numeric vector [w, h].')
            end
            obj.Size = val;
        end
        
        function val = get.Width(obj)
            val = obj.Size(1);
        end
        
        function val = get.Height(obj)
            val = obj.Size(2);
        end
        
        function set.UIEvents(obj, val)
            obj.prUIEvents = val;
            % init mouse listeners
            obj.lsMouseDown = addlistener(obj.UIEvents, 'MouseDown',...
                @obj.HandleMouseDown);    
            obj.lsMouseDrag = addlistener(obj.UIEvents, 'MouseDrag',...
                @obj.HandleMouseDrag);  
            addlistener(obj.prUIEvents, 'MouseMove', @obj.HandleMouseMove);        
            addlistener(obj.prUIEvents, 'MouseDown', @obj.HandleMouseDown);    
            addlistener(obj.prUIEvents, 'MouseUp', @obj.HandleMouseUp);  
            addlistener(obj.prUIEvents, 'MouseDrag', @obj.HandleMouseDrag);             
        end
        
        function val = get.UIEvents(obj)
            val = obj.prUIEvents;
        end
        
        function set.Type(obj, val)
            val = lower(val);
            if ~ismember(val, {'layer', 'ui'})
                error('Type must be ''layer'' or ''ui''')
            end
            obj.Type = val;
        end
        
        function set.Alpha(obj, val)
            obj.Alpha = val;
            notify(obj, 'HasDrawn');
        end
        
        % intention is that these methods will be overriden by any
        % subclasses
        function HandleMouseDown(obj, ~, ~)
        end
        
        function HandleMouseDrag(obj, ~, ~)
        end
        
        function HandleMouseUp(obj, ~, ~)
        end
        
        function HandleMouseMove(obj, ~, ~)
        end
        
        function UpdateValid(~)
        end
        
        function Update(~)
        end
        
    end
           
end

