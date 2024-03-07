classdef vpaGazeUnits < teViewpane
    
    properties
        Net 
%         Neurons
%         Synapses
        Gaze
    end
    
    properties (SetAccess = private)
        Valid = false
        MouseXGrid = nan
        MouseYGrid = nan
        SelectedNodeID = []
        SelectedNodeIdx = []
    end
    
    properties (Dependent, SetAccess = private)
        GridWidth
        GridHeight
        X
        Y
        NumHorizLines
        NumVertLines
    end
    
    properties (Constant)
        CONST_COL_GRID_OUTLINE              = [120, 210, 240]  
        CONST_COL_GRID_ACTIVATION           = [120, 210, 240]  
        CONST_COL_SYNAPSE                   = [255, 211, 146]
    end
    
    events
        % note that HasDrawn event is defined in teViewpane superclass
        DataChanged
    end
    
    methods
        
        function obj = vpaGazeUnits(gaze, net)
            
            obj.Gaze = gaze;
            obj.Net = net;
            obj.Valid = true;
            
            % tell any subscribers that the data for this pane has changed
            notify(obj, 'DataChanged')
            
        end
        
        function Draw(obj)
            
            if ~obj.Valid
                notify(obj, 'HasDrawn')
                return
            end
            
            obj.Clear
            
            obj.DrawGridActivation
            if ~isempty(obj.SelectedNodeID) 
                obj.DrawOneNeuronSynapses(obj.SelectedNodeID)
            end
            obj.DrawGridOutline
            obj.DrawGridSelection
            
            % drawing code here if valid
            notify(obj, 'HasDrawn')
            
        end
        
        function DrawGridOutline(obj)      
            
            % format into pairs of consecutive [x; y] columns for PTB
            coords = zeros(2, (obj.NumHorizLines + obj.NumVertLines) * 2);
            
            % horiz lines
            cnt = 1;
            for i = 1:obj.NumHorizLines
                coords(:, cnt) = [obj.X(i); 1];
                cnt = cnt + 1;
                coords(:, cnt) = [obj.X(i), obj.Height];
                cnt = cnt + 1;
            end
            
            % vert lines
            for i = 1:obj.NumVertLines
                coords(:, cnt) = [1, obj.Y(i)];
                cnt = cnt + 1;
                coords(:, cnt) = [obj.Width, obj.Y(i)];
                cnt = cnt + 1;
            end            
            
            % draw
            col = obj.CONST_COL_GRID_OUTLINE;
            lineWidth = 3;
            Screen('DrawLines', obj.Ptr, coords, lineWidth, col);

        end
        
        function DrawGridActivation(obj)
            
            numCells = obj.GridWidth * obj.GridHeight;
            coords = zeros(4, numCells);
            coords_sel = nan;
            cols = zeros(4, numCells);
            cnt = 1;
            gx = obj.X;
            gy = obj.Y;
            for x = 1:obj.Net.XGrid(end)
                for y = 1:obj.Net.YGrid(end)
                    
                    % get top left and bottom right coords of grid square
                    x1 = gx(x);
                    y1 = gy(y);
                    x2 = gx(x + 1);
                    y2 = gy(y + 1);
                    
                    % format for PTB
                    coords(:, cnt) = [x1; y1; x2; y2];
                    
                    % scale colour of grid square by its activation
                    cols(:, cnt) =...
                        [obj.CONST_COL_GRID_ACTIVATION';...
                        round(255 * obj.Net.Nodes.activation(cnt))];
                    
                    % if this node selected?
                    if obj.SelectedNodeID == cnt
                        coords_sel = [x1, y1, x2, y2];
                    end
                    
                    cnt = cnt + 1;
                end
            end
            
            % draw activations
            Screen('FillRect', obj.Ptr, cols, coords);
            
            % draw selection
            if ~isnan(coords_sel)
                Screen('FrameRect', obj.Ptr, obj.CONST_COL_SYNAPSE,...
                    coords_sel, 5);            
            end

        end
        
        function DrawGridSelection(obj)
             
            if isnan(obj.MouseXGrid) || isnan(obj.MouseYGrid) ||...
                    isempty(obj.SelectedNodeID)
                return
            end
            
            str = sprintf('[%d, %d] %.2f', obj.MouseXGrid, obj.MouseYGrid,...
                obj.Net.Nodes.activation(obj.SelectedNodeIdx));
            [x, y] = obj.GridCoords2Pixels(obj.MouseXGrid, obj.MouseYGrid);
            
            Screen('DrawText', obj.Ptr, str, x + 2,...
                y + 2, obj.CONST_COL_GRID_ACTIVATION,...
                [0, 0, 0]);
                        
        end
        
        function DrawAllSynapses(obj)
        end
        
        function DrawOneNeuronSynapses(obj, nidx)
            
            if isempty(nidx)
                return
            end
            
            % find synapses connected to selected node
            idx_s = obj.Net.FindConnectedSynapses(nidx);
            if ~any(idx_s)
                return
            end
            
%             idx_s = find(obj.Net.Synapses(:, 1) == nidx |...
%                 obj.Net.Synapses(:, 2) == nidx);
            syn = obj.Net.Synapses(idx_s, :);
            
            [xg1, yg1] = obj.Net.Key2Coords(syn.node1);
            [xg2, yg2] = obj.Net.Key2Coords(syn.node2);
            
            xg1 = xg1 + .5;
            xg2 = xg2 + .5;
            yg1 = yg1 + .5;
            yg2 = yg2 + .5;
            
%             % find nodes connected to these synapses
%             neu1 = obj.Net.Nodes(syn(:, 1), :);
%             neu2 = obj.Net.Nodes(syn(:, 2), :);
%             
%             % get grid coords
%             xg1 = neu1(:, 1);
%             yg1 = neu1(:, 2);
%             xg2 = neu2(:, 1);
%             yg2 = neu2(:, 2);
            
            % get pixel coords
            [xp1, yp1] = obj.GridCoords2Pixels(xg1, yg1);
            [xp2, yp2] = obj.GridCoords2Pixels(xg2, yg2);
            
%             % get cell width and height in pixels
%             width_grid_px = obj.Width / obj.GridWidth;
%             height_grid_px = obj.Height / obj.GridHeight;
%             xp1 = xp1 + (width_grid_px / 2);
%             yp1 = yp1 + (height_grid_px / 2);
%             xp2 = xp2 - (width_grid_px / 2);
%             yp2 = yp2 - (height_grid_px / 2);
            
            % format for PTB lines
            cnt = 1;
            coords = zeros(2, length(xp1) * 2);
            widths = zeros(1, length(xp1));
            cols = [...
                repmat(obj.CONST_COL_SYNAPSE, length(xp1) * 2, 1),...
                zeros(length(xp1) * 2, 1)]';
            for i = 1:length(xp1)
                coords(:, cnt) = [xp1(i); yp1(i)];
                cols(4, cnt) = round(255 * syn.weight(i));
                cnt = cnt + 1;
                coords(:, cnt) = [xp2(i); yp2(i)];
                cols(4, cnt) = round(255 * syn.weight(i));
                cnt = cnt + 1;
                 
                widths(i) = 1 + round(10 * syn.weight(i));
            end
            
            Screen('Drawlines', obj.Ptr, coords, widths, cols);
            
        end
        
        function HandleMouseMove(obj, src, ~)
            
            % ignore offscreen mouse coords
            if src.MouseX < 0 || src.MouseY < 0 ||...
                    src.MouseX > obj.Width || src.MouseY > obj.Height
                return
            end
           
            % find the grid cell that the mouse is over
            [obj.MouseXGrid, obj.MouseYGrid] =...
                obj.Pixels2GridCoords(src.MouseX, src.MouseY);
            obj.SelectedNodeID =...
                obj.Net.Coords2Key(obj.MouseXGrid, obj.MouseYGrid);
            obj.SelectedNodeIdx = obj.Net.NodeID2NodeIdx(obj.SelectedNodeID);

            obj.Draw
            
        end        
        
        % utlities
        function [px, py] = GridCoords2Pixels(obj, gx, gy)
            px = ((gx - 1) / obj.GridWidth) * obj.Width;
            py = ((gy - 1) / obj.GridHeight) * obj.Height;
        end
        
        function [gx, gy] = Pixels2GridCoords(obj, px, py)
            gx = ceil((px / obj.Width) * obj.GridWidth);            
            gy = ceil((py / obj.Height) * obj.GridHeight);
        end

        % get/set
        
        function val = get.GridWidth(obj)
            val = max(obj.Net.XGrid);
        end
        
        function val = get.GridHeight(obj)
            val = max(obj.Net.YGrid);
        end
        
        function val = get.X(obj)
            val = (obj.Net.XGrid ./ obj.GridWidth) .* obj.Width;
            val = [1; val];
        end
        
        function val = get.Y(obj)
            val = (obj.Net.YGrid ./ obj.GridHeight) .* obj.Height;
            val = [1; val];
        end
        
        function val = get.NumHorizLines(obj)
            val = length(obj.X);
        end
        
        function val = get.NumVertLines(obj)
            val = length(obj.Y);
        end
        
    end
    
end
    
    