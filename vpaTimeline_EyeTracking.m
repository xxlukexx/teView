classdef vpaTimeline_EyeTracking < vpaTimeline
    
    properties
        AOI@vpaAOI
    end
    
    properties (Dependent, SetAccess = protected)
        AOIScoresValid
    end
    
    methods
        
        function obj = vpaTimeline_EyeTracking
            obj.DrawHeight = 100;
        end
        
        function Draw(obj)
            
%             profile on
                        
            % don't try to draw if invalid
            if ~obj.Valid, return, end
            
            % clear texture
            obj.Clear
            
            obj.DrawBackground
            obj.DrawAOIScores
            obj.DrawControls
            
            % fire event
            notify(obj, 'HasDrawn')
            
%             profile off
    
        end
        
        function DrawAOIScores(obj)
            
            if ~obj.AOIScoresValid, return, end
            
        % scale look vector to height of timeline
        
            % get normalised look vector
            in = obj.AOI.LookVector;
            numSamps = size(in, 2);
            numAOIs = size(in, 1);
            
            % get timeline coords
            x1 = obj.prRect(1) + obj.BorderWidth;
            x2 = obj.prRect(3) - obj.BorderWidth;
            y1 = obj.prRect(2) + obj.BorderWidth;
            y2 = obj.prRect(4) - obj.BorderWidth;
            w = x2 - x1;
            h = y2 - y1;
            
            % scale y values from looking vector
            ly = round(y2 - (in * h));
            
            % calculate gap in pixels between each frame and form x values
            xinc = w / numSamps;
            lx = round(x1:xinc:x2 - xinc);
            
            % remove NaNs (not yet scored)
            idx_nan = isnan(lx);
            lx(idx_nan) = [];
            ly(idx_nan) = [];
            
            % form x, y coords in PTB format
            lx = repmat(lx, 1, numAOIs);
            xCoords = reshape([lx(1:end - 1); lx(2:end)], 1, []);
            yCoords = nan(1, numAOIs * numSamps * 2);
            s1 = 1;
            s2 = numSamps * 2;
            for a = 1:numAOIs
                yCoords(s1:s2) = reshape([ly(a, :); ly(a, :)], 1, []);
                s1 = s1 + (numSamps * 2);
                s2 = s2 + (numSamps * 2);
            end
            coords = [xCoords; yCoords(2:end - 1)];
            
            % form colour values per AOI
            if isprop(obj.AOI, 'AOIDefinition')
                idx_singleCol = cellfun(@(x) length(x) == 1,...
                    obj.AOI.AOIDefinition(:, 2));
                defCols(idx_singleCol) = cellfun(@(x) x{end},...
                    obj.AOI.AOIDefinition(idx_singleCol, 2),...
                    'UniformOutput', false);
                defCols(~idx_singleCol) = repmat({[255, 255, 255]}, 1,...
                    sum(~idx_singleCol));
            else
                defCols = repmat({[255, 255, 255]}, numAOIs, 1);
            end
            
            cols = nan(3, numAOIs * numSamps * 2);
            s1 = 1;
            s2 = numSamps * 2;
            for a = 1:numAOIs
                cols(:, s1:s2) = repmat(defCols{a}', 1, numSamps * 2);
                s1 = s1 + (numSamps * 2);
                s2 = s2 + (numSamps * 2);
            end
            cols = cols(:, 2:end - 1);
            
            % draw
            Screen('DrawLines', obj.Ptr, coords, 2, cols, [], 2);
            
        end
        
        function val = get.AOIScoresValid(obj)
            val =...
                obj.Valid &&...
                ~isempty(obj.AOI) &&...
                isa(obj.AOI, 'vpaAOI') &&...
                obj.AOI.Valid &&...
                ~isempty(obj.AOI.LookVector) &&...
                ~all(isnan(obj.AOI.LookVector(:)));
        end
            
        
    end
    
end