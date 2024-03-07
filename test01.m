clear all

port = teViewport;
port.WindowScale = .2;
port.PositionPreset = 'bottomright';

port.Viewpane('test') = vpaImage;
port.Viewpane('test').Image = 'wat.png';

port.Viewpane('badass') = vpaImage;
port.Viewpane('badass').Image = 'badass.png';

% for i = 1:1000
%     port.Zoom = .5 + (i / 100);
% %     port.Refresh
% end

port.Zoom = 2;
WaitSecs(.5)
port.Zoom = .5;
WaitSecs(.5)
port.Zoom = 1;
