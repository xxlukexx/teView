classdef vpaSalienceMap < handle
    
    properties 
        MaskWidth
        MaskHeight
        Colour
    end
       
    properties (SetAccess = protected)
        In
    end
    
    properties (Access = protected)
        prID 
        prPropVal
        prLookVector
    end
    
    methods   
        
        function [in, cols] = ScoreImage(~, gaze, img)
        % takes the gaze data from a vpaEyeTrackingData instance and scores 
        % against the AOI
            
            in = etScoreSalienceMap(gaze, img);

        end
        
    end
    
end
