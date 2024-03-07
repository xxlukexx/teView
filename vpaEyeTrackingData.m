classdef vpaEyeTrackingData < teViewpane
    
    properties 
        DrawQuivers = true
        DrawDistance = true
        ColourByAOI = true
        DrawHeatmap = true
        DrawBinocular = false
        Colour = [50, 50, 50]
        HeatmapApplyColourmap = true
        HeatmapBinarise = true
        MarkerSize = 18;
    end
    
    properties (Dependent)
        Group
        ColourByGroup = false
        Timeline vpaTimeline
    end
    
    properties (SetAccess = ?vpaAOIMask)
        AOIColours
    end
    
    properties (SetAccess = private)
        Gaze
        ID
    end
    
    properties (Dependent, SetAccess = private)
        Valid
        CurrentTime
        CurrentSample
        CurrentX 
        CurrentY
        GazeValid
        NumGroups
    end
    
    properties (Access = ?vpaEyeTrackingGroupLegend)
        prTimeline
        prGazeValid = false;
        prGroup
        prGroup_u
        prGroup_i
        prGroup_s
        prGroupColours
        prGroupColours_u
        prColourByGroup = true
    end
    
    properties (Access = private)
        prNearestToMouse
    end
    
%     properties (Constant)
%         COL_GAZE = [50, 50, 50];
%     end
    
    events
        DataChanged
    end
    
    methods
                
        function Import(obj, gaze, id)
            
            if ~exist('gaze', 'var') || ~isa(gaze, 'etGazeData') ||...
                    isempty(gaze)
                error('Must pass a non-empty etGaze instance containing gaze data.')
            end
            
            % check for presence of ID variable. If not passed, then make
            % it a running number from 001. If present, check the size
            % matches that of the ET data
            if ~exist('id', 'var') || isempty(id)
                id = arrayfun(@num2str, 1:gaze.NumSubjects, 'uniform', false)';
            end

            % id has been passed, check it
            idFormat = iscellstr(id) || isnumeric(id);
            idShape = isvector(id) && size(id, 1) == gaze.NumSubjects;
            if ~idFormat || ~idShape
                error('''id'' must be a column vector in numeric or cellstr format.')
            end

            % store
            obj.Gaze = gaze;
            obj.ID = id;
            
            notify(obj, 'DataChanged')
            
        end
        
        function Draw(obj)
            
            if ~obj.Valid, return, end
            
            % clear texture
            obj.Clear
            
            if ~obj.Valid || all(isnan(obj.CurrentX)) ||...
                    all(isnan(obj.CurrentY))
                notify(obj, 'HasDrawn')
                return
            end
                    
        % setup time
        
            % get current time in seconds
            t = obj.Timeline.Position;
            % find nearest sample of gaze data
            s = obj.TimeToSample(t);
            % check that a valid sample number was returned
            if isnan(s)
                notify(obj, 'HasDrawn')
                return
            end
            
        % setup gaze

            % rescale gaze points to pixels. Do this for the average x
            % and y data across eyes, because regardless of what we
            % draw, we'll use these later.
            w = obj.Size(1);
            h = obj.Size(2);
            x = obj.Gaze.X(s, :) .* w;
            y = obj.Gaze.Y(s, :) .* h;        
            
        % draw heatmap
        
            if obj.DrawHeatmap
                
                % get a few samples of gaze data and average, to stop the
                % heatmap jumping around so much
                hm_smooth_samps = 6;
                hms1 = s - hm_smooth_samps;
                hms2 = s + hm_smooth_samps;
                if hms1 < 1, hms1 = 1; end
                if hms2 > obj.Gaze.NumSamples, hms2 = obj.Gaze.NumSamples; end
                
                xs = nanmean(obj.Gaze.X(hms1:hms2, :) .* w, 1);
                ys = nanmean(obj.Gaze.Y(hms1:hms2, :) .* h, 1);                
                
                if ~obj.ColourByGroup
                    
                    numHeatmaps = 1;
                    hmx{1} = xs;
                    hmy{1} = ys;
                    hm_colDef{1} = obj.Colour;
                    
                else
                    
                    numHeatmaps = length(obj.prGroup_u);
                    hmx = cell(numHeatmaps, 1);
                    hmy = cell(numHeatmaps, 1);
                    hm_colDef = cell(numHeatmaps, 1);
                    for i = 1:numHeatmaps
                        hmx{i} = xs(obj.prGroup_s == i);
                        hmy{i} = ys(obj.prGroup_s == i);
                        hm_colDef{i} = obj.prGroupColours_u(i, :);
                    end
                    
                end
                
                hm_tex = nan(numHeatmaps, 1);
                for i = 1:numHeatmaps
                    
                    % make heatmap
                    if obj.HeatmapApplyColourmap 
                        [hm_col, hm_alpha] = etHeatmap4(hmx{i}', hmy{i}',...
                            [w / 4, h / 4], [w / 4, h / 4], [w, h]);                    
                    else
                        [hm_col, hm_alpha] = etHeatmap4(hmx{i}', hmy{i}',...
                            [w / 4, h / 4], [w / 4, h / 4], [w, h], hm_colDef{i} ./ 255);                             
                    end
            
                    if obj.HeatmapBinarise
                        hm_alpha = imbinarize(hm_alpha, .1) .* 255;
                    end
                    
                    % combine heatmap alpha channel
                    hm = cat(3, hm_col, hm_alpha * 1.5); 
                    
                    % todo - bwboundaries when matlab is working again
                    
                    % make heatmap texture
                    hm_tex(i) = Screen('MakeTexture', obj.ParentPtr, hm);                    
                    
                end
                    
%                 % make heatmap
%                 [hm_col, hm_alpha] = etHeatmap4(x', y', [w / 5, h / 5],...
%                     [w / 4, h / 4], [w, h], obj.Colour ./ 255);
%                 
%                 % combine heatmap alpha channel
%                 hm = cat(3, hm_col, hm_alpha * 1.5);
%                 
%                 % make heatmap texture
%                 hm_tex = Screen('MakeTexture', obj.ParentPtr, hm);

            end            
            
        % draw gaze dots
                        
            if obj.DrawBinocular
                
                % draw the left and right eyes separately, in blue/green
                % respetively. 
        
                % rescale gaze points to pixels
                w = obj.Size(1);
                h = obj.Size(2);
                lx = obj.Gaze.LeftX(s, :) .* w;
                ly = obj.Gaze.LeftY(s, :) .* h;                
                rx = obj.Gaze.RightX(s, :) .* w;
                ry = obj.Gaze.RightY(s, :) .* h;                

                % put into PTB-shaped matrix, left eye first
                dots_left = [reshape(lx, 1, []); reshape(ly, 1, [])];
                dots_right = [reshape(rx, 1, []); reshape(ry, 1, [])];
                dots = [dots_left, dots_right];
            
                cols_left = repmat([000, 000, 255], length(lx), 1)';
                cols_right = repmat([000, 255, 000], length(lx), 1)';
                cols_dots = [cols_left, cols_right];
            
            else

                % put into PTB-shaped matrix
                dots = [reshape(x, 1, []); reshape(y, 1, [])];
                % if colouring by group, set colours accordingly
                if obj.ColourByGroup
                    cols_dots = obj.prGroupColours;
                elseif obj.ColourByAOI && ~isempty(obj.AOIColours)
                    cols_dots = shiftdim(obj.AOIColours(s, :, :), 1)';
                else
                    cols_dots = obj.Colour;
                end
                
            end
            
        % draw quivers
        
            if obj.DrawQuivers
                
                % find coords for each end of the quiver, by querying gaze
                % at two points in time
                t1 = obj.Timeline.Position;
                t2 = obj.Timeline.Position - .150;
                % convert to samples, correct bounds if necessary
                s1 = obj.TimeToSample(t1);
                s2 = obj.TimeToSample(t2);
                if s1 < 1, s1 = 1; end
                if s2 < 2, s2 = 2; end
                % get gaze, average eyes
                lx1 = obj.Gaze.LeftX(s1, :);
                ly1 = obj.Gaze.LeftY(s1, :);
                rx1 = obj.Gaze.RightX(s1, :);
                ry1 = obj.Gaze.RightY(s1, :);
                lx2 = obj.Gaze.LeftX(s2, :);
                ly2 = obj.Gaze.LeftY(s2, :);
                rx2 = obj.Gaze.RightX(s2, :);
                ry2 = obj.Gaze.RightY(s2, :);
                curs_x1 = nanmean(cat(3, lx1, rx1), 3) .* w;
                curs_y1 = nanmean(cat(3, ly1, ry1), 3) .* h;   
                curs_x2 = nanmean(cat(3, lx2, rx2), 3) .* w;
                curs_y2 = nanmean(cat(3, ly2, ry2), 3) .* h;   
                % remove missing
                missing = isnan(curs_x1) | isnan(curs_y1) | isnan(curs_x2) | isnan(curs_y2);
                curs_x1(missing) = [];
                curs_y1(missing) = [];
                curs_x2(missing) = [];
                curs_y2(missing) = [];  
                % slow looped drawing
                xCoords = reshape([curs_x1; curs_x2], 1, []);
                yCoords = reshape([curs_y1; curs_y2], 1, []);
                quiv_coords = [xCoords; yCoords];
                
%                 switch obj.ColourByGroup
%                     
%                     case false
                        
                        r2 = 255;
                        r1 = obj.Colour(1);
                        g1 = obj.Colour(2);
                        b1 = obj.Colour(3);
                        g2 = 255;
                        b2 = 255;
                        a1 = 255;
                        a2 = 0;
                        colVals = [r1, r2; g1, g2; b1, b2; a1, a2];
                        quiv_cols = repmat(colVals, 1, length(curs_x1));
                        
%                     case true
%                         
%                         r1 = obj.prGroupColours(1, ~missing);
%                         g1 = obj.prGroupColours(2, ~missing);
%                         b1 = obj.prGroupColours(3, ~missing);
%                         a1 = repmat(255, 1, length(r1));
%                         
%                         r2 = obj.prGroupColours(1, ~missing);
%                         g2 = obj.prGroupColours(2, ~missing);
%                         b2 = obj.prGroupColours(3, ~missing);
%                         a2 = zeros(1, length(r1));          
%                         quiv_cols = [r1, r2; g1, g2; b1, b2; a1, a2];
% %                         quiv_cols(:, missing) = [];
% 
%                 end
                        
                w1 = 4;
                w2 = 1;
                widthVals = [w1, w2];
                quiv_widths = repmat(widthVals, 1, length(curs_x1));
                
            end     
            
        % draw info on sample point nearest to mouse
        
            drawMouseInfo = obj.UIEvents.MouseOnScreen &&...
                ~isempty(obj.prNearestToMouse);
            if drawMouseInfo
                
                % draw connecting line from nearest gaze point to mouse
                % cursor
                idx_near = obj.prNearestToMouse;
                if ~isempty(obj.AOIColours)
                    col_cursor = shiftdim(...
                        obj.AOIColours(obj.CurrentSample, idx_near, :), 2)';
                else
                    col_cursor = [200, 200, 200];
                end
                curs_x1 = obj.CurrentX(idx_near) * w;
                curs_y1 = obj.CurrentY(idx_near) * h;
                curs_x2 = obj.UIEvents.MouseX;
                curs_y2 = obj.UIEvents.MouseY;
                curs_lab = obj.ID{idx_near};
                if isnumeric(curs_lab), curs_lab = num2str(curs_lab); end
                
                % draw connecting line from nearest gaze point to centroid
                % of each AOI
                
                
            end
            
        % draw to texture
        
            % heatmap(s)
            if obj.DrawHeatmap
                for i = 1:numHeatmaps
                    Screen('DrawTexture', obj.Ptr, hm_tex(i), [], [0, 0, w, h], [], [], .75);
                    Screen('Close', hm_tex(i));
                end
            end
            
            % quivers
            if obj.DrawQuivers && ~isempty(quiv_coords)
                Screen('DrawLines', obj.Ptr, quiv_coords, quiv_widths, quiv_cols);
            end      
            
            % gaze
            Screen('DrawDots', obj.Ptr, dots, obj.MarkerSize, [210, 210, 210], [], 3);
            Screen('DrawDots', obj.Ptr, dots, round(obj.MarkerSize * .80), cols_dots, [], 3);
            
            % mouse-over info
            if drawMouseInfo
                Screen('DrawLine', obj.Ptr, col_cursor, curs_x1, curs_y1, curs_x2, curs_y2, 3);
                Screen('DrawDots', obj.Ptr, [curs_x1; curs_y1], 35, col_cursor, [], 3);
                Screen('DrawText', obj.Ptr, curs_lab, curs_x2, curs_y2, [255, 255, 255], [000, 000, 000, 200]);
            end
            
            % sample number
            obj.DrawSampleNumber
            
            % fire event
            notify(obj, 'HasDrawn')
            
        end
        
        function DrawSampleNumber(obj)
            
            numZeros = length(num2str(obj.Gaze.NumSamples));
            cmd = sprintf('Sample: %%0%dd/%%0%dd', numZeros, numZeros);
            str = sprintf(cmd,...
                obj.TimeToSample(obj.Timeline.Position),...
                obj.Gaze.NumSamples);
            Screen('DrawText', obj.Ptr, str, 0, 0, [255, 255, 255], [100, 100, 100]);
            
        end
        
        function UpdateTime(obj, ~, ~)
            obj.Draw
        end
        
        function s = TimeToSample(obj, t)
            if ~obj.Valid, s = nan; return, end
            % find the first sample that is 
            s = find(obj.Gaze.Time >= t, 1, 'first');
        end
        
        function [s, gazeDetails] = BuildTemporalAOIScores(obj, aoi, dist)
            
            isAOI = isa(aoi, 'vpaAOI');
            isSal = isa(aoi, 'vpaSalienceMap');
            hasAOIDef = isprop(aoi, 'AOIDefinition');
            hasDistance = isprop(aoi, 'Distance') && ~isempty(aoi.Distance);
            
            if ~exist('aoi', 'var') || (~isAOI && ~isSal)
                error('Must pass a vpaAOI instance.')
            end
            
            if ~aoi.Valid
                error('AOI is not valid.')
            end
            
            if isempty(aoi.In)
                error('No scoring data in AOI. Score AOI first.')
            end
            
            if ~exist('dist', 'var') || isempty(dist)
                dist = [];
            end
            
            % create struct array to store temporal scores
            numAOIs = size(aoi.In, 3);
            s(numAOIs) = struct;
            
            % for each AOI, write temporal scores to the struct
            for a = 1:numAOIs
                if isAOI
                    if hasAOIDef
                        s(a).aoi_name = aoi.AOIDefinition{a, 1};
                    else
                        s(a).aoi_name = aoi.Name;
                    end
                else
                    s(a).aoi_name = 'salience';
                end
                s(a).in = aoi.In(:, :, a);
                if hasDistance
                    s(a).distance = aoi.Distance(:, :, a);
                end
            end
            
            % [x, y] coords, missing, and absent vectors are common to all
            % AOIs so we store them in a separate struct, gazeDetails
            gazeDetails = struct;
            gazeDetails.ids = obj.ID;
            gazeDetails.time = obj.Gaze.Time;
            gazeDetails.missing = obj.Gaze.Missing;
            gazeDetails.absent = obj.Gaze.Absent;
            gazeDetails.X = obj.Gaze.X;
            gazeDetails.Y = obj.Gaze.Y;
            
        end
        
        function HandleMouseMove(obj, src, ~)
            
            % convert mouse coords to normalised
            mx = src.MouseX / obj.Width;
            my = src.MouseY / obj.Height;
            
            % calculate euclidean distance from each sample to mouse pos
            xDis = mx - obj.CurrentX;
            yDis = my - obj.CurrentY;
            dis = sqrt((xDis .^ 2) + (yDis .^ 2));
            
            % find nearest gaze point
            obj.prNearestToMouse = find(dis == min(dis), 1);
            
            obj.Draw
            
        end
        
        % get / set
        function val = get.Valid(obj)
           val = ~isempty(obj.ParentPtr) &&...
               ~isempty(obj.Gaze) &&...
               ~isempty(obj.Timeline) &&...
               isa(obj.Timeline, 'vpaTimeline') &&...
               obj.Timeline.Valid;
        end
        
        function val = get.Timeline(obj)
            val = obj.prTimeline;
        end
        
        function set.Timeline(obj, val)
            % when a timeline is set, add a listener for the timeline's
            % PositionChanged event. This means that any time the position
            % of the timeline changes, we get update the current time of
            % this class, so that we can draw the appropriate gaze data
            addlistener(val, 'PositionChanged', @obj.UpdateTime);
            % set timeline duration to duration of ET data
            val.Duration = obj.Gaze.Duration;
            % store and set timeline valid flag
            obj.prTimeline = val;
        end 
        
        function val = get.CurrentTime(obj)
            if obj.Valid
                val = obj.Timeline.Position;
            end
        end
        
        function val = get.CurrentSample(obj)
            if obj.Valid
                val = obj.TimeToSample(obj.CurrentTime);
            else
                val = [];
            end
        end
        
        function val = get.CurrentX(obj)
            if obj.Valid
                s = obj.CurrentSample;
                val = obj.Gaze.X(s, :);
            else
                val = [];
            end
        end
        
        function val = get.CurrentY(obj)
            if obj.Valid
                s = obj.CurrentSample;
                val = obj.Gaze.Y(s, :);
            else
                val = [];
            end
        end
        
        function val = get.GazeValid(obj)
            val = ~obj.prMissing & ~obj.prNotPresent;
        end
        
        function set.Group(obj, val)
            if isempty(obj.Gaze)
                error('Import gaze data before setting Group.')
            end
            % group can be cell array or numeric vector
            if ~isvector(val) && (~isnumeric(val) || ~iscellstr(val))
                error('Group must be a numeric vector or cell array of string.')
            end
            % check length
            if length(val) ~= obj.Gaze.NumSubjects
                error('Length of Group (%d) must match NumSubjects (%d).',...
                    length(val), obj.Gaze.NumSubjects)
            end
            % check for NaNs
            if any(isnan(val))
                error('Group indices cannot contain NaN values.')
            end
            % make subscripts
            obj.prGroup = val;
            [obj.prGroup_u, obj.prGroup_i, obj.prGroup_s] = unique(val);
            % define colours
            numCol = length(obj.prGroup_u);
            % get enough colours for the number of groups
            obj.prGroupColours_u = round(hsv(numCol + 1) .* 255);
            obj.prGroupColours_u(1, :) = [];
            % use group subscripts to select the appropriate colour for
            % each individual, according to their group membership
            obj.prGroupColours = obj.prGroupColours_u(obj.prGroup_s, :)';            
            
            notify(obj, 'DataChanged')
        end
        
        function val = get.Group(obj)
            val = obj.prGroup;
        end
        
        function set.ColourByGroup(obj, val)
            % check logical 
            if ~islogical(val) && ~isscalar(val)
                error('ColourByGroup must be a logical scalar (true/false).')
            end
            % check group has been set
            if isempty(obj.Group)
                error('Group property not set or invalid.')
            end
            obj.prColourByGroup = val;
        end
        
        function val = get.ColourByGroup(obj)
            % if group is not set, then this property must be false
            if isempty(obj.Group)
                val = false;
            else
                val = obj.prColourByGroup;
            end
        end
        
        function val = get.NumGroups(obj)
            if isempty(obj.Group)
                val = 0;
                return
            else
                val = length(obj.prGroup_u);
            end
        end        
        
        function set.DrawHeatmap(obj, val)
            obj.DrawHeatmap = val;
            obj.Draw;
        end
        
        function set.MarkerSize(obj, val)
            obj.MarkerSize = val;
            obj.Draw;
        end
        

    end
    
end