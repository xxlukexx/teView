clear all

load('/Users/luke/Desktop/BT312/2018-10-07T131632/data.mat')

port = teViewport;

vid = vpaVideo;
port.Viewpane('vid') = vid;
vid.Video = data.ScreenRecording.Path_Video;

tl = vpaTimeline;
tl.Duration = vid.Duration;
port.Viewpane('tl') = tl;
vid.Timeline = tl;

% profile on

tl.Position = 60;
vid.Play

WaitSecs(5);

vid.Stop

% profile off
% profile viewer
