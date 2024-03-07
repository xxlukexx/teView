clear all

port = teViewport;
port.WindowScale = .2;
port.PositionPreset = 'bottomright';

port.Viewpane('test') = vpaImage;
port.Viewpane('test').Image = 'wat.png';

tl = vpaTimeline;
tl.Duration = 20;
tl.Type = 'ui';
port.Viewpane('timeline') = tl;
port.Viewpane('timeline').Duration = 10;

et = vpaEyeTrackingData;
et.Import(t, lx, ly, rx, ry, missing, notPresent)
port.Viewpane('gaze') = et;

port.LayerClickBox = port.Size;
port.LayerClickBox(4) = port.LayerClickBox(4) - 250;