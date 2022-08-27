% (C) Copyright 2022 ALICE VAN AUDENHAEGE

clear;
clc;

more off;

cfg = configuration();

%% Constants

expName = 'LipSpeechMVPA';

% variables to build block / trial loops
% (nReps = will be defined by input)
% num of different blocks (= different acquisition runs) per rep --> one per modality
nBlocks = 2;
% per block: 3 cons x 3 vow x 3 speakers
nTrials = 27;
if cfg.debug.do
    nTrials = 3;
end

auditoryCond = 1;
visualCond = 2;

% for the frame loop (videos - visual stimuli)
vidDuration = 2;
videoFrameRate = 25;  %% OR 24.98 ????
% total num of frames in a whole video (videos of 2sec * 25frames per sec)
nFrames = videoFrameRate * vidDuration;

% stimXsize = 1920; % never used
% stimYsize = 1080; % never used

%% User input
cfg.subject.subjectNb = num2str(input('SUBJECT NUMBER :'));
cfg.subject.sessionNb = num2str(input('SESSION NUMBER :'));

% if set to 'mri' then the data will be saved in the `func` folder
cfg.testingDevice = 'mri';

cfg.dir.outputSubject = fullfile(cfg.dir.output, ...
                                 ['sub-' cfg.subject.subjectNb], ...
                                 ['ses-' cfg.subject.sessionNb], 'func');

nReps = input('NUMBER OF REPETITIONS :');
% if no value is supplied, do 10 reps
if isempty(nReps)
    nReps = 10;
end

% define order of modalities within a subject
% modality orded will be fixed within participant, and balanced across %
% 1 = auditory,
% 2 = visual
firstCondition = input('START WITH MODALITY ... ? (AUD=1 or VIS=2) :');

if firstCondition == 1
    secondCondition = 2;
elseif firstCondition == 2
    secondCondition = 1;
else % if error while encoding firstCondition, exp will start with AUD MODALITY
    firstCondition = 1;
    secondCondition = 2;
end

orderCondVector = [firstCondition, secondCondition];

%% Add target trials

% vector with # of blocks per condition
% (if 5 reps, you have 5 blocks for each condition)
blockPerCond = 1:nReps;

% I want 10% of my trials (t=27) to be targets
% I will have 2 or 3 targets per block (adds 10 or 15 sec (max 15) per block) -->
% duration of the blocks = 150s = 2min30

% VISUAL
% randomly select half of the blocks to have 2 1-back stimuli for the audio
tmp = randperm(nReps);
twoBackBlocksVisual = tmp(1:round(nReps / 2));
% remaining half will have 3 1-back stimulus %
threeBackBlocksVisual = setdiff(blockPerCond, twoBackBlocksVisual);

% AUDIO
% randomly select half of the blocks to have 2 1-back stimuli for the audio
tmp = randperm(nReps);
twoBackBlocksAudio = tmp(1:round(nReps / 2));
% remaining half will have 3 1-back stimulus %
threeBackBlocksAudio = setdiff(blockPerCond, twoBackBlocksAudio);

clear tmp;

%% Load stimuli
talkToMe(cfg, 'Load stimuli:');
% time stamp as the experiment starts
expStart = GetSecs;

% to keep track of stimuli
myExpTrials = struct;

talkToMe(cfg, '\n visual');
stimuliMatFile = fullfile(cfg.dir.root, 'stimuli', 'stimuli.mat');
if ~exist(stimuliMatFile, 'file')
    saveStimuliAsMat();
end
load(stimuliMatFile, 'myVidStructArray');
stimNames = fieldnames(myVidStructArray);

talkToMe(cfg, '\n audio');
for t = 1:length(stimNames)
    myExpTrials(t).stimulusname = stimNames{t};
    myExpTrials(t).visualstimuli = myVidStructArray.(stimNames{t});
    myExpTrials(t).syllable = myVidStructArray.(stimNames{t}).syllable;
    [myExpTrials(t).audy, myExpTrials(t).audfreq] = audioread(fullfile(cfg.dir.stimuli, ...
                                                                       [myExpTrials(t).stimulusname '.wav']));
    myExpTrials(t).wavedata = myExpTrials(t).audy';
    myExpTrials(t).nrchannels = size(myExpTrials(t).wavedata, 1);
    myExpTrials(t).trialtype = 0; % will be 1 if trial is a target
end

try

    if cfg.debug.do
        PsychDebugWindowConfiguration;
    end

    % This sets a PTB preference to possibly skip some timing tests:
    % a value of 0 runs these tests, and a value of 1 inhibits them.
    % This should always be set to 0 for actual experiments
    if cfg.debug.do
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'Verbosity', 0);
        % disable all visual alerts
        Screen('Preference', 'VisualDebugLevel', 0);
        % disable all output to the command window
        Screen('Preference', 'SuppressAllWarnings', 1);
    else
        Screen('Preference', 'SkipSyncTests', 0);
    end

    %% INITIALIZE SCREEN AND START THE STIMULI PRESENTATION

    % basic setup checking
    AssertOpenGL;

    % define default font size for all text uses (i.e. DrawFormattedText fuction)
    Screen('Preference', 'DefaultFontSize', 32);

    % all the possible screens.
    % Use max(screenVector) to display on external screen.
    screenVector = Screen('Screens');

    % EXT screen / FULL window
    % [Win, screenRect] = Screen('OpenWindow', max(screenVector), cfg.color.bgColor, []);
    % MAIN screen / FULL window
    [Win, screenRect] = Screen('OpenWindow', 0, cfg.color.bgColor, []);

    cfg.win = Win;

    % estimate the monitor flip interval for the onscreen window
    interFrameInterval = Screen('GetFlipInterval', Win); % in seconds

    % timings in my trial sequence
    % (substract interFrameInterval/3 to make sure that flipping is done
    % at 3sec straight and not 1 frame later)
    ISI = 3 - interFrameInterval / 6;
    frameDuration = 1 / videoFrameRate - interFrameInterval / 6;

    % get width and height of the screen
    [widthWin, heightWin] = Screen('WindowSize', Win);
    widthDis = Screen('DisplaySize', max(screenVector)); % size in mm of the screen

    % give maximum priority to psychtoolbox for anything happening on this machine
    Priority(MaxPriority(Win));

    setUpRand();

    % HideCursor(Win);

    % Listening enabled and any output of keypresses
    % to Matlabs windows is suppressed (see ref. page for ListenChar)
    ListenChar(2);
    KbName('UnifyKeyNames');

    talkToMe(cfg, 'turning images into textures.\n');
    for iStim = 1:numel(stimNames)
        thisStime = stimNames{iStim};
        for iFrame = 1:numel(myVidStructArray.(thisStime))
            myVidStructArray.(thisStime)(iFrame).duration = frameDuration;  %#ok<*SAGROW>
            myVidStructArray.(thisStime)(iFrame).imageTexture = Screen('MakeTexture', ...
                                                                       Win, ...
                                                                       myVidStructArray.(thisStime)(iFrame).stimImage);
        end
    end
    % add textures to myExpTrials structure
    for t = 1:length(stimNames)
        myExpTrials(t).visualstimuli = myVidStructArray.(stimNames{t});
    end
    talkToMe(cfg, sprintf('Done.\nTime for preparation : %0.1f sec.\n', GetSecs - expStart));

    % draw black rect for audio-only presentation
    blackScreen = Screen('MakeTexture', Win, cfg.color.black);

    %% BLOCK AND TRIAL LOOP
    % for sound to be used: perform basic initialization of the sound driver
    InitializePsychSound(1);

    % Repetition loop
    for rep = 1:nReps

        cfg.subject.runNb = rep;

        %     % check on participant every 3 blocks
        %     if rep > 1
        %         DrawFormattedText(Win, 'Ready to continue?', 'center', 'center', cfg.color.text);
        %         Screen('Flip', Win);
        %         waitForKb('space');
        %     end

        % define an index (v) number of one-back trials (2 or 3) in the block,
        % depending on the VISUAL blocks we are in
        if ismember(rep, twoBackBlocksVisual)
            v = 2;
        elseif ismember(rep, threeBackBlocksVisual)
            v = 3;
        end
        % same index but for AUDIO blocks (w)
        if ismember(rep, twoBackBlocksAudio)
            w = 2;
        elseif ismember(rep, threeBackBlocksAudio)
            w = 3;
        end

        % and choose randomly which trial will be repeated in this block (if any)
        backTrialsVisual = sort(randperm(27, v));
        backTrialsAudio = sort(randperm(27, w));

        % blocks correspond to modality, so each 'rep' has 2 blocks = 2 acquisition runs
        for block = 1:nBlocks

            DrawFormattedText(Win, cfg.color.instructions, ...
                              'center', 'center', ...
                              cfg.color.text);
            Screen('Flip', Win);

            blockModality = orderCondVector(block);
            if blockModality == visualCond
                r = v;
                backTrials = backTrialsVisual;
                modality = 'vis';
            elseif blockModality == auditoryCond
                r = w;
                backTrials = backTrialsAudio;
                modality = 'aud';
            end

            % Set up output file for current run (1 BLOCK = 1 ACQUISITION RUN)
            cfg.task.name = [expName modality];
            cfg = createFilename(cfg);
            dataFileName = fullfile(cfg.outputDir, cfg.fileName.event);

            % open/create file and create header
            % 'a'== PERMISSION: open or create file for writing; append data to end of file
            fid = fopen(dataFileName, 'a');
            % data header
            header = {'onset', ...
                      'duration', ...
                      'trial_number', ...
                      'stim_name', ...
                      'bloc', ...
                      'modality', ...
                      'repetition', ...
                      'actor', ...
                      'consonant', ...
                      'vowel', 'target'...,
                      'keypress_number', ...
                      'responsekey', ...
                      'keypress_time'};
            header = strjoin(header, '\t');
            fprintf(fid, [header, '\n']);
            fclose(fid);

            % Pseudorandomization made based on syllable vector for the faces
            [~, pseudoSyllIndex] = pseudorandptb(cfg.stimSyll);
            for ind = 1:length(cfg.stimSyll)
                myExpTrials(pseudoSyllIndex(ind)).pseudorandindex = ind;
            end

            % turn struct into table to reorder it
            tableexptrials = struct2table(myExpTrials);
            pseudorandtabletrials = sortrows(tableexptrials, 'pseudorandindex');

            % convert into structure to use in the trial/ stimui loop below
            pseudorandExpTrials = table2struct(pseudorandtabletrials);

            % add 1-back trials for current block type %
            pseudoRandExpTrialsBack = pseudorandExpTrials;
            for b = 1:(length(cfg.stimSyll) + r)
                if r == 2
                    if b <= backTrials(1)
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b);

                        % this trial will be a target
                        % (repetition of the previous syllable - different actor)
                    elseif b == backTrials(1) + 1
                        % find where the same-syll-different-actor rows are %
                        syllVector = {pseudorandExpTrials.syllable};
                        syllRepeated = {pseudorandExpTrials(backTrials(1)).syllable};
                        syllTF = ismember(syllVector, syllRepeated);
                        syllIndices = find(syllTF);
                        syllIndices(syllIndices == (b - 1)) = []; % get rid of current actor
                        % and choose randomly among the others
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(randsample(syllIndices, 1));
                        % add 1 in trialtype column
                        pseudoRandExpTrialsBack(b).trialtype = 1;

                        % this trial will have a repeated emotion but a different actor
                    elseif b == backTrials(2) + 2
                        % find where the same-emotion-different-actor rows are %
                        syllVector = {pseudorandExpTrials.syllable};
                        syllRepeated = {pseudorandExpTrials(backTrials(2)).syllable};
                        syllTF = ismember(syllVector, syllRepeated);
                        syllIndices = find(syllTF);
                        syllIndices(syllIndices == b - 2) = []; % get rid of current actor
                        % and choose randomly among the others
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(randsample(syllIndices, 1));
                        % add 1 in trialtype column
                        pseudoRandExpTrialsBack(b).trialtype = 1;

                    elseif b > backTrials(1) + 1 && b < backTrials(2) + 2
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b - 1);

                    elseif b > backTrials(2) + 2
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b - 2);

                    end

                elseif r == 3
                    if b <= backTrials(1)
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b);

                        % this trial will be a target (repetition of the previous syllable - different actor)
                    elseif b == backTrials(1) + 1
                        % find where the same-syll-different-actor rows are %
                        syllVector = {pseudorandExpTrials.syllable};
                        syllRepeated = {pseudorandExpTrials(backTrials(1)).syllable};
                        syllTF = ismember(syllVector, syllRepeated);
                        syllIndices = find(syllTF);
                        syllIndices(syllIndices == (b - 1)) = []; % get rid of current actor
                        % and choose randomly among the others
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(randsample(syllIndices, 1));
                        % add 1 in trialtype column
                        pseudoRandExpTrialsBack(b).trialtype = 1;

                        % this trial will have a repeated emotion but a different actor
                    elseif b == backTrials(2) + 2
                        % find where the same-emotion-different-actor rows are %
                        syllVector = {pseudorandExpTrials.syllable};
                        syllRepeated = {pseudorandExpTrials(backTrials(2)).syllable};
                        syllTF = ismember(syllVector, syllRepeated);
                        syllIndices = find(syllTF);
                        syllIndices(syllIndices == b - 2) = []; % get rid of current actor
                        % and choose randomly among the others
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(randsample(syllIndices, 1));
                        % add 1 in trialtype column
                        pseudoRandExpTrialsBack(b).trialtype = 1;

                        % this trial will have a repeated emotion but a different actor
                    elseif b == backTrials(3) + 3
                        % find where the same-emotion-different-actor rows are %
                        syllVector = {pseudorandExpTrials.syllable};
                        syllRepeated = {pseudorandExpTrials(backTrials(3)).syllable};
                        syllTF = ismember(syllVector, syllRepeated);
                        syllIndices = find(syllTF);
                        syllIndices(syllIndices == b - 3) = []; % get rid of current actor
                        % and choose randomly among the others
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(randsample(syllIndices, 1));
                        % add 1 in trialtype column
                        pseudoRandExpTrialsBack(b).trialtype = 1;

                    elseif b > backTrials(1) + 1 && b < backTrials(2) + 2
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b - 1);

                    elseif b > backTrials(2) + 2 && b < backTrials(3) + 3
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b - 2);

                    elseif b > backTrials(3) + 3
                        pseudoRandExpTrialsBack(b) = pseudorandExpTrials(b - 3);

                    end
                end
            end

            % % %    STEFANIAS BIT OF CODE         %% TRIGGER
            % % %     Screen('TextSize', wPtr, 50);%text size
            % % %     DrawFormattedText(wPtr, '\n READY TO START \n \n - Detectez les images repetees - ',
            %%        ['center'],['center'],[0 0 0]);
            % % %     Screen('Flip', wPtr);
            % % %
            % % %     waitForTrigger(cfg); %this calls the function from CPP github

            % Each Block is for the scanner a new run so the first 3 volumes get discarded each time %
            % trigger

            fprintf('WAITING FOR TRIGGER (- instructions displayed on the screen) \n'); % fb in command window
            % waitForTrigger(cfg);
            % waitForTrigger(cfg, -1);
            triggerCounter = 0;
            while triggerCounter < cfg.numTriggers

                keyCode = [];

                [~, keyCode] = KbPressWait;

                if strcmp(KbName(keyCode), 's')

                    triggerCounter = triggerCounter + 1;

                    % msg = sprintf(' Trigger %i', triggerCounter);
                    msg = ['The session will start in', ...
                           num2str(cfg.numTriggers - triggerCounter), '...'];

                    %                 talkToMe(cfg, msg);

                    %                 % we only wait if this is not the last trigger
                    %                 if triggerCounter < cfg.numTriggers
                    %                     pauseBetweenTriggers(cfg);
                    %                 end

                end
            end

            blockStart = GetSecs;
            disp(strcat('Number of targets in coming trial :', num2str(r)));

            for trial = 1:(nTrials + r)

                % start queuing for triggers and subject's keypresses (flush previous queue) %
                KbQueue('flush');
                % keep 's' in the allowed keys ???? OR WILL MESS UP WITH THE TRIGGER ??
                KbQueue('start', {'s', 'd', 'space'});

                % which kind of block is it? Stimulus presentation changes based on modality %

                %% visual
                if blockModality == visualCond

                    if trial == 1
                        DrawFormattedText(Win, 'Faites attention aux LEVRES', 'center', 'center', cfg.color.text);
                        Screen('Flip', Win);
                        WaitSecs(0.5);
                    end

                    lastEventTime = GetSecs;

                    % frames presentation loop
                    for f = 1:nFrames

                        % time stamp to measure stimulus duration on screen
                        if f == 1
                            stimStart = GetSecs;
                        end

                        Screen('DrawTexture', Win, pseudoRandExpTrialsBack(trial).visualstimuli(f).imageTexture, [], [], 0);
                        [vbl, ~, lastEventTime, missed] = Screen('Flip', Win, lastEventTime + frameDuration);
                    end

                    stimEnd = GetSecs;

                    % clear last frame
                    Screen('FillRect', Win, cfg.color.bgColor);

                    % ISI
                    [~, ~, ISIend] = Screen('Flip', Win, stimEnd + ISI);
                    % fb about duration in cw
                    disp(strcat('Timing trial  ', num2str(trial), ...
                                '- the duration was :', num2str(stimEnd - stimStart), ' sec'));
                    % fb about duration in cw
                    disp(strcat('Timing ISI - the duration was :', num2str(ISIend - stimEnd), ' sec'));

                    %% auditory
                elseif blockModality == auditoryCond

                    if trial == 1
                        DrawFormattedText(Win, 'Faites attention aux VOIX', 'center', 'center', cfg.color.text);
                        Screen('Flip', Win);
                        WaitSecs(0.5);
                        % clear instructions from screen
                        Screen('FillRect', Win, cfg.color.bgColor);
                        [~, ~, lastEventTime] = Screen('Flip', Win);
                    end

                    if pseudoRandExpTrialsBack(trial).nrchannels < 2
                        wavedata = pseudoRandExpTrialsBack(trial).wavedata;
                        nrchannels = 2;
                    elseif pseudoRandExpTrialsBack(trial).nrchannels == 2
                        wavedata = pseudoRandExpTrialsBack(trial).wavedata;
                        nrchannels = pseudoRandExpTrialsBack(trial).nrchannels;
                    end

                    try
                        % Try with the 'freq'uency we wanted:
                        pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
                    catch
                        % Failed. Retry with default frequency as suggested by device:

                        psychlasterror('reset');
                        pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
                    end

                    % Fill the audio playback buffer with the audio data 'wavedata':
                    PsychPortAudio('FillBuffer', pahandle, wavedata);

                    % Start audio playback for 'repetitions' repetitions of the sound data,
                    % start it immediately (0) and wait for the playback to start, return onset
                    % timestamp.
                    stimStart = GetSecs;
                    PsychPortAudio('Start', pahandle, 1, 0, 1);

                    %   % Stay in a little loop for the file duration:
                    %   % use frames presentation loop to get the same duration as in the visual condition%
                    %   for f = 1:nFrames
                    %
                    %   Screen('DrawTexture', Win, blackScreen, [], [], 0);
                    %   [~, ~, lastEventTime] = Screen('Flip', Win, lastEventTime+frameDuration);
                    %
                    %   end

                    WaitSecs(2);

                    % Stop playback:
                    [~, ~, ~, stimEnd] = PsychPortAudio('Stop', pahandle);
                    % PsychPortAudio('Stop', pahandle);

                    % Close the audio device:
                    PsychPortAudio('Close', pahandle);

                    % clear stimulus from screen
                    Screen('Flip', Win);
                    [~, ~, ISIend] = Screen('Flip', Win, stimEnd + ISI);

                    % fb about duration in cw
                    disp(strcat('Timing trial ', num2str(trial), '- duration was :', ...
                                num2str(stimEnd - stimStart), ' sec'));
                    % fb about duration in cw
                    disp(strcat('Timing ISI - duration was :', num2str(ISIend - stimEnd), ' sec'));

                end

                % SAVE DATA TO THE OUTPUT FILE

                % get keypresses during this trial
                % 1 column per keypress; row 1 = keyCode, row 2 = time.
                pressCodeTime = KbQueue('stop', expStart);
                pCTSize = size(pressCodeTime);
                % get number of columns = number of keypress
                howManyPress = pCTSize(2);
                if howManyPress == 0
                    keyName = '';
                    keyTime = 0;
                else
                    % get name of the first key pressed (1st row, 1st col)
                    keyName = KbName(pressCodeTime(1, 1));
                    % get time of the first key (2nd row, 1st col)
                    keyTime = pressCodeTime(2, 1);
                end

                % write in the output file

                % header was defined previously as :
                fid = fopen(dataFileName, 'a');
                fprintf(fid, '%.3f\t%.3f\t%d\t%s\t%d\t%s\t%d\t%s\t%s\t%s\t%d\t%d\t%s\t%.3f\n', ...
                        stimStart - expStart, ...
                        stimEnd - stimStart, ...
                        trial, ...
                        pseudoRandExpTrialsBack(trial).stimulusname, ...
                        block, ...
                        modality, ...
                        rep, ...
                        pseudoRandExpTrialsBack(trial).actor, ...
                        pseudoRandExpTrialsBack(trial).syllable(1), ...
                        pseudoRandExpTrialsBack(trial).syllable(2), ...
                        pseudoRandExpTrialsBack(trial).trialtype, ...
                        howManyPress, ...
                        keyName, ...
                        keyTime);
                fclose(fid);

            end

            blockEnd = GetSecs;
            blockDur = blockEnd - blockStart;
            disp(strcat('Total block duration  ', num2str(blockDur)));
            fprintf('Press SPACE to launch the next block & start waiting for trigger\n');

            KbQueue('wait', 'space');
            % waitForKb('space', -3); ?? not working ..

        end

    end

    DrawFormattedText(Win, 'Fin de l''experience :)\nMERCI !', 'center', 'center', cfg.color.text);
    Screen('Flip', Win);
    expEnd = GetSecs;
    disp(strcat('Experiment duration: ', num2str((expEnd - expStart) / 60), ' \n Press SPACE to end'));
    KbQueue('flush');
    KbQueue('wait', 'space');
    ListenChar(0);
    ShowCursor;
    sca;

catch ME
    ListenChar(0);
    ShowCursor;
    sca;

    rethrow(ME);
end
