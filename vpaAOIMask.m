classdef vpaAOIMask < vpaAOI
    
    properties 
        AOIDefinition
        MaskWidth
        MaskHeight
        ColourTolerance = 10
        PixelRadius = 3
    end
    
    properties (Dependent)
        NumAOIs
    end
    
    properties (SetAccess = protected)
        In
        Distance
    end
    
    properties (Access = protected)
        prAlphaShader
    end
    
    methods   
        
        function [in, cols] = ScoreImage(obj, gaze, img)
        % takes the gaze data from a vpaEyeTrackingData instance and scores 
        % against the AOI
            
            [in, cols] = etScoreAOIMask(gaze, img, obj.AOIDefinition,...
                obj.ColourTolerance);

        end
        
        function dist = ScoreDistance(obj, in, gaze, img)
            dist = etScoreAOIDistanceMask(in, gaze, img, obj.AOIDefinition,...
                obj.PostInterpX, obj.PostInterpY);
        end
        
        function [area, tab] = CalculateAOIImageArea(obj, img)
            
            def = obj.AOIDefinition;

            % split image into separate variables for each colour channel.
            % This allows us to use one set of gaze point indices to look
            % up the intensity value in each channel
            img_r = double(img(:, :, 1));
            img_g = double(img(:, :, 2));
            img_b = double(img(:, :, 3));
            colourTolerance = 10;
        
            area = zeros(1, obj.NumAOIs);
            data = cell(obj.NumAOIs, 3);
            tab = table;
            if all(img(:) == 0), return, end
            
            for a = 1:obj.NumAOIs

                % determine number of colours in this AOI
                numCols = size(def{a, 2}, 2);
                idx = false(size(img, 1), size(img, 2));
                for c = 1:numCols

                    % pull RGB values from the def
                    def_r = double(def{a, 2}{c}(1));
                    def_g = double(def{a, 2}{c}(2));
                    def_b = double(def{a, 2}{c}(3));
                    
                    idx = idx | ...
                        abs(img_r - def_r) < colourTolerance &...
                        abs(img_g - def_g) < colourTolerance &...
                        abs(img_b - def_b) < colourTolerance;
                    
                end
                    
%                 img_r(~idx) = 0;
%                 img_g(~idx) = 0;
%                 img_b(~idx) = 0;
%                 img_aoi = cat(3, img_r, img_g, img_b);
%                 disp(def{a, 1})
%                 imshow(idx)
%                 pause
                
                area(1, a) = prop(idx(:));
                data{a, 1} = def{a, 1};
                data{a, 2} = sum(idx(:));
                data{a, 3} = prop(idx(:));

            end         
            
            tab = cell2table(data, 'VariableNames', {'aoi', 'sum', 'prop'});

        end
        
        function [area, box, perim, tab] =...
                CalculateAOIImageSizeStats(obj, img)
            
            def = obj.AOIDefinition;

            % split image into separate variables for each colour channel.
            % This allows us to use one set of gaze point indices to look
            % up the intensity value in each channel
            img_r = double(img(:, :, 1));
            img_g = double(img(:, :, 2));
            img_b = double(img(:, :, 3));
            colourTolerance = 30;
        
            area = nan(1, obj.NumAOIs);
            box = nan(1, obj.NumAOIs);
            perim = nan(1, obj.NumAOIs);
            data = cell(obj.NumAOIs, 4);
            tab = table;
            if all(img(:) == 0), return, end
            
            for a = 1:obj.NumAOIs

                % determine number of colours in this AOI
                numCols = size(def{a, 2}, 2);
                idx = false(size(img, 1), size(img, 2));
                for c = 1:numCols

                    % pull RGB values from the def
                    def_r = double(def{a, 2}{c}(1));
                    def_g = double(def{a, 2}{c}(2));
                    def_b = double(def{a, 2}{c}(3));
                    
                    % update index of pixels within the AOI
                    idx = idx | ...
                        abs(img_r - def_r) < colourTolerance &...
                        abs(img_g - def_g) < colourTolerance &...
                        abs(img_b - def_b) < colourTolerance;
                    
                end
                
                stats = regionprops(idx, 'area', 'boundingbox', 'perimeter');
                
                % calculate area (as proportion of screen)
                if any(idx(:))
                    area(1, a) = sum([stats.Area] ./ numel(idx));
                    box(1, a) = (stats.BoundingBox(3) * stats.BoundingBox(4)) ./ numel(idx);
                    perim(1, a) = stats.Perimeter;
                end
                
%                 disp(def{a, 1})
%                 imshow(idx)
%                 pause
                
                data{a, 1} = def{a, 1};
                data{a, 2} = area(1, a);
                data{a, 3} = box(3, a);
                data{a, 4} = perim(1, a);

            end         
            
            tab = cell2table(data, 'VariableNames', {'aoi', 'area_px', 'area_bb', 'perim'});    
            
            
        end
        
        function MaskBackground(obj, col)
            obj.prAlphaShader = CreateSinglePassImageProcessingShader(...
                obj.ParentPtr, 'BackgroundMaskOut', double(col), 10);
        end
               
        % get / set       
        function set.AOIDefinition(obj, val)
        % fires when an AOI definition is set or updated. First the
        % definition is checked for correctness, then property is updated.
        
            etAssertAOIDef(val)
            
        % attempt to mask out the background colour. If any of the
        % definitions are called "background" then use that colour to set
        % up an OpenGL shader that will mask out any pixels in that colour.
        % This can be used when drawing the AOI image texture to quickly
        % remove the background colour. Note that if the "background" def
        % is found, it is then removed, since "background" is not actually
        % an AOI and should not treated as such (scored etc.)
        
            % check for background in def
            idx = find(strcmpi(val(:, 1), 'background'));
            if ~isempty(idx)
                
                % check that the background is specified as a single RGB
                % colour. We cannot mask multiple colours
                numCols = length(val{idx, 2});
                if numCols > 1
                    error('A ''background'' definition was found, but had multiple colours. Backgrounds can only have on colour.')
                end
                
                % extract the colour value
                col = val{idx, 2};
                
                % make shader mask
                obj.MaskBackground(col{:});

                % remove background def
                val(idx, :) = [];
                
            end
            
            % update property
            obj.AOIDefinition = val;
            
            % update AOI validity
            obj.Update
                
        end
        
        function val = get.NumAOIs(obj)
            if isempty(obj.AOIDefinition)
                val = [];
            else
                val = size(obj.AOIDefinition, 1);
            end
        end
        
    end
    
end
