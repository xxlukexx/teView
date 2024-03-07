function vpaAssertValidEyeTrackingData(et)

    % check that a valid instance of vpaEyeTrackingData has been
    % passed
    if ~exist('et', 'var') || ~isa(et, 'vpaEyeTrackingData') ||...
            ~et.Valid
        error('Missing or invalid eye tracking data passed.')
    end

end