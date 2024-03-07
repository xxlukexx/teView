path_aoi = '/Users/luke/Google Drive/Experiments/natscenes/50faces/aois/aoi_ns_50faces.mov';
path_def = '/Users/luke/Google Drive/Experiments/natscenes/50faces/aois/aoidef_ns_50faces.mat';
load(path_def, 'def')

vr = VideoReader(path_aoi);
img = vr.readFrame;