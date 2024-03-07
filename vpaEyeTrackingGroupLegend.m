classdef vpaEyeTrackingGroupLegend < teViewpane
    
    properties 
        EyeTrackingData vpaEyeTrackingData
        ForeColour = [255, 255, 255, 255]
        BackColour = [000, 000, 000, 200]        
        BorderWidth = 3
    end
    
    properties (Dependent, SetAccess = private)
        Valid 
    end
    
    properties (Access = private)
        lsDataChanged
    end
    
    methods
        
        function obj = vpaEyeTrackingGroupLegend
        end
        
        function Draw(obj)
            if obj.Valid, obj.UpdateDrawing; end
%             obj.UpdateValid
        end
        
        function UpdateDrawing(obj)
            if ~obj.Valid, return, end
            
            Screen('TextSize', obj.Ptr, 24);
            Screen('TextStyle', obj.Ptr, 1);
            
            % get number of groups
            num = obj.EyeTrackingData.NumGroups;
            if num == 0, return, end
            % get group info
            u = obj.EyeTrackingData.prGroup_u;
            s = obj.EyeTrackingData.prGroup_s;
            g = obj.EyeTrackingData.prGroup;
            
            % legend height
            bounds = Screen('TextBounds', obj.ParentPtr, 'TEST');
            txHeight = bounds(4) - bounds(2);
            txDiv = 5;
            totHeight = num * ((txDiv * 2) + txHeight);
            % legend width
            if isnumeric(u)
                u = arrayfun(@num2str, u, 'UniformOutput', false);
            end
            groupWidths = cellfun(@length, u);
            widestGroup = u{find(max(groupWidths), 1)};
            bounds = Screen('TextBounds', obj.ParentPtr, widestGroup);
            txWidth = bounds(3) - bounds(1);
            lineHorizWidth = 15;
            totWidth = txWidth + lineHorizWidth + (txDiv * 4);
            % legend rect
%             rect = [obj.Width - totWidth, 0, obj.Width, totHeight];
            rect = [0, 40, totWidth, totHeight + 40];
            % draw background 
            Screen('FillRect', obj.Ptr, obj.BackColour, rect);
            % draw outline 
            Screen('FrameRect', obj.Ptr, obj.ForeColour, rect,...
                obj.BorderWidth);  
            
            % colours and labels
            cols = obj.EyeTrackingData.prGroupColours_u;
            lineHeight = (txDiv * 2) + txHeight;
            startY = txDiv + (txHeight / 2) + 40;
            for i = 1:num
                
                % lines
                lx1 = txDiv;
                lx2 = txDiv + lineHorizWidth;
                ly = startY + (lineHeight * (i - 1));
                Screen('DrawLine', obj.Ptr, cols(i, :), lx1, ly, lx2, ly,...
                    obj.BorderWidth)
                
                % labels
                tx = lx2 + txDiv;
                ty = ly - (txHeight / 4);
                Screen('DrawText', obj.Ptr, u{i}, tx, ty, obj.ForeColour);
                
            end
            
            
%             cols(2:2:end) = (obj.EyeTrackingData.prGroupColours_u)';
%             lx1 = repmat(txDiv, num, 1);
%             lx2 = repmat(txDiv + lineHorizWidth, num, 1);
%             firstLine = txDiv + (txHeight / 2);
%             ly = (firstLine:lineHeight:firstLine + (lineHeight * (num - 1)))';
%             r1 = repmat(lx1', 1, 2);
%             r1(2:2:end) = ly';
%             r2 = repmat(lx2', 1, 2);
%             r2(2:2:end) = ly';
%             coords = [r1; r2];
            
%             lx_ptb = repmat(lx1', 1, 2);
%             lx_ptb(2:2:end) = lx2;
%             ly_ptb = repmat(ly', 1, 2);
%             ly_ptb(2:2:end) = ly;
%             rect = [lx_ptb; ly_ptb];
%             Screen('DrawLines', obj.Ptr, coords, obj.BorderWidth, cols);
        end
        
%         function UpdateValid(obj)
%             oval = obj.Valid;
%             obj.Valid = ~isempty(obj.EyeTrackingData) &&...
%                 obj.EyeTrackingData.Valid &&...
%                 ~isempty(obj.Ptr) &&...
%                 ~isempty(obj.ParentPtr);
%             if obj.Valid && ~oval
%                 obj.UpdateDrawing
%             end
%         end
        
        % get / set
        function val = get.Valid(obj)
%             oval = obj.Valid;
            val = ~isempty(obj.EyeTrackingData) &&...
                obj.EyeTrackingData.Valid &&...
                ~isempty(obj.Ptr) &&...
                ~isempty(obj.ParentPtr);
%             if obj.Valid && ~oval
%                 obj.UpdateDrawing
%             end
        end        
        
        function set.EyeTrackingData(obj, val)
            obj.EyeTrackingData = val;
            obj.lsDataChanged = addlistener(obj.EyeTrackingData,...
                'DataChanged', @obj.UpdateDrawing);
            obj.UpdateValid
            obj.UpdateDrawing
        end
        
    end
    
end
    