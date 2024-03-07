classdef vpaVideo < teViewpane
    
    properties 
        Path
        Timeline
        CacheVideo = false
        Monochrome = false
    end
    
    properties (SetAccess = private)
        Duration
        VideoWidth
        VideoHeight   
        FPS
    end
    
    properties (Dependent, SetAccess = private)
        ImageData
    end
    
    properties (Dependent, SetAccess = private)
        Valid
        VideoAspectRatio
    end
    
    properties (Access = protected)
        prFilterMode = 1
        prShader = [];
    end
    
    properties (Access = private)
        prTimeline
        prTimelineValid
        prMovPtr
        prImagePtr
        prFPS
        prTextureCache
        prTimeUpdating = false;
        prTimer
        prPreviousTimeUpdate = nan        
    end
    
    methods 
        
        function obj = vpaVideo(varargin)
            % call superclass constructor
            obj = obj@teViewpane(varargin{:});
            % init timer
            obj.prTimer = timer(...
                'Period', round(1000 / 60) / 1000,...
                'ExecutionMode', 'fixedRate',...
                'BusyMode', 'drop',...
                'TimerFcn', @obj.Timer,...
                'ErrorFcn', @obj.Timer_ERR);
        end
        
        function LoadMovie(obj)
        % load a movie using psychtoolbox
        
        % check that the movie file exists, and that the viewpane has a
        % valid PTB Ptr (assigned by viewport - so if not yet added to vpo,
        % may not have a Ptr). 
        
            % check path
            if ~exist(obj.Path, 'file')
                error('File not found.')
            end
            
            % check Ptr
            if isempty(obj.ParentPtr)
                error('Cannot load a movie before the ParentPtr property is set to a valid Psychtoolbox window pointer.')
            end        
            
        % attempt to load
        
            try
                
%                 % get movie info, and use it to set the width and height of
%                 % the video
%                 info = mmfileinfo(obj.Path);
%                  = info.Video.Width;
%                 obj.VideoHeight = info.Video.Height;
                
                % open in PTB
                [obj.prMovPtr, obj.Duration, obj.FPS, obj.VideoWidth,...
                    obj.VideoHeight] = Screen('OpenMovie',...
                    obj.ParentPtr, obj.Path, 4, 5);
                
                % rewind to time 0
                Screen('SetMovieTimeIndex', obj.prMovPtr, 0);
                
                % get first frame
                obj.prImagePtr = Screen('GetMovieImage', obj.ParentPtr,...
                    obj.prMovPtr);
                
                % optionally cache video frames
                if obj.CacheVideo, obj.CacheFrames, end
                
            catch ERR
                
                error('Error loading video:\n\n%s', ERR.message)
                
            end
            
        end
        
        function CloseMovie(obj)
            
            if isempty(obj.prMovPtr), return, end
            
            Screen('Close', obj.prImagePtr);
            Screen('CloseMovie', obj.prMovPtr);
            obj.prMovPtr = [];
            
        end
        
        function CacheFrames(obj)
        % cache movie frames to memory. This can be slow so is only
        % recommended for short videos
        
            if ~obj.Valid, return, end
            
            wb = waitbar(0, 'Caching frames');
            
            % make frame times. GStreamer doesn't like you to specify
            % frames, but prefers timestamps. So convert frames to
            % timestamps using video FPS
            frameStep = 1 / obj.FPS;
            ft = 0:frameStep:obj.Duration - frameStep;
            
            % preallocate space for textures 
            tex = nan(size(ft));
            
            % loop through movie and cache each frame
            for f = 1:length(ft)
                Screen('SetMovieTimeIndex', obj.prMovPtr, ft(f));
                tex(f) = Screen('GetMovieImage', obj.ParentPtr,...
                    obj.prMovPtr);      
                wb = waitbar(f / length(ft), wb);
            end
            
            % store each texture ptr along with its frametime
            obj.prTextureCache = [ft', tex'];
            
            close(wb)
            delete(wb)
            
        end        
        
        function Draw(obj, shader, noNotify)
        % draw the current frame, if available, to the vpa internal texture
        
            if ~exist('shader', 'var')
                shader = [];
            end
            if ~exist('noNotify', 'var')
                noNotify = false;
            end
        
            if ~obj.Valid, return, end
            
            % clear previous frame data. Needed in case of transparency to
            % prevent ghosting
            obj.Clear
            
            % figure out source/dest sizes. Currently we don't try to
            % manage aspect ratios, since this should most correctly be
            % done by the viewport (although as of 20190403 this isn't
            % implemented)
            rect_dest = [0, 0, obj.Width, obj.Height];
            rect_src = [0, 0, obj.VideoWidth, obj.VideoHeight];
            
            Screen('DrawTexture', obj.Ptr, obj.prImagePtr, rect_src,...
                rect_dest, [], obj.prFilterMode, [], [], shader);
            
            if ~noNotify, notify(obj, 'HasDrawn'); end
            
        end
        
        function Update(obj)
        % general update which can be called from any other object, but
        % most likely by the parent teViewPort when it is initialising this
        % object. The only things we need to do in this circumstance are 1)
        % load the video if not already loaded, and 2) draw the frame
            
            if ~isempty(obj.ParentPtr) && isempty(obj.prMovPtr) && exist(obj.Path, 'file')
                obj.LoadMovie
            end
            
            obj.Draw
            
        end
        
        function UpdateTime(obj, tl, ~)
        % do any updates that happen when time changes. This is the 
        % callback for the vpaTimeLine class, so the second input argument 
        % (the 'source' in callback terminology) is the vpaTimeLine itself
        %
        % note that this calls a hidden protected method where the time
        % value is passed in seconds, rather than as a vpaTimeLine object.
        % This allows subclasses to adjust the time position (rather than
        % simply taking it from the timeline) which allows things like
        % offsets for synchronisation
        
            obj.updateTime(tl.Position)

        end
        
        function UpdateTimeline(obj, tl)
        % when a timeline is set, add a listener for the timeline's
        % PositionChanged event. This means that any time the position
        % of the timeline changes, we get update the current time of
        % this class, so that we can draw the appropriate gaze data
        
            addlistener(tl, 'PositionChanged', @obj.UpdateTime);
            
            % if unset, set timeline duration to duration of video
            if isempty(tl.Duration)
                tl.Duration = obj.Duration;
            end
            
        end
        
        function Play(obj)
            disp('Not implemented')
%             obj.prTimeUpdating = true;
%             Screen('PlayMovie', obj.prMovPtr, 1);
%             start(obj.prTimer);
        end
        
        function Stop(obj)
            disp('Not implemented.')
%             Screen('PlayMovie', obj.prMovPtr, 0);
%             stop(obj.prTimer)
%             obj.prTimeUpdating = false;
        end
        
        function Timer(obj, ~, ~)
%             tic
%             obj.prFramePtr =...
%                 Screen('GetMovieImage', obj.ParentPtr,...
%                 obj.prMovPtr);            
%             obj.Draw
%             toc
        end
        
        function Timer_ERR(obj, ~, ~)
        end
        
        function set.Path(obj, val)
        % when setting a new path, check to see whether a) the viewpane has
        % a valid PTB Ptr (indicating it has been attached to a viewport
        % with an open window), and b) that the path itself exists. If so,
        % attempt to load the video that the path referes to.
        
            if ~exist(val, 'file')
                error('File not found: %s', val)
            end
            
            obj.Path = val;
            
            if ~isempty(obj.Ptr) 
%             if ~isempty(obj.Ptr) && exist(prPath, 'file')
                obj.LoadMovie
            end
            
        end
        
        function val = get.Valid(obj)
        % two conditions, 1) must have a PTB texture Ptr (as assigned by
        % teViewPort), and 2) must have a movie Ptr, indicating that the
        % movie has been loaded
        
            val = ~isempty(obj.Ptr) && ~isempty(obj.prMovPtr);
            
        end
        
        function val = get.ImageData(obj)
            if ~obj.Valid, return, end
            % get current frame from ptb
%             tic
            val = Screen('GetImage', obj.Ptr);
%             fprintf('\t\tGetImage: %.3f\n', toc);
        end
        
        function val = get.VideoAspectRatio(obj)
            if obj.Valid
                val = obj.VideoWidth / obj.VideoHeight;
            else
                val = [];
            end
        end
        
        function set.CacheVideo(obj, val)
        % if the value changes, close the video and reopen it (the 
        % LoadMovie method queries the CacheVideo property, so will know
        % how to load the movie - direct or cached)
        
            if ~isequal(obj.CacheVideo, val)
                obj.CacheVideo = val;
                obj.CloseMovie
                obj.Update
                obj.Draw
            end
            
        end
        
        function set.Monochrome(obj, val)
            obj.Monochrome = val;
            obj.Draw
        end
        
        function set.Timeline(obj, val)
            obj.Timeline = val;
            obj.UpdateTimeline(val);
        end 
        
    end
    
    methods (Hidden, Access = protected)
        
        function updateTime(obj, t)
            
            
            if ~obj.Valid, return, end
            if obj.prTimeUpdating, return, end
            
            % if time has not changed since last update, don't do anything
            if isequal(obj.prPreviousTimeUpdate, t)
                return
            end
            
            % flag an update as in progress, so we don't get multiple time
            % update requests stacking up
            obj.prTimeUpdating = true;
            
            switch obj.CacheVideo
                
                % if we are working with cached frames then find the
                % frametime closest to the current position of the
                % timeline, then look up the corresponding frame texture
                % and make that the current image of this vpa
                case true
                    
                    idx = find(obj.prTextureCache(:, 1) >= t, 1);
                    if ~isempty(idx)
                        obj.prImagePtr = obj.prTextureCache(idx, 2);            
                    end
                    
                case false
                % if not caching frames, read the frame directly from the 
                % movie file, via PTB -> Gstreamer. Check that time is not
                % out of bounds, since this can trigger all sorts of
                % PTB/GStreamer errors and crashes
                    
                    if t > 0 && t <= (obj.Duration - (1 / obj.FPS))
%                         tic
                        Screen('SetMovieTimeIndex', obj.prMovPtr, t);
%                         fprintf('\t\t\t\tSetMovieTimeIndex: [%s] %.3f\n', obj.Path, toc);
                        Screen('Close', obj.prImagePtr);
                        obj.prImagePtr = Screen('GetMovieImage', obj.ParentPtr,...
                            obj.prMovPtr);
                    end
                    
            end
            
            % draw new frame
            frameAvail = ~isempty(obj.prImagePtr) && obj.prImagePtr ~= -1;
            if frameAvail, obj.Draw, end
            
            % store the current time position for comparison next time
            obj.prPreviousTimeUpdate = t;

            % we're done with the update now, so can accept new ones as
            % they arrive
            obj.prTimeUpdating = false;
            
        end
        
    end
    
end