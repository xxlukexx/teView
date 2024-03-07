classdef vpaTimeline < teViewpane
    
    properties
        Duration = nan
        GapFromEdge_W = 100
        GapFromEdge_H = 100
        DrawHeight = 30
        BorderWidth = 3
        ForeColour = [255, 255, 255, 255]
        BackColour = [000, 000, 000, 100]
    end
    
    properties (Dependent)
        Position
    end
    
    properties (Access = protected)
        prRect
    end
    
    properties (Access = private)
        prPosition = 0
        prClickBox
    end
    
    properties (Dependent, SetAccess = private)
        Valid
    end
    
    events
        PositionChanged
    end
    
    methods
        
        function Draw(obj)
            
            % don't try to draw if invalid
            if ~obj.Valid, return, end
            
            % clear texture
            obj.Clear
            
            obj.DrawBackground
            obj.DrawControls

            % fire event
            notify(obj, 'HasDrawn')
    
        end
        
        function DrawBackground(obj)
            
            % calculate timeline dimensions - from bottom of screen
            rect_screen = Screen('Rect', obj.ParentPtr);
            x1 = obj.GapFromEdge_W;
            x2 = rect_screen(3) - obj.GapFromEdge_W;
            y2 = rect_screen(4) - obj.GapFromEdge_H;
            y1 = y2 - obj.DrawHeight;
            obj.prRect = [x1, y1, x2, y2];
            % draw background of timeline
            Screen('FillRect', obj.Ptr, obj.BackColour, obj.prRect);
            % draw outline of timeline
            Screen('FrameRect', obj.Ptr, obj.ForeColour, obj.prRect,...
                obj.BorderWidth);  
            
            % update clickbox 
            obj.prClickBox = [0, obj.prRect(2) - 100, rect_screen(3),...
                obj.prRect(4) + 100];
            
        end
        
        function DrawControls(obj)
            
            % get coords of background
            x1 = obj.prRect(1);
            x2 = obj.prRect(3);
            y1 = obj.prRect(2);
            y2 = obj.prRect(4);
            
            rect_screen = Screen('Rect', obj.ParentPtr);
            
            % label start and end of timeline (sl = start label, el = end
            % label)
            sl_str = sprintf('%.2f', 0);
            el_str = sprintf('%.2f', obj.Duration);
            ly = y2 + 20;
            rect_startLabel = [...
                0,...
                ly,...
                obj.GapFromEdge_W * 2,...
                ly];
            rect_endLabel = [...
                x2 - obj.GapFromEdge_W,...
                ly,...
                x2 + obj.GapFromEdge_W,...
                ly];
            % set font, bold Menlo size 18
            Screen('TextFont', obj.Ptr, 'Arial');
            Screen('TextSize', obj.Ptr, 18);
            Screen('TextStyle', obj.Ptr, 1);
            % draw timeline labels
            Screen('DrawText', obj.Ptr, sl_str, rect_startLabel(3) / 2, rect_startLabel(2), obj.ForeColour);
            Screen('DrawText', obj.Ptr, el_str, rect_endLabel(3), rect_endLabel(2), obj.ForeColour);
%             DrawFormattedText(obj.Ptr, sl_str, 'center', 'center',...
%                 obj.ForeColour, [], [], [], [], [], rect_startLabel);
%             DrawFormattedText(obj.Ptr, el_str, 'center', 'center',...
%                 obj.ForeColour, [], [], [], [], [], rect_endLabel);  
            
            % draw cursor. This consists of a vertical bar on the timeline,
            % a horizontal bar intersecting it above the timeline (in a T
            % shape), and a label representing the current position above
            % this horizontal bar
            cursHeight = 7;
            cursWidth = 55;
            curs_y1 = y1 - cursHeight;
            curs_y2 = y2 + cursHeight;
            pos_prop = obj.prPosition / obj.Duration;
            curs_x = x1 + 1 + ((x2 - x1 - 1) * pos_prop);
            Screen('DrawLine', obj.Ptr, obj.ForeColour, curs_x, curs_y1,...
                curs_x, curs_y2)
            % bar
            curs_bar_x1 = curs_x - (cursWidth / 2);
            curs_bar_x2 = curs_x + (cursWidth / 2);
            Screen('DrawLine', obj.Ptr, obj.ForeColour, curs_bar_x1,...
                curs_y1, curs_bar_x2, curs_y1)
            % label bg
            rect_curs = round(...
                [curs_bar_x1 - 10, curs_y1 - 16, curs_bar_x2 + 10, curs_y1 + 6]);
            Screen('FillRect', obj.Ptr, obj.BackColour, rect_curs);
            % label
            pos_str = sprintf('%.2f', obj.prPosition);
            Screen('DrawText', obj.Ptr, pos_str, curs_x - (cursWidth / 2), curs_y1 - (cursHeight), obj.ForeColour);
%             DrawFormattedText(obj.Ptr, pos_str, 'center', curs_y1,...
%                 obj.ForeColour, [], [], [], [], [], rect_curs);   
            
        end
        
        % event handlers
        function HandleMouseMove(obj, src, ~)
            obj.updatePositionFromMouse(src)
        end
        
        function HandleMouseDown(obj, src, ~)
            obj.updatePositionFromMouse(src)
        end
        
        % get / set
        function val = get.Position(obj)
            if ~obj.Valid
                val = [];
            end
            val = obj.prPosition;
%             obj.Draw
        end
        
        function set.Position(obj, val)
            % check input
            if val < 0 || val > obj.Duration || ~isscalar(val) 
                error('Position must be a positive numeric scalar between 0 and %.2f',...
                    obj.Duration)
            end
            % check to see if position has changed
            hasChanged = val ~= obj.prPosition;
            if hasChanged
                % store
                obj.prPosition = val;
                % draw
                obj.Draw
                % fire events
                notify(obj, 'PositionChanged')
            end
        end 
        
        function val = get.Valid(obj)
            val = ~isnan(obj.Duration);
        end
        
    end
    
    methods (Access = private)
        
        function updatePositionFromMouse(obj, src)
            % is mouse over clickbox?
            if src.MouseIsDown &&...
                    src.MouseX >= obj.prClickBox(1) &&...
                    src.MouseY >= obj.prClickBox(2) &&...
                    src.MouseX <= obj.prClickBox(3) &&...
                    src.MouseY <= obj.prClickBox(4) 
                
                % calculate position on timeline according to mouse pos
                px = src.MouseX - obj.prRect(1);
                tlWidth = obj.prRect(3) - obj.prRect(1);
                if px < 0, px = 0; end
                if px > tlWidth, px = tlWidth; end
                pos_prop = px / tlWidth;
                
                % set position property
                obj.Position = pos_prop * obj.Duration;
            
            end
        end
        
    end
    
end