addpath(genpath('/Users/luke/Google Drive/Dev/lm_tools'))
addpath(genpath('/Users/luke/Google Drive/Dev/ECKAnalyse'))

clear all
sca

% load('/Users/luke/Google Drive/Experiments/emovids/ph3_emovids_seg.mat')
% load('emovids_aoidef.mat')
% 
% seg = etFilterSeg(seg, 'addData',...
%     @(x) strcmpi(x, 'EMOTION_ONSETHappyDirectConstant.mov'));
% seg = etFilterSeg(seg, 'fs', @(x) abs(x - 120) < 5);
% seg.mainBuffer = cellfun(@(mb) etPreprocess(mb, 'removeoffscreen', true,...
%     'removemissing', true), seg.mainBuffer, 'uniform', false);
% [t, lx, ly, rx, ry, missing, notPresent] = etTabulateSeg(seg);

port = teViewport;
% port.WindowScale = .2;
% port.PositionPreset = 'bottomright';

tl = vpaTimeline;
tl.Duration = 20;
tl.Type = 'ui';

aoi = vpaDynamicAOI;
port.Viewpane('aoi') = aoi;
aoi.Path = '/Users/luke/Google Drive/Experiments/emovids/aois/emo_happy_direct.mov';
aoi.AOIDefinition = def;

port.Viewpane('timeline') = tl;
port.Viewpane('timeline').Duration = 10;

et = vpaEyeTrackingData;
et.Import(t, lx, ly, rx, ry, missing, notPresent)
et.Group = site;
et.Timeline = tl;
port.Viewpane('gaze') = et;

port.LayerClickBox = port.Size;
port.LayerClickBox(4) = port.LayerClickBox(4) - 250;