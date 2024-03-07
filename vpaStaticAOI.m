classdef vpaStaticAOI < vpaAOIMask & vpaImage

    properties (SetAccess = private)
        AOIType = 'static'
    end

    methods
        
        function Score(obj, et)
        % here we simply call the ScoreImage method of the superclass
        % vpaAOIMask, and store the results
        
            if ~obj.Valid, return, end
            obj.AssertValidEyeTrackingData(et)
        
            % grab the ID labels from the eye tracking data
            obj.prID = et.ID;
            obj.prPropVal = et.Gaze.PropValid;
            
            % score the AOI image data
            [obj.In, et.AOIColours] =...
                obj.ScoreImage(et.Gaze, obj.Image);
            
            % handle post processing
            obj.PostProcessScores(et.Gaze);
            
            % calculate distance to AOI centroids
            obj.Distance = obj.ScoreDistance(obj.In, et.Gaze, obj.Image);
            
            obj.Draw
            notify(obj, 'HasDrawn')
            
            obj.calculateLookVector
            
        end
        
    end
    
    methods (Hidden)
        
        function processImage(obj)
        % process the AOI image to remove non-AOI pixels. This sets the
        % alpha channel of the image such that the background is
        % transparent. It does this using the AOI definition. 
        
            if ~obj.Valid, return, end
            
            % get image data
            img = obj.Image;
            
            % if image data does not have an alpha channel, add a blank one
            % (we'll fill it with pixels later on)
            if size(img, 3) ~= 4
                img(:, :, end + 1) = zeros(obj.ImageHeight, obj.ImageWidth);
            end
            
            % get AOI definition 
            def = obj.AOIDefinition;
            
        % get the RGB colours of all aois from the definition. Each AOI can
        % be comprised of 1 or more colours. We loop through each
        % aoi, and query the number of colours that comprises that AOI. We
        % then collect each colour in one big list. 
        
            % loop through aois
            cols = [];
            numAOIs = size(def, 1);
            for d = 1:numAOIs
                
                % query number of colours in this AOI
                numCols = length(def{d, 2});
                
                % loop through colours and collect...
                for c = 1:numCols
                    cols(end + 1, :) = def{d, 2}{c};
                end
                
            end
            
        % search the image, separately for each colour channel, for any AOI
        % colours. Any pixels that are NOT an AOI colour are background and
        % will be removed

            % get index of pixels in the AOI for each colour channel
            idx_r = arrayfun(@(red) img(:, :, 1) == red, cols(:, 1),...
                'uniform', false);
            idx_g = arrayfun(@(green) img(:, :, 2) == green, cols(:, 2),...
                'uniform', false);            
            idx_b = arrayfun(@(blue) img(:, :, 3) == blue, cols(:, 3),...
                'uniform', false);            
            
        % reshape the indices into 3D arrays. The third dimension
        % represents each AOI...
        
            idx_r = any(cat(3, idx_r{:}), 3);
            idx_g = any(cat(3, idx_g{:}), 3);
            idx_b = any(cat(3, idx_b{:}), 3);
            
        % now form one index from all of the AOIs, representing AOI-pixels
        
            idx_aoi = any(cat(3, idx_r, idx_g, idx_b), 3);
            
        % use this index to make an alpha channel for the image (the fourth
        % element of the third - colour - dimension, in order to be PTB
        % compatible)
        
            img(:, :, 4) = round((idx_aoi) * 255);
            
        % set the image data of the AOI using the output of the previous
        % step. We have now made any non-AOI pixels (aka the background)
        % transparent. Make a PTB texture from this image, and call the
        % Draw method to draw the newly-transparent image to the viewpane
        
            obj.Image = img;
            obj.prImgTexPtr = Screen('MakeTexture', obj.ParentPtr, obj.Image);
            obj.Draw
            
        end
        
        function val = getValid(obj)
            val = ~isempty(obj.Image) &&...
                ~isempty(obj.Ptr) &&...
                ~isempty(obj.AOIDefinition);
        end
        
    end
    
end