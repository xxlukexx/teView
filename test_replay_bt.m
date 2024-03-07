% ses = teSession('/Users/luke/Desktop/braintoolstmp/test/BT321/2018-11-05T134149');
% ses = teSession('/Users/luke/Desktop/braintoolstmp/BT319/2018-11-03T134615');
ses = teSession('/Users/luke/Desktop/braintoolstmp/test/BT344/2019-02-09T135711');
%%

clear et replay port 
sca

gaze = etGazeDataBino('te2', ses.ExternalData('eyetracking').Buffer);
et = vpaEyeTrackingData;
et.Import(gaze, {ses.ID})

sr = ses.ExternalData('screenrecording');

replay = vpaGazeReplay(gaze, sr.Sync);
replay.Path = sr.Paths('screenrecording');

tl = vpaTimeline_session(ses);
tl.TimeTranslator.AddTimeFormat('screenrecording', sr.Ext2Te, sr.Te2Ext);
% tl.Duration = gaze.Duration;
replay.Timeline = tl;
et.Timeline = tl;
et.DrawHeatmap = false;

port = teViewport;
port.Viewpane('replay') = replay;
port.Viewpane('tl') = tl;
port.Viewpane('et') = et;