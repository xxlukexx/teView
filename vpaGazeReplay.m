classdef vpaGazeReplay < vpaVideo
    
    properties
        GazeHistorySecs = 1;
        GazeSampleSize = 10;
    end
    
    properties (SetAccess = private)
        Path_Video
        Gaze etGazeData
        Sync struct
    end
    
    properties (Constant)
        COL_ET_LEFT             = [066, 133, 244]
        COL_ET_RIGHT            = [125, 179, 066]
        COL_ET_AVG              = [213, 008, 000]
    end
    
    methods
        
        function obj = vpaGazeReplay(gaze, sync)
            obj = obj@vpaVideo;
            obj.Gaze = gaze;
            obj.Sync = sync;
        end
        
        function Draw(obj)
            
            % draw video via superclass
            Draw@vpaVideo(obj, [], true)
            
            % draw gaze
            
                % segment from current position backwards to
                % GazeHistorySecs (default 1s)
                t2 = obj.Timeline.Position;
                t1 = t2 - obj.GazeHistorySecs;
                if t1 < 0, t1 = 0; end
                gaze = obj.Gaze.SegmentByTime(t1, t2);
                if isempty(gaze), return, end
                numSamps = gaze.NumSamples;
                
                % compute alpha values
                alphaInc = 255 / numSamps;
                a_range = (0:alphaInc:255)';
                if length(a_range) > numSamps
                    a_range = a_range(1:numSamps);
                end                    
            
                % get eye validity
                val = ~gaze.Missing;
                val_l = ~gaze.LeftMissing;
                val_r = ~gaze.RightMissing;

                % convert POG to px
                if any(val)
                    % if any eyes are valid
                    gx_l = gaze.LeftX;
                    gy_l = gaze.LeftY;
                    gx_r = gaze.RightX;
                    gy_r = gaze.RightY;

                    % scale gaze to pixels
                    gx_l = round(gx_l * obj.Width);
                    gy_l = round(gy_l * obj.Height);
                    gx_r = round(gx_r * obj.Width);
                    gy_r = round(gy_r * obj.Height);

                    % average by taking available eyes, or mean of
                    % both if both visible
                    gx_a = gaze.X;
                    gy_a = gaze.Y;

                    % dot radius
                    radius = obj.GazeSampleSize;
                    
                    % make non valid samples invisible by setting
                    % their alpha value to 0 (their position is
                    % NaN)
                    a_range(~val_l & ~val_r) = 0;
                    
                    % reshape dots into row vector for PTB
                    dots = [gx_l', gx_r', gx_a'; gy_l', gy_r', gy_a'];
                    
                    % colour dots according to eye, setting alpha
                    % to fade out over time
                    col = [...
                        repmat(obj.COL_ET_LEFT, numSamps, 1), a_range;...
                        repmat(obj.COL_ET_RIGHT, numSamps, 1), a_range;...
                        repmat(obj.COL_ET_AVG, numSamps, 1), a_range];    
                    
                    % draw
                    Screen('DrawDots', obj.Ptr, dots, radius,...
                        col', [], 1);   
                    
                end

            
            notify(obj, 'HasDrawn');
            
            
        end
        
        function UpdateTime(obj, tl, ~)
            if ~isa(tl, 'vpaTimeline_session')
                error('vpaGazeReplay must be used with a vpaTimeline_session object (not teTimeline).')
            end
            t = obj.Timeline.TimeTranslator.Te2Ext(tl.Position_Session, 'screenrecording')
%             s = obj.Gaze.Time2Sample(tl.Position);
%             t = obj.Sync.te2video(tl.Position_Session)          
% %             t = obj.Sync.te2video(obj.Gaze.Timestamp(s));
%             obj.updateTime(t)
        end
        
    end
    
end
            
            
        
        