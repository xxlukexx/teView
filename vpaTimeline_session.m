classdef vpaTimeline_session < vpaTimeline
    
    properties
        Session teSession
        TimeTranslator teTimeTranslator
    end
       
    properties (Dependent)
        SessionValid
        Position_Session        
    end
    
    properties (Dependent, SetAccess = private)
%         Valid
    end
    
    properties (Access = private)
        TaskData
%         TimeOffset
    end
    
    methods
        
        function obj = vpaTimeline_session(ses)
            obj.TimeTranslator = teTimeTranslator;
            obj.Session = ses;
            obj.DrawHeight = 100;
        end
        
        function SetDurationFromSession(obj)
            
            if isempty(obj.Session.Log.LogArray)
                error('Empty log.')
            end
            
            if ~obj.SessionValid
                error('Session not valid.')
            end
            
            t1 = obj.Session.Log.LogArray{1}.timestamp;
            t2 = obj.Session.Log.LogArray{end}.timestamp;
            
            obj.TimeTranslator.FirstTeTimestamp = t1;
            obj.Duration = t2 - t1;
%             obj.TimeOffset = t1;

        end
        
        function ProcessTasks(obj)
            
            if ~obj.SessionValid
                error('Session not valid.')
            end            
            
            % get task on/offsets from the log
            tab_on = teLogFilter(obj.Session.Log.LogArray,...
                'topic', 'task_change', 'data', 'task_onset');
            tab_off = teLogFilter(obj.Session.Log.LogArray,...
                'topic', 'task_change', 'data', 'task_offset');
            
            % append indices to each task
            tab_on.idx(:, 1) = 1:size(tab_on, 1);
            tab_on.taskidx = cellfun(@(x, y) sprintf('%s_%d', x, y),...
                tab_on.source, num2cell(tab_on.idx), 'UniformOutput', false);
            tab_off.idx(:, 1) = 1:size(tab_off, 1);
            tab_off.taskidx = cellfun(@(x, y) sprintf('%s_%d', x, y),...
                tab_off.source, num2cell(tab_off.idx), 'UniformOutput', false);            
            
            % remove empty trial GUIDs
            idx_on_empty = cellfun(@isempty, tab_on.trialguid);
            tab_on(idx_on_empty, :) = [];
            idx_off_empty = cellfun(@isempty, tab_off.trialguid);
            tab_off(idx_off_empty, :) = [];
            
            % join
            tab = innerjoin(tab_on, tab_off, 'Keys', 'taskidx',...
                'LeftVariables', {'timestamp', 'source'},...
                'RightVariables', {'timestamp'});
            tab.Properties.VariableNames{'timestamp_tab_on'} = 'onset_te';
            tab.Properties.VariableNames{'timestamp_tab_off'} = 'offset_te';
            tab = sortrows(tab, 'onset_te');
            
            % get absolute (i.e. duration since session start) timestamps
            tab.onset_abs = obj.TimeTranslator.Te2Abs(tab.onset_te);
            tab.offset_abs = obj.TimeTranslator.Te2Abs(tab.offset_te);
            
%             % zero timestamps
%             tab.onset = tab.onset - obj.TimeOffset;
%             tab.offset = tab.offset - obj.TimeOffset;
            
            obj.TaskData = tab;

        end
        
        function Draw(obj)
                        
            % don't try to draw if invalid
            if ~obj.Valid, return, end
            
            % clear texture
            obj.Clear
            
            obj.DrawBackground
            obj.DrawTasks
            obj.DrawControls
            
            % fire event
            notify(obj, 'HasDrawn')
    
        end
        
        function DrawTasks(obj)
            
            if ~obj.SessionValid, return, end
            
            % rescale time to pixels
            width_tl = obj.prRect(3) - obj.prRect(1);
            onsets = round((obj.TaskData.onset_abs / obj.Duration) * width_tl);
            offsets = round((obj.TaskData.offset_abs / obj.Duration) * width_tl);
            
            % build rects
            numTasks = length(onsets);
            rects = [onsets, repmat(obj.prRect(2), numTasks, 1), offsets,...
                repmat(obj.prRect(4), numTasks, 1)];
            
            % draw
            Screen('FrameRect', obj.Ptr, [255, 255, 255], rects');
            
            
%         % scale look vector to height of timeline
%         
%             % get normalised look vector
%             in = obj.AOI.LookVector;
%             numSamps = size(in, 2);
%             numAOIs = size(in, 1);
%             
%             % get timeline coords
%             x1 = obj.prRect(1) + obj.BorderWidth;
%             x2 = obj.prRect(3) - obj.BorderWidth;
%             y1 = obj.prRect(2) + obj.BorderWidth;
%             y2 = obj.prRect(4) - obj.BorderWidth;
%             w = x2 - x1;
%             h = y2 - y1;
%             
%             % scale y values from looking vector
%             ly = round(y2 - (in * h));
%             
%             % calculate gap in pixels between each frame and form x values
%             xinc = w / numSamps;
%             lx = round(x1:xinc:x2 - xinc);
%             
%             % remove NaNs (not yet scored)
%             idx_nan = isnan(lx);
%             lx(idx_nan) = [];
%             ly(idx_nan) = [];
%             
%             % form x, y coords in PTB format
%             lx = repmat(lx, 1, numAOIs);
%             xCoords = reshape([lx(1:end - 1); lx(2:end)], 1, []);
%             yCoords = nan(1, numAOIs * numSamps * 2);
%             s1 = 1;
%             s2 = numSamps * 2;
%             for a = 1:numAOIs
%                 yCoords(s1:s2) = reshape([ly(a, :); ly(a, :)], 1, []);
%                 s1 = s1 + (numSamps * 2);
%                 s2 = s2 + (numSamps * 2);
%             end
%             coords = [xCoords; yCoords(2:end - 1)];
%             
%             % form colour values per AOI
%             if isprop(obj.AOI, 'AOIDefinition')
%                 idx_singleCol = cellfun(@(x) length(x) == 1,...
%                     obj.AOI.AOIDefinition(:, 2));
%                 defCols(idx_singleCol) = cellfun(@(x) x{end},...
%                     obj.AOI.AOIDefinition(idx_singleCol, 2),...
%                     'UniformOutput', false);
%                 defCols(~idx_singleCol) = repmat({[255, 255, 255]}, 1,...
%                     sum(~idx_singleCol));
%             else
%                 defCols = repmat({[255, 255, 255]}, numAOIs, 1);
%             end
%             
%             cols = nan(3, numAOIs * numSamps * 2);
%             s1 = 1;
%             s2 = numSamps * 2;
%             for a = 1:numAOIs
%                 cols(:, s1:s2) = repmat(defCols{a}', 1, numSamps * 2);
%                 s1 = s1 + (numSamps * 2);
%                 s2 = s2 + (numSamps * 2);
%             end
%             cols = cols(:, 2:end - 1);
%             
%             % draw
%             Screen('DrawLines', obj.Ptr, coords, 2, cols, [], 2);
            
        end
        
        function val = get.SessionValid(obj)
            val =...
                isa(obj.Session, 'teSession');
        end
        
        function val = get.Position_Session(obj)
            val = obj.TimeTranslator.Abs2Te2(obj.Position);
%             val = obj.Position + obj.TimeOffset;
        end
        
        function set.Session(obj, val)
            obj.Session = val;
            obj.SetDurationFromSession                        
            obj.ProcessTasks
        end 
        
%         function val = get.Valid(obj)
%             val = ~isnan(obj.Duration) &&...
%                 isa(obj, 'teTimeline_session');
%         end        
        
    end
    
end