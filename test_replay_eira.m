ses = teSession('/Volumes/scratch/eira/E004/2018-10-24T131923');

gaze = etGazeDataBino('te2', ses.ExternalData('eyetracking').Buffer);
et = vpaEyeTrackingData;
et.Import(gaze, {ses.ID})

sr = ses.ExternalData('screenrecording');

replay = vpaGazeReplay(gaze, sr.Sync);
replay.Path = sr.Paths('screenrecording');

tl = vpaTimeline;
tl.Duration = gaze.Duration;
replay.Timeline = tl;
et.Timeline = tl;

port = teViewport;
port.Viewpane('replay') = replay;
port.Viewpane('tl') = tl;
% port.Viewpane('et') = et;

