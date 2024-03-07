classdef vpaDynamicAOI < vpaAOIMask & vpaVideo
    
    properties
        ScoreDistance = true
    end
    
    properties (SetAccess = private)
        AOIType = 'dynamic'
        AOIColours
    end
    
%     properties (Access = protected)
%         prID 
%         prPropVal
%         prLookVector
%     end
    
    methods
        
        function obj = vpaDynamicAOI
            obj = obj@vpaVideo;
            obj.prFilterMode = 0;
        end
        
        function Score(obj, et)
        % score AOIs for all frames. Loop through all samples of ET data, 
        % extract the relevant frame from the AOI video, and pull the image
        % data into a matrix. Then pass this matrix to the ScoreImage
        % method of the superclass vpaAOIMask. Store the results.
        
            if ~obj.Valid, return, end
            vpaAssertValidEyeTrackingData(et)
            
            % grab the ID labels from the eye tracking data
            obj.prID = et.ID;
            
            % get current position on timeline, so that we can set it back
            % to here later
            currentTime = obj.Timeline.Position;
            
            % preallocate storage of scores
            in = nan(et.Gaze.NumSamples, et.Gaze.NumSubjects, obj.NumAOIs);
            dist = nan(et.Gaze.NumSamples, et.Gaze.NumSubjects, obj.NumAOIs);
            cols = nan(et.Gaze.NumSamples, et.Gaze.NumSubjects, 3); 
            
            % loop through samples and score
            t_frame = nan(et.Gaze.NumSamples, 4);
            for s = 1:et.Gaze.NumSamples
                
                obj.Parent.AllowRefresh = false;
                                
                % set timeline to time of current sample
                obj.Timeline.Position = et.Gaze.Time(s);   
                
                % spawn a child gaze object for the current sample
                gaze_s = et.Gaze.FilterOneSample(s);
               
                % score this frame
                [in(s, :, :), cols(s, :, :)] =...
                    obj.ScoreImage(gaze_s, obj.ImageData);
                
                % score distance
                if obj.ScoreDistance
%                     dist(s, :, :) = obj.ScoreDistance(in(s, :, :),...
%                         gaze_s, obj.ImageData);    
                    
                    dist(s, :, :) = etScoreAOIDistanceMask(in(s, :, :),...
                        gaze_s, obj.ImageData, obj.AOIDefinition,...
                        obj.PostInterpX, obj.PostInterpY);
            
%                     intmp = in(s, :, :);
%                     gazetmp = copyHandleClass(gaze_s);
%                     imgtmp = obj.ImageData;
%                     dist(s, :, :) = obj.ScoreDistance(intmp,...
%                         nan, imgtmp);  
                    
                    
                    
                    obj.Distance = dist;
                else
                    obj.Distance = [];
                end
                
                obj.In = in;
                obj.AOIColours = cols;
                et.AOIColours = cols;
                
                obj.Parent.AllowRefresh = true;
                obj.Parent.Refresh;
                
%                 fprintf('frame finished\n\n');
                                
            end
            
            % post-process
            obj.PostProcessScores(et.Gaze);
                
            obj.Draw
            notify(obj, 'HasDrawn')

            % put time back to where it was
            obj.Timeline.Position = currentTime;
            
        end
        
        function [area, box, perim, medDist, tab] = CalculateAOIArea(obj, maxDur)
            
            if ~exist('maxDur', 'var') || isempty(maxDur)
                maxDur = obj.Duration;
            end
            
            area = [];
            tab = table;
            if ~obj.Valid, return, end
            
            % get current position on timeline, so that we can set it back
            % to here later
            currentTime = obj.Timeline.Position;
            
            % preallocate storage of scores
            roughNumFrames = (maxDur * obj.FPS) + 100;
            frameTimes = 0:1 / obj.FPS:roughNumFrames;
            idx_eof = frameTimes > maxDur;
            numFrames = find(idx_eof, 1) - 1;
%         numFrames = 20;
            frameTimes = frameTimes(1:numFrames);
            
            area = nan(numFrames, obj.NumAOIs);
            perim = nan(numFrames, obj.NumAOIs);
            box = nan(numFrames, obj.NumAOIs);
            medDist = nan(numFrames, obj.NumAOIs);
            
            tab = cell(numFrames, 1);
            
            % loop through samples and score
            for s = 1:numFrames
                
                % set timeline to time of current sample
                obj.Timeline.Position = frameTimes(s);
                
                % calculate area on this frame
                [area(s, :), box(s, :), perim(s, :), medDist(s, :), tab{s}] =...
                    obj.CalculateAOIImageSizeStats(obj.ImageData);
%                 [area(s, :), tab_area] = obj.CalculateAOIImageArea(obj.ImageData);
%                 [box(s, :), tab_box] = obj.CalculateAOIImageBoundingBox(obj.ImageData);
%                 [perim(s, :), tab_perim] = obj.CalculateAOIImagePerimeter(obj.ImageData);
%                 [medDist(s, :), tab_medDist] = obj.CalculateAOIImageMedianDistance(obj.ImageData);
%                 tab{s} = [tab_area, tab_box, tab_perim, tab_medDist];
                tab{s}.frame = repmat(s, size(tab{s}, 1), 1);
                
%                 obj.AOIAreas = areas;
                                
            end
            
            obj.Draw
            notify(obj, 'HasDrawn')

            % put time back to where it was
            obj.Timeline.Position = currentTime;
            
        end
        
        function Draw(obj)
        % this overrides vpaVideo.Draw. We want to call that method, but
        % pass an optional shader pointer. This shader is created by the
        % vpaAOIMask class when the .MaskBackground property is set
        
            Draw@vpaVideo(obj, obj.prAlphaShader)
            
        end
        
    end
    
end