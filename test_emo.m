addpath(genpath('/Users/luke/Google Drive/Dev/lm_tools'))
addpath(genpath('/Users/luke/Google Drive/Dev/ECKAnalyse'))
addpath('/Users/luke/Google Drive/Dev/LEAP_ET')

clear all
load('/Users/luke/Google Drive/Experiments/emovids/ph3_emovids_seg.mat')
load('/Users/luke/Google Drive/Experiments/emovids/aois/aoi_def.mat')

[stim_u, ~, stim_s] = unique(seg.addData);

mb = seg.mainBuffer;
tb = seg.timeBuffer;
parfor s = 1:seg.numIDs
    
    % resample
    [mb{s}, tb{s}] = etResample(mb{s}, tb{s}, 25);

    % preproc
    mb{s} = etPreprocess(mb{s}, 'removeoffscreen', true, 'removemissing',...
        true);
end
seg.mainBuffer = mb;
seg.timeBuffer = tb;

    scene = 5;
    
    segf = etFilterSeg(seg, 'addData', @(x) strcmpi(x, stim_u{scene}));
    [t, lx, ly, rx, ry, missing, notPresent, id] = etTabulateSeg(segf);

    clear port
    sca
    port = teViewport;
    port.Size = [0, 0, 960, 540];
    % port.WindowScale = .2;
    % port.PositionPreset = 'bottomright';


%     stim = vpaV;
%     port.Viewpane('stimulus') = stim;
%     stim.Image = '/Users/luke/Google Drive/Experiments/staticimages/stimuli/STATIC6.jpg';
%     stim.Monochrome = true;
    
    aoi = vpaDynamicAOI;
    aoi.CacheVideo = true;
    port.Viewpane('aoi') = aoi;
    aoi.Path = '/Users/luke/Google Drive/Experiments/emovids/aois/emo_happy_direct.mp4';
    aoi.AOIDefinition = def;

    tl = vpaTimeline;
    tl.Duration = max(t);
    tl.Type = 'ui';
    port.Viewpane('timeline') = tl;

    et = vpaEyeTrackingData;
    et.Import(t, lx, ly, rx, ry, missing, notPresent, id)
    et.Timeline = tl;
    port.Viewpane('gaze') = et;
    aoi.Score(et)
    aoi.Alpha = .3;
    aoi.TimeLine = tl;
    et.DrawHeatmap = true;
    
    port.LayerClickBox = port.Size;
    port.LayerClickBox(4) = port.LayerClickBox(4) - 250;

    %%

%     tab = aoi.SubjectTable;
%     tab = LEAP_appendMetadata(tab, 'ID');
%     file = fullfile('/Users/luke/Google Drive/Experiments/staticimages/staticsocial',...
%         sprintf('LEAP_ET_staticsocial_scores_scene%d_%s.xlsx',...
%         scene, datetimeStr));
%     writetable(tab, file)
% 
%     % remove all but ASD/TD groups
%     idxASD_TD = strcmpi(tab.group, 'ASD') | strcmpi(tab.group, 'TD');
%     tab = tab(idxASD_TD, :);
% 
%     % make group/schedule subscripts
%     [grp_u, ~, grp_s] = unique(tab.group);
%     numGrps = length(grp_u);
%     [sched_u, ~, sched_s] = unique(tab.schedule_adj);
%     numScheds = length(sched_u);
% 
%     % aggregate AOI scores by group/sched
%     numAOIs = size(aoi.AOIDefinition, 1);
%     res = cell(numAOIs, 1);
%     for a = 1:numAOIs
%         res{a} = accumarray([sched_s, grp_s], tab{:, a + 1}, [], @nanmean);
%     end
% 
%     figure('units', 'normalized', 'Position', [0, 0, 1, 1])
%     spc = 1;
%     for s = 1:numScheds
%         for a = 1:numAOIs
% 
%             subplot(numScheds, numAOIs, spc)
% 
%             idx = sched_s == s;
%             data = tab{idx, a + 1};
% 
%             [grp_u, ~, grp_s] = unique(tab.group(idx));
%             nbp = notBoxPlot(data, grp_s, 'jitter', .5);
%             nbp(1).data.MarkerSize = 4;
%             nbp(2).data.MarkerSize = 4;
% 
%             set(gca, 'xticklabel', grp_u)
% 
%             str = sprintf('%s | %s', aoi.AOIDefinition{a, 1}, sched_u{s});
%             title(str, 'Interpreter', 'none')
%             spc = spc + 1;
% 
%         end
%     end
%     file = fullfile('/Users/luke/Google Drive/Experiments/staticimages/staticsocial',...
%         sprintf('LEAP_ET_staticsocial_scores_scene%d_%s.png',...
%         scene, datetimeStr));
%     export_fig(file, '-r150')
%     close all
% 
% end
% 

