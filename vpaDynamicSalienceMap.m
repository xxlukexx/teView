classdef vpaDynamicSalienceMap < vpaSalienceMap & vpaVideo
    
    methods
        
        function obj = vpaDynamicSalienceMap
            obj = obj@vpaVideo;
            obj.prFilterMode = 0;
        end
        
        function Score(obj, et)
        % score salience for all frames. Loop through all samples of ET data, 
        % extract the relevant frame from the salience video, and pull the image
        % data into a matrix. Then pass this matrix to the ScoreImage
        % method of the superclass vpaSalienceMap. Store the results.
        
            if ~obj.Valid, return, end
            vpaAssertValidEyeTrackingData(et)
            
            % grab the ID labels from the eye tracking data
            obj.prID = et.ID;
            
            % get current position on timeline, so that we can set it back
            % to here later
            currentTime = obj.Timeline.Position;
            
            % preallocate storage of scores
            in = nan(et.Gaze.NumSamples, et.Gaze.NumSubjects, 1);
            cols = nan(et.Gaze.NumSamples, et.Gaze.NumSubjects, 3); 
            
            % loop through samples and score
            for s = 1:et.Gaze.NumSamples
                
                % set timeline to time of current sample
                obj.Timeline.Position = et.Gaze.Time(s);   
                
                % spawn a child gaze object for the current sample
                gaze_curSample = et.Gaze.FilterOneSample(s);
                
                % score this frame
                in(s, :, :) = obj.ScoreImage(gaze_curSample, obj.ImageData);
                obj.In = in;
%                 obj.AOIColours = cols;
%                 et.AOIColours = cols;
                                
            end
            
            obj.Draw
            notify(obj, 'HasDrawn')

            % put time back to where it was
            obj.Timeline.Position = currentTime;
            
            
        end
        
%         function Draw(obj)
%         % this overrides vpaVideo.Draw. We want to call that method, but
%         % pass an optional shader pointer. This shader is created by the
%         % vpaAOIMask class when the .MaskBackground property is set
%         
%             Draw@vpaVideo(obj, obj.prAlphaShader)
%             
%         end
        
    end
    
end