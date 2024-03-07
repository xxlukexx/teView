classdef vpaAOIRect < vpaAOI
    
    properties
        Dimensions
    end
    
    properties (SetAccess = protected)
        In
    end
    
    properties (Dependent, SetAccess = private)
        Valid
    end
    
    properties (Constant)
        COL_AOI_LIGHT           = [245, 145, 110]
        COL_AOI_DARK            = [247, 202, 024]
    end
    
    methods
        
        function obj = vpaAOIRect(rect)
            obj.Dimensions = rect;
        end
        
        function Score(obj, et)
            
            if ~obj.Valid, return, end
            obj.AssertValidEyeTrackingData(et)
        
            % grab the ID labels from the eye tracking data
            obj.prID = et.ID;
            obj.prPropVal = et.Gaze.PropValid;
            
            % score the AOI image data
            obj.In = etScoreAOIRect(et.Gaze, obj.Dimensions);
            
            % handle post processing
            obj.PostProcessScores(et.Gaze);
            
            % calculate distance to AOI centroids
            warning('AOI distance calculations not done yet for rects')
%             obj.Distance = obj.ScoreDistance(obj.In, et.Gaze, obj.Image);
            
            obj.Draw
            notify(obj, 'HasDrawn')
            
            obj.calculateLookVector            
            
        end
        
        function Draw(obj)
            
            w = obj.Width;
            h = obj.Height;
            rect = obj.Dimensions .* [w, h, w, h];
            Screen('FrameRect', obj.Ptr, obj.COL_AOI_LIGHT, rect, 4);
            
            
        end
    
        % get/set
        function val = get.Valid(obj)
            val = ~isempty(obj.Dimensions) && isvector(obj.Dimensions) &&...
                length(obj.Dimensions) == 4 &&...
                obj.Dimensions(3) > obj.Dimensions(1) &&...
                obj.Dimensions(4) > obj.Dimensions(2) &&...
                all(obj.Dimensions >= 0) && all(obj.Dimensions <= 1);
        end
        
    end
    
end