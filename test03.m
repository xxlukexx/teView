addpath(genpath('/Users/luke/Google Drive/Dev/lm_tools'))
addpath(genpath('/Users/luke/Google Drive/Dev/ECKAnalyse'))

clear classes
clear all
sca

% load('tmp.mat')

if ~exist('site', 'var')
    dc = ECKDataContainer;
    dc.LoadExportFolder('/Volumes/Samsung_T5/LEAP_ET/popout/mat')
    seg = etGatherSegments(dc);
    seg = etFilterSeg(seg, 'addData',...
        @(x) strcmpi(x, 'STATICIMAGES_ONSETPOPOUT1.TIFPOPOUT'));
    seg = etFilterSeg(seg, 'fs', @(x) abs(x - 120) < 5);
    seg.mainBuffer = cellfun(@(mb) etPreprocess(mb, 'removeoffscreen', true,...
        'removemissing', true), seg.mainBuffer, 'uniform', false);
    [t, lx, ly, rx, ry, missing, notPresent] = etTabulateSeg(seg);
    [site_u, site_i, site_s] = unique(seg.site);
    site = seg.site;
    save('tmp.mat', 't', 'lx', 'ly', 'rx', 'ry', 'missing', 'notPresent', 'site_u', 'site_i', 'site_s', 'site')
end


port = teViewport;
port.WindowScale = .2;
port.PositionPreset = 'bottomright';

% port.Viewpane('test') = vpaImage;
% port.Viewpane('test').Image = 'wat.png';

tl = vpaTimeline;
tl.Duration = 20;
tl.Type = 'ui';

aoi_def = {...
    'face',     [186, 108, 107]     ;...
    'car',      [107, 157, 186]     ;...
    'phone',    [111, 186, 107]     ;...
    'noise',    [240, 172, 026]     ;...
    'bird',     [209, 090, 226]     ;...
    };
aoi = vpaStaticAOI;
port.Viewpane('aoi') = aoi;
aoi.Path = '/Users/luke/Google Drive/Experiments/staticimages/popout/aoi_masks_te/POPOUT1.png';
aoi.AOIDefinition = aoi_def;

port.Viewpane('timeline') = tl;
port.Viewpane('timeline').Duration = 10;

et = vpaEyeTrackingData;
et.Import(t, lx, ly, rx, ry, missing, notPresent)
et.Group = site;
et.Timeline = tl;
port.Viewpane('gaze') = et;

leg = vpaEyeTrackingGroupLegend;
port.Viewpane('legend') = leg;
leg.EyeTrackingData = et;

port.LayerClickBox = port.Size;
port.LayerClickBox(4) = port.LayerClickBox(4) - 250;