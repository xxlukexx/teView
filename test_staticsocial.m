addpath(genpath('/Users/luke/Google Drive/Dev/lm_tools'))
addpath(genpath('/Users/luke/Google Drive/Dev/ECKAnalyse'))
addpath('/Users/luke/Google Drive/Dev/LEAP_ET')

clear all
load('/Users/luke/Google Drive/Dev/teView/tmp_staticsocial.mat')
load('/Users/luke/Google Drive/Experiments/staticimages/staticsocial/aois/staticsocial_aoi_def.mat')
% path_data = '/Users/luke/Desktop/mat';
% dc = ECKDataContainer;
% dc.LoadExportFolder(path_data);
% seg = etGatherSegments(dc);
% 
[stim_u, ~, stim_s] = unique(seg.addData);

mb = seg.mainBuffer;
tb = seg.timeBuffer;
parfor s = 1:seg.numIDs
    
    % resample
    [mb{s}, tb{s}] = etResample(mb{s}, tb{s}, 600);

    % preproc
    mb{s} = etPreprocess(mb{s}, 'removeoffscreen', true, 'removemissing',...
        true);
end
seg.mainBuffer = mb;
seg.timeBuffer = tb;

%%

tab = cell(1, 6);
for scene = 1:6
    
    segf = etFilterSeg(seg, 'addData', @(x) strcmpi(x, stim_u{scene}));
    [t, lx, ly, rx, ry, missingLeft, missingRight, absent, id] = etTabulateSeg(segf);
    gaze = etGazeDataBino;
    gaze.Import(lx, ly, rx, ry, t, missingLeft, missingRight, absent);

    clear port aoi et tl stim 
    sca
    port = teViewport;
%     port.Size = [0, 0, 960, 540];
    % port.WindowScale = .2;
    % port.PositionPreset = 'bottomright';


    stim = vpaImage;
    port.Viewpane('stimulus') = stim;
    stimName = sprintf('STATIC%d', scene);
    stim.Image = sprintf('/Users/luke/Google Drive/Experiments/staticimages/stimuli/%s.jpg', stimName);
    stim.Monochrome = true;
    
    aoi = vpaStaticAOI;
    port.Viewpane('aoi') = aoi;
    aoi.Image = sprintf('/Users/luke/Google Drive/Experiments/staticimages/staticsocial/leap_aois/static%d.png', scene);
    aoi.AOIDefinition = def;
    aoi.Alpha = .7;

    tl = vpaTimeline;
    tl.Duration = max(t);
    tl.Type = 'ui';
    port.Viewpane('timeline') = tl;

    et = vpaEyeTrackingData;
    et.Import(gaze)
    et.Timeline = tl;
    port.Viewpane('gaze') = et;
    aoi.Score(et)
    et.DrawHeatmap = true;
    
    port.LayerClickBox = port.Size;
    port.LayerClickBox(4) = port.LayerClickBox(4) - 250;

    tab{scene} = aoi.SubjectTable;
    tab{scene}.Stimulus = repmat({sprintf('static%d', scene)}, size(tab{scene}, 1), 1);
    
    temporal = et.BuildTemporalAOIScores(aoi);
    file_temporal = fullfile(...
        '/Users/luke/Google Drive/Experiments/staticimages/staticsocial',...
        sprintf('LEAP_ET_staticsocial_scenes_temporal_scores_%s_%s.mat',...
        stimName, datestr(now, 30)));    
    save(file_temporal, 'temporal');
    
end

%%
    
% scene as a variable

    % put all stim together in one tall table
    tab_all = vertcat(tab{:});
    
    % compute face and head scores
    tab_all.face = tab_all.upper_face + tab_all.lower_face;
    tab_all.head = tab_all.face + tab_all.hair;
    
    % rearrange columns
    tab_all = [tab_all(:, 1:6), tab_all(:, 9:10), tab_all(:, 7:8), tab_all(:, 11:end)];
    
    % get leap metadata
    tab_all = LEAP_appendMetadata(tab_all, 'ID');

    % write to Excel
    file_temporal = fullfile('/Users/luke/Google Drive/Experiments/staticimages/staticsocial',...
        sprintf('LEAP_ET_staticsocial_scenes_scores_%s.xlsx', datetimeStr));
    writetable(tab_all, file_temporal)
    
% average across scene

    % remove propval < 25%
    idx_remove = tab_all.prop_valid < .25;
    tab_all(idx_remove, :) = [];
    
    % average across stimulus
    [id_u, id_i, id_s]  = unique(tab_all.ID);
    avg_upper_face      = accumarray(id_s, tab_all.upper_face,  [], @nanmean);
    avg_lower_face      = accumarray(id_s, tab_all.lower_face,  [], @nanmean);
    avg_hair            = accumarray(id_s, tab_all.hair,        [], @nanmean);
    avg_body            = accumarray(id_s, tab_all.body,        [], @nanmean);
    avg_face            = accumarray(id_s, tab_all.face,        [], @nanmean);
    avg_head            = accumarray(id_s, tab_all.head,        [], @nanmean);

    % store in table
    tab_avg             = cell2table(id_u, 'variablenames', {'ID'});
    tab_avg.upper_face  = avg_upper_face;
    tab_avg.lower_face  = avg_lower_face;
    tab_avg.hair        = avg_hair;
    tab_avg.body        = avg_body;
    tab_avg.face        = avg_face;
    tab_avg.head        = avg_head;
    
    % get leap metadata
    tab_avg = LEAP_appendMetadata(tab_avg, 'ID');
    
    % write to Excel
    file_temporal = fullfile('/Users/luke/Google Drive/Experiments/staticimages/staticsocial',...
        sprintf('LEAP_ET_staticsocial_avg_scores_%s.xlsx', datetimeStr));
    writetable(tab_avg, file_temporal)
    
% plot

    % remove all but ASD/TD groups
    idxASD_TD = strcmpi(tab_avg.group, 'ASD') | strcmpi(tab_avg.group, 'TD');
    tab_avg = tab_avg(idxASD_TD, :);

    % make group/schedule subscripts
    [grp_u, ~, grp_s] = unique(tab_avg.group);
    numGrps = length(grp_u);
    [sched_u, ~, sched_s] = unique(tab_avg.schedule_adj);
    numScheds = length(sched_u);

    % aggregate AOI scores by group/sched
    numAOIs = 6;
    res = cell(numAOIs, 1);
    for a = 1:numAOIs
        res{a} = accumarray([sched_s, grp_s], tab_avg{:, a + 1}, [], @nanmean);
    end

    figure('units', 'normalized', 'Position', [0, 0, 1, 1])
    spc = 1;
    for s = 1:numScheds
        for a = 1:numAOIs

            subplot(numScheds, numAOIs, spc)

            idx = sched_s == s;
            data = tab_avg{idx, a + 1};

            [grp_u, ~, grp_s] = unique(tab_avg.group(idx));
            nbp = notBoxPlot(data, grp_s, 'jitter', .5);
            nbp(1).data.MarkerSize = 4;
            nbp(2).data.MarkerSize = 4;

            set(gca, 'xticklabel', grp_u)

            str = sprintf('%s | %s', tab_avg.Properties.VariableNames{a + 1}, sched_u{s});
            title(str, 'Interpreter', 'none')
            spc = spc + 1;

        end
    end
    file_temporal = fullfile('/Users/luke/Google Drive/Experiments/staticimages/staticsocial',...
        sprintf('LEAP_ET_staticsocial_avg%d_%s.png',...
        scene, datetimeStr));
    export_fig(file_temporal, '-r150')
    close all
    
% % scatter
% 
%     idxASD = strcmpi(tab_avg.group, 'ASD');
%     tab_avg = tab_avg(idxASD, :);
% 
% 
% 
%     % vineland
%     vl = cell2mat(tab_avg{:, 52:55});
%     vl(vl == 999 | vl == 777) = nan;
%     
%     figure
%     subplot(2, 2, 1)
%     scatter(tab_avg.face, vl(:, 1))
% 
%     subplot(2, 2, 2)
%     scatter(tab_avg.face, vl(:, 2))
%     
%     subplot(2, 2, 3)
%     scatter(tab_avg.face, vl(:, 3))
%     
%     subplot(2, 2, 4)
%     scatter(tab_avg.face, vl(:, 4))
% 
