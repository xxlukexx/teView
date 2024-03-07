classdef teUIEvents < handle
    
    properties
        UpdatesPerSecond = 60
        MouseX = nan
        MouseY = nan
        MouseLastX = nan
        MouseLastY = nan
        MouseXChange = nan
        MouseYChange = nan
        MouseDownX = nan
        MouseDownY = nan
        MouseXDownChange = nan
        MouseYDownChange = nan
        MouseButtons = [0, 0, 0]
        MouseLastButtons = [0, 0, 0]
        MouseIsDown = false
        MouseIsUp = true
        MouseIsDragging = false
        MouseOnScreen = false
    end
    
    properties (Access = private)
        prTimer
        prParentPtr
    end
    
    events
        MouseMove
        MouseDown
        MouseUp
        MouseDrag
    end
    
    methods
        
        function obj = teUIEvents
            % init timer
            obj.prTimer = timer(...
                'Period', round(1000 / 60) / 1000,...
                'ExecutionMode', 'fixedDelay',...
                'TimerFcn', @obj.Timer,...
                'ErrorFcn', @obj.Timer_ERR);
        end
        
        function delete(obj)
            stop(obj.prTimer)
        end
        
        function StartTimer(obj, ptr)
            % check input
            if nargin ~= 2
                error('Must pass a Psychtoolbox window handle.')
            end            
            % store ptr
            obj.prParentPtr = ptr;
            % start timer
            start(obj.prTimer)
        end
        
        function StopTimer(obj)
            stop(obj.prTimer)
        end
        
        % event listeners
        function Timer(obj, ~, ~)

            obj.HandleMouse
            obj.HandleKeyboard
            
        end
        
        function HandleMouse(obj)
            
            % get current mouse state
            try
                [mx, my, mButtons] = GetMouse(obj.prParentPtr);
            catch ERR
                disp(ERR.message)
            end
            % is mouse over window?
            winRect = Screen('Rect', obj.prParentPtr);
            mouseOverWindow =  mx > 0 && my > 0 && mx < winRect(3) &&...
                my < winRect(4);
            % get old mouse state 
            omx = obj.MouseLastX;
            omy = obj.MouseLastY;
            omButtons = obj.MouseLastButtons;
            % detect changes
            mouseHasMoved = mx ~= omx || my ~= omy;
            mouseDown = ~omButtons(1) && mButtons(1);
            mouseUp = omButtons(1) && ~mButtons(1);
            % fire events
            if mouseOverWindow && mouseHasMoved
                % mouse has moved
                obj.MouseLastX = obj.MouseX;
                obj.MouseLastY = obj.MouseY;
                obj.MouseXChange = mx - obj.MouseX;
                obj.MouseYChange = my - obj.MouseY;
                notify(obj, 'MouseMove')
            end
            if mouseOverWindow && mouseDown
                % mouse down over window
                obj.MouseDownX = mx;
                obj.MouseDownY = my;
                obj.MouseIsDown = true;
                obj.MouseIsUp = false;
                notify(obj, 'MouseDown')
            end
            if mouseOverWindow && mouseDown && mouseHasMoved
                % mouse drag over window
                obj.MouseXDownChange = mx - obj.MouseDownX;
                obj.MouseYDownChange = my - obj.MouseDownY;
                obj.MouseIsDragging = true;
                notify(obj, 'MouseDrag')
            end
            if mouseUp
                % mouse up
                obj.MouseIsDown = false;
                obj.MouseIsUp = true;
                obj.MouseIsDragging = false;
                notify(obj, 'MouseUp')
            end
            % store previous state
            obj.MouseLastButtons = obj.MouseButtons;
            % store state
            obj.MouseX = mx;
            obj.MouseY = my;
            obj.MouseButtons = mButtons;   
            obj.MouseOnScreen = mouseOverWindow;
            
        end

        function Timer_ERR(~, ~, ~)
            cprintf('_green', 'Timer error\n')
        end
        
    end
    
end