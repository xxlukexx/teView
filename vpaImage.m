classdef vpaImage < teViewpane
    
    properties 
        Monochrome = false
    end
    
    properties (Dependent)
        Image
        ImageWidth
        ImageHeight
        ImageAspectRatio
    end
    
    properties (Dependent, SetAccess = private)
        Valid
    end
    
    properties (Access = protected)
        prImg
        prImgTexPtr
        prImgMonoTexPtr
        prIsUpdating = false
    end
    
    methods 
  
        function Draw(obj)
            if ~obj.Valid, return, end
%             if obj.ImageAspectRatio > 1
%                 % width > height
%                 rect_dest = [0, 0, obj.Width * obj.ImageAspectRatio, obj.Height];
%             else
%                 rect_dest = [0, 0, obj.Width, obj.Height / obj.ImageAspectRatio];
%             end
            rect_dest = [0, 0, obj.Width, obj.Height];
            rect_src = [0, 0, obj.ImageWidth, obj.ImageHeight];
            
            switch obj.Monochrome
                case false
                    tex = obj.prImgTexPtr;
                case true
                    tex = obj.prImgMonoTexPtr;
            end
            Screen('DrawTexture', obj.Ptr, tex, rect_src,...
                rect_dest);
            notify(obj, 'HasDrawn')
            
        end
        
        function Update(obj)
        % called when the viewpane is initialised, or otherwise needs to 
        % update its state. For example, a viewpane that hasn't been
        % initialised by adding it to a viewport's viewpane collection
        % doesn't yet have a PTB texture to draw to, so can't be drawn. 
        
            if isempty(obj.Ptr) || ~obj.Valid
                return
            end
            
            % if already updating, quit out. This can happen if, for
            % example, the processImage method alters the .Image property,
            % which itself triggers an update
            if obj.prIsUpdating
                return
            else
                obj.prIsUpdating = true;
            end
            
            % do other image processing. This is here so that subclasses
            % can exploit it - in the vpaImage class it doesn't do anything
            obj.processImage
            
            % make PTB textures from image and greyscale version
            obj.makePTBTextures
            
            obj.Draw
            
            obj.prIsUpdating = false;
            
        end
                
        function set.Image(obj, val)    

            % handle the input (path to image, or image matrix) and store
            % the image in a property
            obj.setOrLoadImage(val)

            % cannot do any more until we have a PTB offscreen window to
            % draw to. In case we don't have this, the functions of the
            % Update method wil be deferred until we do (and .Update is
            % called again)
            obj.Update
            
        end
        
        function val = get.Image(obj)
            val = obj.prImg;
        end
        
        function val = get.Valid(obj)
            val = obj.getValid;
        end
        
        function val = get.ImageWidth(obj)
            if obj.Valid
                val = size(obj.prImg, 2);
            else
                val = [];
            end
        end
        
        function val = get.ImageHeight(obj)
            if obj.Valid
                val = size(obj.prImg, 1);
            else
                val = [];
            end
        end
        
        function val = get.ImageAspectRatio(obj)
            if obj.Valid
                val = obj.ImageWidth / obj.ImageHeight;
            else
                val = [];
            end
        end
        
        function set.Monochrome(obj, val)
            obj.Monochrome = val;
            obj.Draw
        end

    end
    
    methods (Hidden)
        
        function setOrLoadImage(obj, val)
        % takes either a path to an image, or an image matrix. If a path,
        % attempts to load the image. Then sets the private prImg property
        % to the image matrix
        
            if nargin ~= 2
                error('Initialise this class with an image matrix, or a path to an image.')
            end
            
            % img can be an image matrix, or a path to an image. If a path,
            % load it
            if ischar(val)
                
                % check file exists
                if ~exist(val, 'file')
                    error('File not found: %s', val)
                else
                    % try to load
                    try
                        
                        [obj.prImg, ~, alpha] = imread(val);
                        
                        % if image has alpha channel, append this as the
                        % fourth element of the third dimesion of the
                        % matrix (PTB-style)
                        if ~isempty(alpha)
                            obj.prImg(:, :, end + 1) = alpha;
                        end
                        
                    catch ERR_loadImage
                        
                        error('Error loading image. Error was:\n\n%s',...
                            ERR_loadImage.message)
                    end
                end
                
            elseif (isa(val, 'uint8') || isa(val, 'single') ||...
                    isa(val, 'double')) && ndims(val) <= 4
                
                % image matrix
                obj.prImg = val;
            else
                
                error('Unrecognised image format.')
            end
                        
        end
        
        function makePTBTextures(obj)
            
            % colour image
            obj.prImgTexPtr = Screen('MakeTexture', obj.ParentPtr, obj.prImg);
            
            % greyscale version
            img_grey = rgb2gray(obj.prImg(:, :, 1:3));
            obj.prImgMonoTexPtr = Screen('MakeTexture', obj.ParentPtr, img_grey);
            
        end
        
        function processImage(~)
        end
        
        function val = getValid(obj)
            val = ~isempty(obj.Ptr) && ~isempty(obj.prImg) &&...
                ~isempty(obj.Size);
        end
        
    end
    
end