classdef vpaEEG_RawFieldtrip < teViewpane
    
    properties
    end
    
    properties (Dependent)
        Data
    end
    
    properties (Dependent, SetAccess = private)
        Valid
        Continuous 
        Duration
    end
    
    properties (Access = protected)
        data
        cursorEdgeSecs
        cursorWidthSecs
        rawData
        rawSamples
        rawTimestamps
    end
    
    methods
        
        function obj = vpaEEG_RawFieldtrip(data)
            
            % check that fieldtrip is initialised
            try
                ft_defaults
            catch ERR
                error('Error initialising fieldtrip:\n\n\t%s', ERR.message)
            end
            
            % check that the data is a valid fieldtrip struct
            if  ~obj.isValidFieldtripRawData(data)
                error('The variable is not a valid FieldTrip raw data structure.');
            end
            
            % store the data
            obj.data = data;
            
            % init the cursor
            obj.cursorEdgeSecs = 0;
            obj.cursorWidthSecs = 10;
            
            % concat trials, calculate sample indices and sample timestamps
            obj.prepareData
            
            % prepare for drawing 
            obj.prepareForDrawing
            
        end
        
        function scrollLeft(obj, scrollAmount)
            % Scroll the view to the left by a specified amount
            obj.cursorEdgeSecs = obj.cursorEdgeSecs - scrollAmount;
        end
        
        function scrollRight(obj, scrollAmount)
            % Scroll the view to the right by a specified amount
            obj.cursorEdgeSecs = obj.cursorEdgeSecs + scrollAmount;
        end
        
        function zoomIn(obj, zoomFactor)
            % Zoom in the view by a specified factor
            obj.cursorWidthSecs = obj.cursorWidthSecs / zoomFactor;
        end
        
        function zoomOut(obj, zoomFactor)
            % Zoom out the view by a specified factor
            obj.cursorWidthSecs = obj.cursorWidthSecs * zoomFactor;
        end        
        
        % get/set
        
        function set.Data(obj, val)
            
            % Check if 'val' is a valid FieldTrip data structure
            if ~obj.isValidFieldtripRawData(val)
                error('Invalid FieldTrip data structure.');
            else
                obj.data = val; 
            end
            
        end
        
        function val = get.Data(obj)
            val = obj.data;
        end        
        
        function val = get.Continuous(obj)
            val = ~isempty(obj.data) && length(obj.data.trial) == 1;
        end
        
        function val = get.Valid(obj)
            val = ~isempty(obj.data) && obj.isValidFieldtripRawData(obj.data);
        end
        
        function val = get.Duration(obj)
            
            % if not valid, return empty
            if isempty(obj.data) || ~obj.isValidFieldtripRawData(obj.data)
                val = [];
                return
            end
            
            % if segmented, duration is sum total of all segments lengths.
            % Since continuous data is held in the same cell array as
            % segmented data (in data.trial), only with a length of 1, we
            % can use the same code for both conditions. 
            val = sum(cellfun(@(x) x(end), obj.data.time));

        end

    
    end

    methods (Hidden)
        
        function is = isValidFieldtripRawData(~, val)
            is = ~ft_datatype(val, 'data') || ~isstruct(val) ||...
                    ~isfield(val, 'trial') || ~isfield(val, 'time');
        end
        
        function checkCursorBounds(obj)
            
            % Check and adjust cursorEdge and cursorWidth to ensure they are within bounds
            if obj.cursorEdge < 0
                obj.cursorEdge = 0;
            elseif obj.cursorEdge > obj.data.Duration - obj.cursorWidth
                obj.cursorEdge = obj.data.Duration - obj.cursorWidth;
            end
            
            if obj.cursorWidth < 0
                obj.cursorWidth = 0;
            elseif obj.cursorWidth > obj.data.Duration
                obj.cursorWidth = obj.data.Duration;
            end
            
        end    
        
        function prepareData(obj)
            
            % Concatenate the segments and store the results
            obj.rawData = vertcat(obj.data.trial{:});
            
            % Calculate the sample indices for each sample of EEG data
            sampleStart = obj.data.sampleinfo(:, 1);
            sampleEnd = obj.data.sampleinfo(:, 2);
            numSamples = obj.data.sampleinfo(:, 2) - obj.data.sampleinfo(:, 1);
            obj.rawSamples = sampleStart(1):sampleEnd(end);
            
            % Calculate the timestamps for each sample of EEG data
            obj.rawTimestamps = (1:numSamples) / obj.data.fsample;
            
        end 
        
        function prepareForDrawing(obj)
            
            % segment around cursor
            [segRaw, segSamps, segTimeStamps] = obj.segmentCursorData;

            
        end
        
        function [segRaw, segSamps, segTimeStamps] = segmentCursorData(obj)
            
            % Convert cursorEdgeSecs and cursorWidthSecs to sample indices
            s1 = obj.cursorEdgeSecs * obj.data.fsample;
            if s1 == 0, s1 = 1; end
            s2 = obj.cursorWidthSecs * obj.data.fsample;
            
            % Segment the raw EEG data
            segRaw = obj.rawData(:, s1:s2);

            % Segment the sample indices
            segSamps = obj.rawSamples(s1:s2);

            % Segment the timestamps
            segTimeStamps = obj.rawTimestamps(s1:s2);
            
        end
        
    end
    
end




