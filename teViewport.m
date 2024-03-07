classdef teViewport < handle
    
    properties
        Viewpane teCollection
        WindowScale = .5;
        BackgroundColour = [056, 056, 056]
%         BackgroundColour = [158, 104, 175]  
        InternalSize = [nan, nan, nan, nan];
        Offset = [0, 0]
        LayerClickBox = [nan, nan, nan, nan];
        ShowViewpaneDetails = false
    end
    
    properties (SetAccess = private)
        MouseState = [nan, nan, 0, 0, 0];
        MouseIsDown
        KeyIsDown = false
        KeyWasDown = false
    end
     
    properties (Dependent)
        IsOpen
        MonitorNumber 
        FullScreen 
        PositionPreset
        Size
        Zoom = 1
        AllowRefresh
    end
    
    properties (Dependent, SetAccess = private)
        ScreenResolution
        NumberOfViewpanes
    end
    
    properties (Access = private)
        % main settings
        prMonitorNumber 
        prPositionPreset = 'topright'
        prFullScreen = true
        prIsOpen = false;
        prWindowSize
        prWindowSizeSetManually = false
        prWinPtr
        prZoom = 1
        prTimer
        prTimerReady = false
        prAcceptingRefreshRequests = false
        % housekeeping
        prPTBOldSyncTests
        prPTBOldWarningFlag
        % mouse
        prMouseDownX = nan
        prMouseDownY = nan
        prPrevMouseState = [nan, nan, nan, nan, nan]
        % event handling
        prUIEvents
        lsViewpane_AddItem
        lsViewpane_RemoveItem
        lsViewpane_Clear
        lsViewpane_MouseMove
        lsViewpane_MouseDown
        lsViewpane_MouseUp
        lsViewpane_HasDrawn
%         lsViewpane_DoubleClick
%         lsViewpane_Click
    end
    
    properties (Constant)
        CONST_ZOOM_MIN = .01
        CONST_ZOOM_MAX = 20
    end
    
    events
        MouseMove
        MouseDown
        MouseUp
        MouseDrag
        KeyPressed
%         Click
%         DoubleClick
    end

    methods 
        
        % constructor
        function obj = teViewport(varargin)
        % general setup for the teViewPort class. First we check whether
        % PTB is installed, and then turn of sync tests and suppress all
        % warnings, since we don't care about timing. Then we set screen
        % defaults, including sizes, initialise the viewpane collection,
        % and add some event listeners. The window is opened here. 
            
            % check PTB is installed
            AssertOpenGL
            
            % disable sync tests and set PTB verbosity to minimum
            obj.prPTBOldSyncTests =...
                Screen('Preference', 'SkipSyncTests', 2);
            obj.prPTBOldWarningFlag =...
                Screen('Preference', 'SuppressAllWarnings', 1);
            
            % if running macOS > 10.14, set kPsychUseAGLForFullscreenWindows
            % to prevent artefacts
            if ismac
                [~, os_ver] = detectOS;
                if os_ver(2) > 14
                    Screen('Preference', 'ConserveVRAM', 8192);
                end
            end
            
            % if no monitor number has been set, then set it
            % automatically. Default is the max monitor number. If more
            % than one monitor, open fullscreen on that monitor, otherwise
            % open windowed on a single monitor
            if isempty(obj.MonitorNumber)
                obj.MonitorNumber = max(Screen('screens'));
            end
            
            % if only one monitor, we cannot run in fullscreen so set that
            % option to false
            if max(Screen('Screens')) == 0
                obj.prFullScreen = false;
            end
            
            % default position preset is top left
            if isempty(obj.PositionPreset)
                obj.PositionPreset = 'topleft';
            end
            
            % set window size coordsand 
            obj.SetWindowSize   
            
            % init view pane collection
            obj.Viewpane = teCollection('teViewpane');
            obj.Viewpane.ChildProps = {'Ptr'}; 
            
            % open window
            obj.Open       
            
            % listeners - viewpane collection items
            addlistener(obj.Viewpane, 'ItemAdded', @obj.InitialiseViewpane);
            addlistener(obj.Viewpane, 'ItemRemoved', @obj.DestroyViewpane);   
            addlistener(obj.Viewpane, 'ItemsCleared', @obj.DestroyAllViewpanes);              
            
            % ui event handler
            obj.prUIEvents = teUIEvents;               
            addlistener(obj.prUIEvents, 'MouseMove', @obj.HandleMouseMove);        
            addlistener(obj.prUIEvents, 'MouseDown', @obj.HandleMouseDown);    
            addlistener(obj.prUIEvents, 'MouseUp', @obj.HandleMouseUp);  
                        
            % start event handler on timer
            obj.prUIEvents.StartTimer(obj.prWinPtr)        
            obj.prTimerReady = false;  
        
        end
        
        % destructor
        function delete(obj)
            
            fprintf('<strong>Destructor</strong>\n');
            
            % delete timers
            delete(timerfind)
                        
            % close open screen
            if obj.prIsOpen
                obj.Close
            end
            % destroy all viewpanes
            obj.DestroyAllViewpanes
            Screen('CloseAll')
           % reset PTB prefs
            Screen('Preference', 'SkipSyncTests', obj.prPTBOldSyncTests);
            Screen('Preference', 'SuppressAllWarnings',...
                obj.prPTBOldWarningFlag);
            
        end
        
        % screen
        function Open(obj)
            
            if obj.prIsOpen
                error('Screen already open.')
            end
            
            % if fullscreen, set flag to pass to PTB and set rect for
            % PTB window size
            if obj.prFullScreen
                fullscreenFlag = [];
                rect = [];
            else
                rect = obj.prWindowSize;
                fullscreenFlag = [];
            end
            
            % open window
            obj.prWinPtr = Screen('OpenWindow', obj.MonitorNumber,...
                obj.BackgroundColour, rect, [], [], [], 1, [], fullscreenFlag);
            % set up alpha blending and text font and antialiasing 
            Screen('BlendFunction', obj.prWinPtr, GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);
            Screen('Preference', 'TextAlphaBlending', 1)
            Screen('TextFont', obj.prWinPtr, 'Arial');
            
            % set internal size - same as size to begin with. Also (re)set
            % zoom to 1
%             obj.InternalSize = obj.Size;
            obj.InternalSize = [0, 0, obj.Size(3) - obj.Size(1), obj.Size(4) - obj.Size(2)];
            obj.prZoom = 1;              
            
            % flag that refresh requests are accepted
            obj.prAcceptingRefreshRequests = true;
            
            % start timer, if it's ready
            if obj.prTimerReady
                obj.prUIEvents.StartTimer(obj.prWinPtr)        
            end
            
            % set flag
            obj.prIsOpen = true;          
            
        end
        
        function Close(obj)
            
            if ~obj.prIsOpen
                error('Screen is not open.')
            end
            obj.prUIEvents.StopTimer
            Screen('Close', obj.prWinPtr);
            obj.prIsOpen = false;
            
        end
        
        function Reopen(obj)
            if obj.prIsOpen
                obj.Close
                obj.Open
            end
        end   
        
        function Refresh(obj)
            if isempty(obj.Viewpane)
                return
            end
            % no refresh requests during this method
            obj.prAcceptingRefreshRequests = false;
            
            obj.HandleKeyboard
            
            % get all offscreen window ptrs
            ptrs = cellfun(@(x) x.Ptr, obj.Viewpane.Items);
            % get viewpane validity
            val = cellfun(@(x) x.Valid, obj.Viewpane.Items);
            % get alpha values from all panes
            alpha = cellfun(@(x) x.Alpha, obj.Viewpane.Items);
            % get zorder
            zOrd = cellfun(@(x) x.ZPosition, obj.Viewpane.Items);
            % sort by zorder
            [~, so] = sort(zOrd);
            ptrs = ptrs(so);
            val = val(so);
            alpha = alpha(so);
            % remove entries for invalid panes
            ptrs(~val) = [];
            alpha(~val) = [];
            if isempty(ptrs), return, end
            % set destination rects according to viewpane type. If layer,
            % then destination size = internal size (i.e. it should scroll
            % and zoom). If ui, dest size = size (i.e. no scroll or zoom)
            isLayer = cellfun(@(x) strcmpi(x.Type, 'layer'),...
                obj.Viewpane.Items);
            isLayer = isLayer(val);
            rect_dest = nan(4, sum(val));
            rect_dest(:, isLayer) = repmat(obj.InternalSize', 1, sum(isLayer));
            rect_dest(:, ~isLayer) = repmat(obj.InternalSize', 1, sum(~isLayer));

            % optionally draw viewpane details
            if obj.ShowViewpaneDetails
                obj.DrawViewpaneDetails(rect_dest)
            end            
            % draw
            Screen('DrawTextures', obj.prWinPtr, ptrs, [], rect_dest,...
                [], [], alpha');
            % flip
            Screen('Flip', obj.prWinPtr, [], [], 2);
            % requests OK again
            obj.prAcceptingRefreshRequests = true;
        end
        
        function RequestRefresh(obj, ~, ~)
            if obj.prAcceptingRefreshRequests
                obj.Refresh
            end
        end
        
        function Draw(obj)
            if isempty(obj.Viewpane)
                return
            end
            % do not accept any requests whilst this method runs (since we
            % will do a refresh at the end)
            obj.prAcceptingRefreshRequests = false;
            % get zorder of viewpanes
            zOrd = cellfun(@(x) x.ZPosition, obj.Viewpane.Items);
            % sort by zorder
            [~, so] = sort(zOrd);
            vpa_so = obj.Viewpane.Items;
            vpa_so = vpa_so(so);
            % loop through viewpanes and ask each one to draw, in zOrder
            for vpa = 1:obj.Viewpane.Count
                vp = vpa_so{vpa};
                obj.ResizeViewpane(vp);
                if vp.Valid
                    vp.Draw;
                end
            end
            obj.Refresh
            % start accepting refresh requests again
            obj.prAcceptingRefreshRequests = true;
        end
                    
        function HandleKeyboard(obj)
            
            obj.KeyWasDown = obj.KeyIsDown;
            [obj.KeyIsDown, ~, keyCode] = KbCheck(-1);
            
            if ~obj.KeyWasDown && obj.KeyIsDown
                % key pressed for the first time
                event = teEvent(keyCode);
                notify(obj, 'KeyPressed', event)
            end

        end
        
        function DrawViewpaneDetails(obj, rects)
            val = cellfun(@(x) x.Valid, obj.Viewpane.Items);
%             labels = obj.Viewpane.Keys(val);
            cols = round(hsv(sum(val)) .* 255);
            Screen('FillRect', obj.prWinPtr, cols', rects);
        end
        
        % viewpane management
        function InitialiseViewpane(obj, col, eventData)
            % get item
            vpa = col(eventData.Data);
%             % check that this has not already been added
%             if ismember(vpa.prGUID, obj.Viewpane.prGUID)
%                 error('Cannot add the same teViewpane to one teViewport more than once.')
%             end
            % open offscreen window, default to same size as viewport
            vpa.Ptr = Screen('OpenOffscreenWindow', obj.prWinPtr,...
                [0, 0, 0, 0], obj.Size);
            % set alpha blending
            Screen('BlendFunction', vpa.Ptr, GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);            
            % set view pane props
            vpa.Size = obj.InternalSize(3:4) - obj.InternalSize(1:2);
            % pass a copy of the viewport (this class) 
            vpa.Parent = obj;
            % set parent ptr (the ptr of the current ptb window)
            vpa.ParentPtr = obj.prWinPtr;
            % pass event handler
            vpa.UIEvents = obj.prUIEvents;
            % init listeners
            addlistener(vpa, 'HasDrawn', @obj.RequestRefresh); 
            % update pane validity
            vpa.Update
            % draw
            obj.Draw
        end
        
        function DestroyViewpane(~, col, eventData)
            % get item
            vpa = col(eventData.Data{1});
            % close window
            Screen('Close', vpa.Ptr);
        end
        
        function DestroyAllViewpanes(obj)
            vpa = obj.Viewpane.Items;
            if isempty(vpa), return, end
            % close all
            alreadyClosed = nan(size(vpa));
            for i = 1:length(vpa)
                ptrToClose = vpa{i}.Ptr;
                if ~ismember(ptrToClose, alreadyClosed)
                    Screen('Close', ptrToClose);
                    alreadyClosed(i) = ptrToClose;
                end
            end
        end
        
        function ResizeViewpane(obj, vpa)
%             warning('Why are we resizing the viewpane?')
%             vpa.Valid = false;
%             Screen('Close', vpa.Ptr);
%             vpa.Size = obj.InternalSize(3:4) - obj.InternalSize(1:2);
%              % open offscreen window, default to same size as viewport
%             vpa.Ptr = Screen('OpenOffscreenWindow', obj.prWinPtr,...
%                 [0, 0, 0, 0], obj.Size);
%             % set alpha blending
%             Screen('BlendFunction', vpa.Ptr, GL_SRC_ALPHA,...
%                 GL_ONE_MINUS_SRC_ALPHA);   
%             vpa.Valid = true;
        end
        
        function ApplyZoom(obj)
            % get current size of window
            rect = obj.Size;
            % find centre
            cx = (rect(3) - rect(1)) / 2;
            cy = (rect(4) - rect(2)) / 2;
            % subtract centre for resizing
            rect = rect - [cx, cy, cx, cy];
            % resize
            rect = rect * obj.prZoom;
            % apply offset
            cx = cx + obj.Offset(1);
            cy = cy + obj.Offset(2);
            % put back in original position
            obj.InternalSize = rect + [cx, cy, cx, cy];
            % refresh
            obj.Draw
        end
                
        function HandleMouseMove(obj, src, ~)
            if obj.prUIEvents.MouseIsDown
                % test for mouse in clickbox
                if src.MouseX > obj.LayerClickBox(1) &&...
                        src.MouseY > obj.LayerClickBox(2) &&...
                        src.MouseX < obj.LayerClickBox(3) &&...
                        src.MouseY < obj.LayerClickBox(4)
                    
                    % update offset according to degree of mouse movement since
                    % last check
                    mcx = obj.prUIEvents.MouseXChange;
                    mcy = obj.prUIEvents.MouseYChange;
                    obj.Offset = obj.Offset + [mcx, mcy];
                end
            end
%                 
%                 
%                 % get current mouse
%                 omx = obj.prPrevMouseState(1);
%                 omy = obj.prPrevMouseState(2);
%                 if ~isnan(omx) && ~isnan(omy)
%                     % get mouse down 
%                     mx = obj.MouseState(1);
%                     my = obj.MouseState(2);
%                     obj.Offset = obj.Offset + [mx - omx, my - omy];
%                 end
%                 % store current mouse state
%                 obj.prPrevMouseState = obj.MouseState;
%             end
        end
             
        function HandleMouseDown(obj, ~, ~)
            obj.prMouseDownX = obj.MouseState(1);
            obj.prMouseDownY = obj.MouseState(2);
            obj.MouseIsDown = true;
        end        
        
        function HandleMouseUp(obj, ~, ~)
            obj.prMouseDownX = nan;
            obj.prMouseDownY = nan;
            obj.MouseIsDown = false;
            obj.prPrevMouseState = [nan, nan, nan, nan, nan];
        end        

        % get / set
        function val = get.IsOpen(obj)
            val = obj.prIsOpen;
        end
        
        function val = get.MonitorNumber(obj)
            val = obj.prMonitorNumber;
        end
        
        function set.MonitorNumber(obj, val)
            % set prop
            changed = ~isequal(val, obj.prMonitorNumber);
            obj.prMonitorNumber = val;
            if changed && obj.IsOpen
                obj.Reopen
            end
        end
                
        function val = get.FullScreen(obj)
            val = obj.prFullScreen;
        end
        
        function set.FullScreen(obj, val)
            % check val
            if ~islogical(val) && ~isscalar(val)
                error('FullScreen must be a logical scalar (true/false)')
            end
            % set val
            changed = ~isequal(obj.prFullScreen, val);
            obj.prFullScreen = val;
            % figure out window coords from the preset
            obj.SetWindowSize
            if changed && obj.IsOpen
                obj.Reopen
            end
        end
        
        function val = get.ScreenResolution(obj)
            val = Screen('Rect', obj.MonitorNumber);
        end
        
        function val = get.Size(obj)
            val = obj.prWindowSize;
        end
        
        function set.Size(obj, val)
            % check value
            if ~isnumeric(val) || ~isvector(val) || length(val) ~= 4 ||...
                    any(val) < 0
                error('Size must be a positive numeric vector of length 4.')
            elseif val(1) > val(3) || val(2) > val(4)
                error('Impossible rect values in Size - [x2, y2] must be < [x1, y1].')
            elseif val(3) > obj.ScreenResolution(3) ||...
                    val(4) > obj.ScreenResolution(4)
                error('Size cannot extend beyond the edges of the screen.')
            end
            % assign value and set flag to indicate a manual setting so
            % that preset is ignored
            if ~obj.FullScreen
                obj.prWindowSize = val;
                obj.prWindowSizeSetManually = true;
                % reopen window
                obj.Reopen
            else
                warning('Cannot set Size property when FullScreen is true.')
            end
        end
        
        function val = get.PositionPreset(obj)
            if obj.prWindowSizeSetManually
                val = 'manual';
            elseif obj.FullScreen
                val = 'fullscreen';
            else    
                val = obj.prPositionPreset;
            end
        end
        
        function set.PositionPreset(obj, val)
            % check value
            if ~ischar(val) || ~ismember(val, {'topleft', 'topright',...
                    'bottomleft', 'bottomright'})
                error(['Valid values for PositionPreset are: ''topleft'', ',...
                    '''topright'', ''bottomleft'', ''bottomright'''])
            end
            % set val
            changed = ~isequal(val, obj.prPositionPreset);
            obj.prPositionPreset = val;
            % set flag to indicate that a preset is being used, as opposed
            % to window size having been set manually
            obj.prWindowSizeSetManually = false;
            % figure out window coords from the preset
            obj.SetWindowSize
            if changed && obj.IsOpen && ~obj.FullScreen
                obj.Reopen
            end
        end
        
        function val = get.NumberOfViewpanes(obj)
            val = obj.Viewpane.Count;
        end
        
        function val = get.Zoom(obj)
            val = obj.prZoom;
        end
        
        function set.Zoom(obj, val)
            if ~isnumeric(val) || ~isscalar(val) ||...
                    val < obj.CONST_ZOOM_MIN || val > obj.CONST_ZOOM_MAX
                error('Zoom must be a positive numeric scalar between %.2f and %d.',...
                    obj.CONST_ZOOM_MIN, obj.CONST_ZOOM_MAX)
            end
            % set property
            obj.prZoom = val;
            % apply
            obj.ApplyZoom
        end
        
        function set.Offset(obj, val)
            if ~isnumeric(val) || ~isvector(val) || length(val) ~= 2
                error('Offset must be a numeric vector [x, y].')
            end            
            % apply
            obj.Offset = val;
            obj.ApplyZoom
        end

        function set.WindowScale(obj, val)
            if ~isnumeric(val) || ~isscalar(val) || val < 0.01 || val > 1
                error('WindowScale must be a positive numeric scalar betwen 0.001 and 1.000.')
            end
            obj.WindowScale = val;
            obj.SetWindowSize
            obj.Reopen
        end
        
        function set.BackgroundColour(obj, val)
            obj.BackgroundColour = val;
            Screen('FillRect', obj.prWinPtr, val);
            obj.Refresh
        end
        
        function val = get.AllowRefresh(obj)
            val = obj.prAcceptingRefreshRequests;
        end
        
        function set.AllowRefresh(obj, val)
            obj.prAcceptingRefreshRequests = val;
        end
        
    end
    
    methods (Hidden, Access = private)
        
        % utilities
        function SetWindowSize(obj)
            if obj.prFullScreen
                obj.prWindowSize = obj.ScreenResolution;
            elseif ~obj.prWindowSizeSetManually
                % calculate to-be-set width and height of window from width and
                % height of screen
                w = obj.ScreenResolution(3) * obj.WindowScale;
                h = obj.ScreenResolution(4) * obj.WindowScale;
                % find x1, y1 from preset
                switch lower(obj.prPositionPreset)
                    case 'topleft'
                        x1 = 0;
                        y1 = 0;
                    case 'topright'
                        x1 = obj.ScreenResolution(3) - w;
                        y1 = 0;
                    case 'bottomleft'
                        x1 = 0;
                        y1 = obj.ScreenResolution(4) - h;
                    case 'bottomright'
                        x1 = obj.ScreenResolution(3) - w;
                        y1 = obj.ScreenResolution(4) - h;
                    otherwise
                        error('Invalid preset. Valid presets are: topleft, topright, bottomleft, bottomright.')
                end
                % set x2, y2 using width and height
                x2 = x1 + w;
                y2 = y1 + h;
                % set
                obj.prWindowSize = [x1, y1, x2, y2];
            end
        end          
        
    end
    
end