function [position] = Couple_VideoRating(movie_name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script will run play a list of videos and collect continuous ratings
%
% Can show scrolling history of ratings if needed.
%
% Requires: Psychtoolbox 3, cosanlabtoolbox, and Gstreamer for video input
%           http://psychtoolbox.org/
%           https://github.com/ljchang/CosanlabToolbox
%           http://gstreamer.freedesktop.org/
%
% Developed by Luke Chang, Briana Robustelli, Mark Whisman, Tor Wager,
%              Andrew Frederickson
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2014 Luke Chang
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"),
% to deal in the Software without restriction, including without limitation
% the rights to use, copy, modify, merge, publish, distribute, sublicense,
% and/or sell copies of the Software, and to permit persons to whom the
% Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
% THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Notes
%1) need to find list or folder of videos to load
%2) need to add anchors for rating

%% Setup paradigm

% Set Path
fPath = '/Users/lukechang/Dropbox/Doctor_Patient_Andrew/CoupleVideo';
cosanlabToolsPath = '/Users/lukechang/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
addpath(genpath(fullfile(cosanlabToolsPath,'SupportFunctions')));

% Devices
USE_BIOPAC = 0;         % refers to Biopac make 0 if not running on computer with biopac
USE_VIDEO = 0;          % record video of Run
USE_EYELINK = 0;        % eyetracking
USE_SCANNER = 1;        % use trigger for scanning
doHistory = 1;          % Show scrolling rating history

% initialize mouse recording output
position = [];

% Initialize screen
Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL;

% Background will be black:
background=[0, 0, 0];
% background = 0;

% Open onscreen window. We use the display with the highest number on
% multi-display setups:
screen=max(Screen('Screens'));

% This will open a screen with background color 'background':
% [window rect] = Screen('OpenWindow', screen, background, [0 0 1200 900]);
[window rect] = Screen('OpenWindow', screen, background);

% Settings
STARTFIX = 4;
ENDFIX = 4;
text_size = 28;
anchor_size = 20;

%% Set up keyboard input

% Hide the mouse cursor:
HideCursor;

% Initialize Keyboard inputs
KbName('UnifyKeyNames');

% Query keycodes for ESCAPE key and Space key:

key.space = KbName('SPACE');
key.ttl = KbName('5%');
key.s = KbName('s');
key.p = KbName('p');
key.q = KbName('q');
key.esc = KbName('ESCAPE');
key.zero = KbName('0)');
key.one = KbName('1!');
key.two = KbName('2@');
key.three = KbName('3#');
key.four = KbName('4$');

RestrictKeysForKbCheck([key.space, key.s, key.p, key.q, key.esc, key.zero, key.one, key.two, key.three, key.four,key.ttl]);
% List of Emotions
emotions = {'How much guilt do you feel?','How much anger do you feel?', 'How anxious do you feel?', 'How much happiness do you feel?', 'How much pride do you feel?', 'How much disgust do you feel?', 'How much sadness do you feel?', 'How much shame','How connected do you feel?'};

%% Enter Subject Information

ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 36);
SUBID = GetEchoString(window, 'Experimenter: Please enter subject ID: ', rect(3)/2 - 300, rect(4)/2, [255, 255, 255], [0, 0, 0],[]);
SUBID = str2num(SUBID);
Screen('FillRect',window,screen); % paint black
ListenChar(1); %Start listening to keyboard again.


% Select Condition to Run
ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 28);
DrawFormattedText(window,'Experimenter: Which condition do you want to run?\n\n0: Scanner\n1: Self\n2: Other\nq: Quit','center','center',255);
Screen('Flip',window);

% Clear keys
key_name = fieldnames(key);
for k = 1:length(key_name)
    keycode(key.(key_name{k}))=0;
end

% Wait for keypress
while keycode(key.zero)==0 && keycode(key.one)==0 && keycode(key.two)==0  && keycode(key.three)==0 && keycode(key.four)==0 && keycode(key.q) == 0
    [presstime keycode delta] = KbWait;
end
button = find(keycode==1);
switch button
    case key.zero
        CONDITION = 0;
    case key.one
        CONDITION = 1;
    case key.two
        CONDITION = 2;
    case key.three
        CONDITION = 3;
    case key.four
        CONDITION = 4;
    case key.q % ESC key quits the experiment
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        sca;
        return;
end
ListenChar(1); %Start listening to keyboard again.

% Check if data file exists.  If so ask if we want to rerun, if not then quit and check subject ID.
file_exist = exist(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '_Continuous_VideoRating.csv']),'file');
ListenChar(2); %Stop listening to keyboard
if file_exist == 2
    exist_text = ['WARNING!\n\nA data file exists for Subject - ' num2str(SUBID) 'Condition - ' num2str(CONDITION) '\n\nPress ''esc'' to quit or ''p'' to proceed'];
    Screen('TextSize',window, 36);
    DrawFormattedText(window,exist_text,'center','center',255);
    Screen('Flip',window);
    keycode(esc) = 0;
    keycode(p) = 0;
    while(keycode(p) == 0 && keycode(esc) == 0)
        %     while any(keycode)
        [presstime keycode delta] = KbWait;
    end
    
    % ESC key quits the experiment, 'p' proceeds
    if keycode(esc) == 1
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        sca;
        return;
    end
end
ListenChar(1); %Start listening to keyboard again.

%Initialize File with Header
%Continous Rating
hdr = 'Subject,Video,PositionX,PositionY,Timing,Rating';
dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Continuous_VideoRating.csv']), hdr,'')

%Trial Emotion Ratings
hdr2 = 'Subject,Video,GuiltOnset,GuiltOffset,GuiltDur,GuiltRating,AngerOnset,AngerOffset,AngerDur,AngerRating,AnxiousOnset,AnxiousOffset,AnxiousDur,AnxiousRating,HappinessOnset,HappinessOffset,HappinessDur,HappinessRating,PrideOnset,PrideOffset,PrideDur,PrideRating,DisgustOnset,DisgustOffset,DisgustDur,DisgustRating,SadnessOnset,SadnessOffset,SadnessDur,SadnessRating,ShameOnset,ShameOffset,ShameDur,ShameRating,ConnectedOnset,ConnectedOffset,ConnectedDur,ConnectedRating';
dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Trial_VideoRating.csv']), hdr2,'')


%% Set up Devices

if USE_BIOPAC
    % Test to make sure io32 is on path
    try
        config_io
    catch
        error('Make sure io32 Driver is installed and config_io.m is on path')
    end
    test_func  = exist('io32');
    if test_func ~= 3
        error('if using windows, make sure io32 drivers are installed')
    end
    global BIOPAC_PORT;
    
    % DIGITALIO doesn't work for CINC computer, using io32 instead for now.
    %    BIOPAC_PORT = digitalio('parallel','LPT2');
    %     addline(BIOPAC_PORT,0:7,'out');
    
    BIOPAC_PORT = hex2dec('E050');
    
    BIOPAC_PULSE_DUR = 1; %% this counts as TIME
end

%% record eyelink whole time
if USE_EYELINK
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.05);
    %         Eyelink('StartRecording', 1, 1, 1, 1);
    Eyelink('StartRecording');
    WaitSecs(0.1);
end

if USE_VIDEO && CONDITION ~= 0
    
    % Device info
    devs = Screen('VideoCaptureDevices');
    did = [];
    for i=1:length(devs)
        if devs(i).InputIndex==0
            did = [did,devs(i).DeviceIndex];
        end
    end
    
    % Select Codec
    c = ':CodecType=x264enc Keyframe=1: CodecSettings= Videoquality=1';
    
    % Settings for video recording
    recFlag = 0 + 4 + 16 + 64; % [0,2]=sound off or on; [4] = disables internal processing; [16]=offload to separate processing thread; [64] = request timestamps in movie recording time instead of GetSecs() time:
    
    % Initialize capture
    % Need to figure out how to change resolution and select webcam
    grabber = Screen('OpenVideoCapture', window, did(2), [], [], [], 1, fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Condition' num2str(CONDITION) '_VideoRating.avi' c]), recFlag, 3, 8);
    WaitSecs('YieldSecs', 2); %insert delay to allow video to spool up
    
end


%% Load Movies

if nargin < 1 %look for movies that match subject ID if not provided
    movie_list = rdir(fullfile(fPath,'Videos','*mp4'));
    f_name = cellstr(strvcat(movie_list.name));
    wh_file = strfind(f_name,num2str(SUBID));
    movie_name = f_name{~cellfun(@isempty,wh_file)};
end;

f_exist = which(movie_name);
if f_exist ~= 2
    error('Make sure movie file is a real file on your matlab search path.')
end


% Open the moviefile and query some infos like duration, framerate,
% width and height of video frames. We could also query the total count of frames in
% the movie, but computing 'framecount' takes long, so avoid to query
% this property if you don't need it!
[movie movieduration fps movie_width movie_height] = Screen('OpenMovie', window, movie_name);

% We estimate framecount instead of querying it - faster:
framecount = movieduration * fps;

%% Set up screens

screens = Screen('Screens');
screenNumber = max(screens);

% Configure screen
disp.screenWidth = rect(3);
disp.screenHeight = rect(4);
disp.xcenter = disp.screenWidth/2;
disp.ycenter = disp.screenHeight/2;

%%% create FIXATION screen
disp.fixation.w = Screen('OpenOffscreenWindow',screenNumber);
Screen('FillRect',disp.fixation.w,screenNumber); % paint black
Screen('TextSize',disp.fixation.w,60);
DrawFormattedText(disp.fixation.w,'+','center','center',255); % add text

%% Instructions

switch CONDITION
    case 0
        instruct = 'You will watch a video clip of you and your partner while you are being scanned.\n\nPlease rate how the video makes you feel continously at every moment.\n\nPress ''space'' to continue or ''ESC'' to quit';
    case 1
        instruct = 'You will watch a video clip of you and your partner.\n\nPlease rate how you are feeling in the video continously at every moment.\n\nPress ''space'' to continue or ''ESC'' to quit';
    case 2
        instruct = 'You will watch a video clip of you and your partner.\n\nPlease rate how you think your partner is feeling continously at every moment.\n\nPress ''space'' to continue or ''ESC'' to quit';
end

%% Run Paradigm

try
    % Show instructions...
    Screen('TextSize',window, 36);
    DrawFormattedText(window,instruct,'center','center',255);
    Screen('Flip',window);
    
    % wait for experimenter to press spacebar
    keycode(key.space) = 0;
    while keycode(key.space) == 0
        [presstime keycode delta] = KbWait;
    end
    
    %Wait for Scanner trigger
    if CONDITION == 0 && USE_SCANNER
        DrawFormattedText(window,'Experimenter:  Is the scanner ready?','center','center',255);
        Screen('Flip',window);
        WaitSecs(.2);
        keycode(key.space) = 0;
        while keycode(key.space) == 0
            [presstime keycode delta] = KbWait;
        end
        
        DrawFormattedText(window,'Waiting for trigger from scanner.','center','center',255);
        Screen('Flip',window);
        WaitSecs(.2);
        keycode(key.ttl) = 0;
        while keycode(key.ttl)==0
            [presstime keycode delta] = KbWait;
        end
    else
        DrawFormattedText(window,'Press ''SPACE'' key to begin experiment','center','center',255);
        Screen('Flip',window);
        WaitSecs(.2);
        keycode(key.space) = 0;
        while keycode(key.space) == 0
            [presstime keycode delta] = KbWait;
        end
    end
    
    %%%%BEGIN EXPT
    
    %Start Video Recording
    if USE_VIDEO
        % Start capture -
        %need to figure out how to deal with the initial pause at the beginning.
        % [fps starttime] = Screen('StartVideoCapture', capturePtr [, captureRateFPS=25] [, dropframes=0] [, startAt]);
        [fps t] = Screen('StartVideoCapture', grabber, 30, 0);
    end
    
    if USE_BIOPAC; TriggerBiopac_io32(BIOPAC_PULSE_DUR); end
    
    if USE_EYELINK; Eyelink('Message', 'ttl_start'); end
    
    % put up fixation
    Screen('CopyWindow',disp.fixation.w,window);
    startfix = Screen('Flip',window);
    WaitSecs(STARTFIX);
    
    
    % Start playback of the movie:
    % Play 'movie', at a playbackrate = 1 (normal speed forward),
    % play it once, aka with loopflag = 0,
    % play audio track at volume 1.0  = 100% audio volume.
    if USE_EYELINK; Eyelink('Message', sprintf('R%d_TRIAL_%d', run,Trialnum)); end
    
    Screen('PlayMovie', movie, 1, 0, 1.0);
    
    % Video playback and key response RT collection loop:
    % This loop repeats until either the subject responded with a
    % keypress to indicate s(he) detected the event in the vido, or
    % until the end of the movie is reached.
    movietexture=0;     % Texture handle for the current movie frame.
    lastpts=0;          % Presentation timestamp of last frame.
    onsettime=-1;       % Realtime at which the event was shown to the subject.
    rejecttrial=0;      % Flag which is set to 1 to reject an invalid trial.
    
    while movietexture >= 0
        % Check if a new movie video frame is ready for visual
        % presentation: This call polls for arrival of a new frame. If
        % a new frame is ready, it converts the video frame into a
        % Psychtoolbox texture image and returns a handle in
        % 'movietexture'. 'pts' contains a so called presentation
        % timestamp. That is the time (in seconds since start of movie)
        % at which this video frame should be shown on the screen.
        
        % The 0 - flag means: Don't wait for arrival of new frame, just
        % return a zero or -1 'movietexture' if none is ready.
        [movietexture pts] = Screen('GetMovieImage', window, movie, 0);
        
        % Is it a valid texture?
        if movietexture > 0
            % Yes. Draw the texture into backbuffer:
            Screen('DrawTexture', window, movietexture);
            
            % Flip the display to show the image at next retrace:
            % vbl will contain the exact system time of image onset on
            % screen: This should be accurate in the sub-millisecond
            % range.
            vbl=Screen('Flip', window);
            % Is this the event video frame we've been waiting for?
            if onsettime==-1
                % Yes: This is the first frame with a pts timestamp that is
                % equal or greater than the timeOfEvent, so 'vbl' is
                % the exact time when the event was presented to the
                % subject. Define it as onsettime:
                onsettime = vbl;
                
                % Compare current pts to last one to see if the movie
                % decoder skipped a frame at this crucial point in
                % time. That would invalidate this trial.
                if (pts - lastpts > 1.5*(1/fps))
                    % Difference to last frame is more than 1.5 times
                    % the expected difference under assumption 'no
                    % skip'. We skipped in the wrong moment!
                    rejecttrial=1;
                end;
            end;
            
            % Keep track of the frames pts in order to check for skipped frames:
            lastpts=pts;
            
            % Delete the texture. We don't need it anymore:
            Screen('Close', movietexture);
            movietexture=0;
        end;
        
        %%% Continuous Mouse Ratings
        if CONDITION ~=0
            % Create Rating Lines Bounds
            movie_center = rect/2;
            if doHistory % Rating history below video
                rightb = movie_center(3) + movie_width/2 + 25;
                leftb = rightb - 50;
                ub = movie_center(4) + movie_height/2 + 25;
                lb = ub + 200;
            else % Rating next to video
                leftb = movie_center(3) + movie_width/2 + 25;
                rightb = leftb + 50;
                ub = movie_center(4) - movie_height/2;
                lb = movie_center(4) + movie_height/2;
            end
            
            %Track Mouse coordinate
            t = GetSecs;
            [x,y,buttons] = GetMouse(window);
            if y < ub
                y = ub;
            elseif y > lb
                y = lb;
            end
            position = [position ; x, y, t, (y-lb)/(ub-lb)];
            
            % Text Anchors
            uTextAnchor = 'Positive';
            lTextAnchor = 'Negative';
            
            % Create Rating Lines
            rateLineArray = [leftb rightb leftb rightb leftb+5 rightb-5 (leftb + ((rightb-leftb)/2)) (leftb + ((rightb-leftb)/2)) leftb rightb; ub ub lb lb (ub + ((lb-ub)/2)) (ub + ((lb-ub)/2)) ub lb y y];
            rateColorArray = [255 255 255 255 255 255 255 255 255 255; 255 255 255 255 255 255 255 255 0 0; 255 255 255 255 255 255 255 255 0 0];
            
            %             (lb-ub)/2
            if doHistory % Create Rating history
                
                timeWindow = 20;
                if size(position,1) < fps*timeWindow
                    rateHistoryY = ones(1,fps*timeWindow)*((ub + lb)/2);
                    rateHistoryY(end - size(position,1) + 1:end) = position(:,2);
                else
                    rateHistoryY = position(end-fps*timeWindow + 1:end,2)';
                end
                rateHistory = [leftb - (fps*timeWindow) + 1:leftb; rateHistoryY];
                rateHistoryColor = repmat([30,30,30],size(rateHistory,2),1)';
                Screen('DrawLines',window, [rateLineArray,rateHistory], 4,[rateColorArray,rateHistoryColor]);
            else % No History
                Screen('DrawLines',window, rateLineArray, 4,rateColorArray);
            end
            
            % Add Text Anchors
            Screen('TextFont', window, 'Helvetica Light');
            Screen('TextSize', window, 20);
            DrawFormattedText(window, uTextAnchor, leftb, ub - 25, [255 255 255]);
            DrawFormattedText(window, lTextAnchor, leftb, lb, [255 255 255]);
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Continuous_VideoRating.csv']), [SUBID CONDITION position(end,:)], 'delimiter',',','-append','precision',10)
        end
        
        % Done with drawing. Check the keyboard for subjects response:
        [keyIsDown, secs, keyCode]=KbCheck;
        if (keyIsDown==1)
            % Abort requested?
            if keyCode(esc)
                % This signals abortion:
                rejecttrial=-1;
                % Break out of display loop:
                break;
            end;
        end
        
    end; % ...of display loop...
    
    % Stop movie playback, in case it isn't already stopped. We do this
    % by selection of a playback rate of zero: This will also return
    % the number of frames that had to be dropped to keep audio, video
    % and realtime in sync.
    droppedcount = Screen('PlayMovie', movie, 0, 0, 0);
    if (droppedcount > 0.2*framecount)
        % Over 20% of all frames skipped?!? Playback problems! We
        % reject this trial...
        rejecttrial=4;
    end;
    
    % Close the moviefile.
    Screen('CloseMovie', movie);
    
    % Check if aborted.
    if (rejecttrial==-1)
        % Break out of trial loop
        RETURN;
    end;
    
    % Wait for subject to release keys:
    KbReleaseWait;
    
    %%% Emotion Ratings
    if CONDITION ~= 0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        trial_out(1) = SUBID;
        trial_out(2) = i; % Video Number
        lastt = 2;
        for e = 1:length(emotions)
            [trial_out(lastt + 1) trial_out(lastt + 2) trial_out(lastt + 3) trial_out(lastt + 4)] = GetRating(window, rect, screen, 'txt',emotions{e},'type','line', 'anchor', {'None','A Lot'});
            lastt = lastt + 4;
            
            % Wait for 1 second in between each rating
            Screen('Flip',window);
            WaitSecs(1)
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Append data to file after every trial
        dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '_Trial_VideoRating.csv']), trial_out, 'delimiter',',','-append','precision',10)
    end
    
    %% Done with the experiment. Close onscreen window and finish.
    
    if USE_VIDEO && CONDITION ~= 0
        % Stop capture engine and recording:
        Screen('StopVideoCapture', grabber);
        telapsed = GetSecs - t;
        
        % Close engine and recorded movie file:
        Screen('CloseVideoCapture', grabber);
        
        %Write out timing information
        dlmwrite(fullfile(fPath,'Data',['Video_' num2str(SUBID) '_VideoRating_Timing.txt']),[telapsed,fps])
    end
    
    if USE_EYELINK
        % STEP 8
        % End of Experiment; close the file first
        % close graphics window, close data file and shut down tracker
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.5);
        Eyelink('CloseFile');
        % download data file
        try
            fprintf('Receiving data file ''%s''\n', edfFile );
            status=Eyelink('ReceiveFile');
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if 2==exist(edfFile, 'file')
                fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
            end
        catch
            fprintf('Problem receiving data file ''%s''\n', edfFile );
        end
        % STEP 9
        % cleanup;
        % function cleanup
        Eyelink('Shutdown');
    end
    
    ShowCursor;
    Screen('CloseAll');
    fprintf('Done. Thanks!\n');
    return;
catch %#ok<CTCH>
    % Error handling: Close all windows and movies, release all ressources.
    sca;
    psychrethrow(psychlasterror);
end;

