function staticsocial_cropABCAOIs(path_aois, path_stim)

    % get all PNG files from folder
    d = dir(sprintf('%s%s*.png', path_aois, filesep));
    
    for i = 1:length(d)
        
        % load aoi image
        file_img_aoi = fullfile(path_aois, d(i).name);
        img_aoi = imread(file_img_aoi);
        
        % load stim image
        file_img_stim = fullfile(path_stim, d(i).name);
        img_stim = imread(file_img_stim);
        
        % get stim dimensions
        w_stim = size(img_stim, 2);
        h_stim = size(img_stim, 1);
        
        % get dimensions
        w_aoi = size(img_aoi, 2);
        h_aoi = size(img_aoi, 1);
        
        % find centre of image
        cx = w_aoi / 2;
        cy = h_aoi / 2;
               
        % sizes of AOI/stim
        aoiW = 36.7;
        aoiH = 22.2;
        stimW = 23.35;
        stimH = 19.05;
        
        % scales
        xScale = stimW / aoiW;
        yScale = stimH / aoiH;
        
        % get width/height of to-be-cropped area 
        cw = round(w_aoi * xScale);
        ch = round(h_aoi * yScale);
        
        % make rect for cropping
        rect = [...
            cx - (cw / 2),...
            cy - (ch / 2),...
            cx + (cw / 2),...
            cy + (ch / 2)];
        
        % crop
        imgc = img_aoi(rect(2):rect(4), rect(1):rect(3), :);
        
        % resize AOI to image size
        imgc = imresize(imgc, [h_stim, w_stim]);
        
        % save
        imwrite(imgc, file_img_aoi);
        
    end

end