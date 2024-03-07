function vpaRenderVideo(tl, file_out, fps) 

    % fix spaces in filename, otherwise gstreamer will complain
    file_out = fixUnixPathSpaces(file_out);

    % check timeline is valid
    if ~exist('tl', 'var') || ~isa(tl, 'vpaTimeline') || ~tl.Valid
        error('Must pass a vpaEyeTrackingData object (or subclass of vpaEyeTrackingData) that is in a valid state.')
    end
    
    if ~tl.Valid
        error('vpaEyeTrackingData object''s timeline is not valid.')
    end
    
    % check output path
    if ~exist('file_out', 'var') 
        error('Must pass an output filename.')
    end
    
    % check fps, if not passed, default to 30fps
    if ~exist('fps', 'var') || isempty(fps)
        fps = 30;
        fprintf('Defaulting to 30fps.\n');
    end
    
    % create frame times
    ft = 0:1 / fps:tl.Duration;% - (1 / fps);

    % create output movie file, prepare
    movPtr = Screen('CreateMovie', tl.ParentPtr, file_out, [], [], fps,...
        ':CodecType=VideoCodec=x264enc Keyframe=15 Videobitrate=24576');
    
    % loop through frames
    for f = 1:length(ft)
        tl.Position = ft(f);
        Screen('AddFrameToMovie', tl.ParentPtr, [], [], movPtr);
    end
    
    Screen('FinalizeMovie', movPtr);
    
end