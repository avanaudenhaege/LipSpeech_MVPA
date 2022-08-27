% (C) Copyright 2022 ALICE VAN AUDENHAEGE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Stimulation for functional runs of fMRI design  %%%
%%%   programmer: Federica Falagiarda October 2019   %%%
%%%   ADAPTED BY ALICE VAN AUDENHAEGE - August 2022  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Once fully run, this script has given a txt output file per block (= per acquisition run)%

%% BLOCK DESCRIPTION
% There are 9 possible syllables portrayed by 3 speakers
% SYL: F P L * A I E
% speakers : GH (=S2), JB (=S3), AV (=S1)
% TOTAL stim per block = 27 stims

% Possible modality for each block (n = 2) :
% - visual (lipreading) or
% - auditory (speech).
% The order of presentation of modalities is fixed within participant
% but varies across.
% It is defined manually at the begining of the script (orderCondVector).

% 1 block = 1 acquisition run = 1 modality.
% The scanner will be relaunched after each run.
% The script waits for the trigger (????? A CONFIRMER) to start the next block.

% Time calculation for each run/block :
% 27 stim + 2 or 3 targets
% trial duration = 2s stim + 3s ISI = 5s
% block/run duration = (27 x 5s) + (2 or 3 targets x 5s) = 145 or 150s

%% REPETITIONS
% A repetition consists of 2 blocks, 1 of each modality (visual and auditory).
% The number of repetition desired (nReps) is asked
% at the begining of the script (ideally 18-20 reps in total, over 2 sessions).

%% TASK
% One-back task
% The participant is asked to press a button when he/she sees a repeated
% syllable, independantly of the actor.
% This is to force the participant to attend each syllable that is presented
% (consonant AND vowel).

clear;
sca;
clc;

cfg = configuration();

% add supporting functions to the path
addpath(genpath(fullfile(cfg.rootDir, 'supporting_functions')));
addpath(fullfile(cfg.rootDir, 'lib', 'bids-matlab'));

expName = 'LipSpeechMVPA';

%% VARIABLE SETTINGS

% time stamp as the experiment starts
expStart = GetSecs;

% colors
white = 255;
black = 0;
midgrey = [127 127 127];
bgColor = black;
fixColor = black;
textColor = white;

% variables to build block / trial loops
% (nReps = will be defined by input)
nBlocks = 2; % num of different blocks (= different acquisition runs) per rep --> one per modality
nTrials = 27; % per block: 3 cons x 3 vow x 3 speakers

auditoryCond = 1;
visualCond = 2;

% for the frame loop (videos - visual stimuli)
vidDuration = 2;
videoFrameRate = 25;  %% OR 24.98 ????
% total num of frames in a whole video (videos of 2sec * 25frames per sec)
nFrames = videoFrameRate * vidDuration;
stimXsize = 1920;
stimYsize = 1080;

% input info
subjNumber = input('SUBJECT NUMBER :');
sesNumber = input('SESSION NUMBER :');

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

%% ADD TARGET TRIALS
% vector with # of blocks per condition
% (if 5 reps, you have 5 blocks for each condition)
blockPerCond = 1:nReps;

% I want 10% of my trials (t=27) to be targets
% I will have 2 or 3 targets per block (adds 10 or 15 sec (max 15) per block) -->
% duration of the blocks = 150s = 2min30

%% AUDIO
% randomly select half of the blocks to have 2 1-back stimuli for the audio %
twoBackBlocksAudio = datasample(blockPerCond, round(nReps / 2), 'Replace', false);
% remaining half will have 3 1-back stimulus %
threeBackBlocksAudio = setdiff(blockPerCond, twoBackBlocksAudio);

%% VISUAL
% randomly select half of the blocks to have 2 1-back stimuli for the audio %
twoBackBlocksVisual = datasample(blockPerCond, round(nReps / 2), 'Replace', false);
% remaining half will have 3 1-back stimulus %
threeBackBlocksVisual = setdiff(blockPerCond, twoBackBlocksVisual);

stimuliMatFile = fullfile(cfg.rootDir, 'stimuli', 'stimuli.mat');
if ~exist(stimuliMatFile, 'file')
    saveStimuliAsMat()
end
load(stimuliMatFile, 'myVidStructArray');

try

    PsychDebugWindowConfiguration;

    % This sets a PTB preference to possibly skip some timing tests:
    % a value of 0 runs these tests, and a value of 1 inhibits them.
    % This should always be set to 0 for actual experiments
    Screen('Preference', 'SkipSyncTests', 1);

    %% INITIALIZE SCREEN AND START THE STIMULI PRESENTATION

    % basic setup checking
    AssertOpenGL;

    % define default font size for all text uses (i.e. DrawFormattedText fuction)
    Screen('Preference', 'DefaultFontSize', 32);

    % all the possible screens.
    % Use max(screenVector) to display on external screen.
    screenVector = Screen('Screens');

    % EXT screen / FULL window
    [Win, screenRect] = Screen('OpenWindow', max(screenVector), bgColor, []);
    % MAIN screen / FULL window
    % [Win, screenRect] = Screen('OpenWindow', 0, bgColor, []);

    % estimate the monitor flip interval for the onscreen window
    interFrameInterval = Screen('GetFlipInterval', Win); % in seconds
    msInterFrameInterval = interFrameInterval * 1000; % in ms

    % timings in my trial sequence
    % (substract interFrameInterval/3 to make sure that flipping is done at 3sec straight and not 1 frame later)
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

    %% CREATING THE VISUAL STIMULI (videos from png frames) %%
    frameNum = (1:nFrames);
    % (S1 = AV, S2 = GH, S3 = JB)
    actor = {'S1', 'S2', 'S3'};
    syllable = {'pa', 'pi', 'pe', 'fa', 'fi', 'fe', 'la', 'li', 'le'};

    stimActors = [repmat({'S1'}, 1, 9), repmat({'S2'}, 1, 9), repmat({'S3'}, 1, 9)];
    stimSyll = repmat({'pa', 'pi', 'pe', 'fa', 'fi', 'fe', 'la', 'li', 'le'}, 1, 3);
    stimName = strcat(stimActors, stimSyll);
    nStim = length(stimName);

    % allFrameNames = cell(nFrames, nStim);
    % c = 1;
    % for a = 1:length(actor)
    %     for s = 1:length(syllable)
    %         for f = 1:length(frameNum)
    %             allFrameNames{f, c} = {[actor{a} syllable{s} num2str(frameNum(f))]};
    %         end
    %         c = c + 1;
    %     end
    % end

    % Build one structure per "video"

    % stimuli_path = fullfile(this_directory, 'stimuli');

    % feedback in command window
    % fprintf('Preparing frame structures for each video \n');

    % S1paStruct = struct;
    % S1paStruct = buildFramesStruct(Win, S1paStruct, nFrames, frameDuration, allFrameNames(:, 1), stimuli_path);
    % S1piStruct = struct;
    % S1piStruct = buildFramesStruct(Win, S1piStruct, nFrames, frameDuration, allFrameNames(:, 2), stimuli_path);
    % S1peStruct = struct;
    % S1peStruct = buildFramesStruct(Win, S1peStruct, nFrames, frameDuration, allFrameNames(:, 3), stimuli_path);

    % S1faStruct = struct;
    % S1faStruct = buildFramesStruct(Win, S1faStruct, nFrames, frameDuration, allFrameNames(:, 4), stimuli_path);
    % S1fiStruct = struct;
    % S1fiStruct = buildFramesStruct(Win, S1fiStruct, nFrames, frameDuration, allFrameNames(:, 5), stimuli_path);
    % S1feStruct = struct;
    % S1feStruct = buildFramesStruct(Win, S1feStruct, nFrames, frameDuration, allFrameNames(:, 6), stimuli_path);

    % S1laStruct = struct;
    % S1laStruct = buildFramesStruct(Win, S1laStruct, nFrames, frameDuration, allFrameNames(:, 7), stimuli_path);
    % S1liStruct = struct;
    % S1liStruct = buildFramesStruct(Win, S1liStruct, nFrames, frameDuration, allFrameNames(:, 8), stimuli_path);
    % S1leStruct = struct;
    % S1leStruct = buildFramesStruct(Win, S1leStruct, nFrames, frameDuration, allFrameNames(:, 9), stimuli_path);

    % S2paStruct = struct;
    % S2paStruct = buildFramesStruct(Win, S2paStruct, nFrames, frameDuration, allFrameNames(:, 10), stimuli_path);
    % S2piStruct = struct;
    % S2piStruct = buildFramesStruct(Win, S2piStruct, nFrames, frameDuration, allFrameNames(:, 11), stimuli_path);
    % S2peStruct = struct;
    % S2peStruct = buildFramesStruct(Win, S2peStruct, nFrames, frameDuration, allFrameNames(:, 12), stimuli_path);

    % S2faStruct = struct;
    % S2faStruct = buildFramesStruct(Win, S2faStruct, nFrames, frameDuration, allFrameNames(:, 13), stimuli_path);
    % S2fiStruct = struct;
    % S2fiStruct = buildFramesStruct(Win, S2fiStruct, nFrames, frameDuration, allFrameNames(:, 14), stimuli_path);
    % S2feStruct = struct;
    % S2feStruct = buildFramesStruct(Win, S2feStruct, nFrames, frameDuration, allFrameNames(:, 15), stimuli_path);

    % S2laStruct = struct;
    % S2laStruct = buildFramesStruct(Win, S2laStruct, nFrames, frameDuration, allFrameNames(:, 16), stimuli_path);
    % S2liStruct = struct;
    % S2liStruct = buildFramesStruct(Win, S2liStruct, nFrames, frameDuration, allFrameNames(:, 17), stimuli_path);
    % S2leStruct = struct;
    % S2leStruct = buildFramesStruct(Win, S2leStruct, nFrames, frameDuration, allFrameNames(:, 18), stimuli_path);

    % S3paStruct = struct;
    % S3paStruct = buildFramesStruct(Win, S3paStruct, nFrames, frameDuration, allFrameNames(:, 19), stimuli_path);
    % S3piStruct = struct;
    % S3piStruct = buildFramesStruct(Win, S3piStruct, nFrames, frameDuration, allFrameNames(:, 20), stimuli_path);
    % S3peStruct = struct;
    % S3peStruct = buildFramesStruct(Win, S3peStruct, nFrames, frameDuration, allFrameNames(:, 21), stimuli_path);

    % S3faStruct = struct;
    % S3faStruct = buildFramesStruct(Win, S3faStruct, nFrames, frameDuration, allFrameNames(:, 22), stimuli_path);
    % S3fiStruct = struct;
    % S3fiStruct = buildFramesStruct(Win, S3fiStruct, nFrames, frameDuration, allFrameNames(:, 23), stimuli_path);
    % S3feStruct = struct;
    % S3feStruct = buildFramesStruct(Win, S3feStruct, nFrames, frameDuration, allFrameNames(:, 24), stimuli_path);

    % S3laStruct = struct;
    % S3laStruct = buildFramesStruct(Win, S3laStruct, nFrames, frameDuration, allFrameNames(:, 25), stimuli_path);
    % S3liStruct = struct;
    % S3liStruct = buildFramesStruct(Win, S3liStruct, nFrames, frameDuration, allFrameNames(:, 26), stimuli_path);
    % S3leStruct = struct;
    % S3leStruct = buildFramesStruct(Win, S3leStruct, nFrames, frameDuration, allFrameNames(:, 27), stimuli_path);

    % put them all together
    % myVidStructArray = {S1paStruct, ...
    %                     S1piStruct, ...
    %                     S1peStruct, ...
    %                     S1faStruct, ...
    %                     S1fiStruct, ...
    %                     S1feStruct, ...
    %                     S1laStruct, ...
    %                     S1liStruct, ...
    %                     S1leStruct, ...
    %                     S2paStruct, ...
    %                     S2piStruct, ...
    %                     S2peStruct, ...
    %                     S2faStruct, ...
    %                     S2fiStruct, ...
    %                     S2feStruct, ...
    %                     S2laStruct, ...
    %                     S2liStruct, ...
    %                     S2leStruct, ...
    %                     S3paStruct, ...
    %                     S3piStruct, ...
    %                     S3peStruct, ...
    %                     S3faStruct, ...
    %                     S3fiStruct, ...
    %                     S3feStruct, ...
    %                     S3laStruct, ...
    %                     S3liStruct, ...
    %                     S3leStruct};
    for iStim = 1:numel(myVidStructArray)
        for i = 1:numel(myVidStructArray{iStim})
            myVidStructArray{iStim}(i).duration = frameDuration
            myVidStructArray{iStim}(i).duration = Screen('MakeTexture', mainWindow, myVidStructArray{iStim}(i).stimImage);
        end
    end                      

    prepEnd = GetSecs;
    % fb in command window
    fprintf('Frame structures ready \n');
    disp(strcat('Time for preparation : ', num2str(prepEnd - expStart), ' sec'));
    %% CREATING AUDITORY STIMULI

    %% Read everything into a structure
    % preallocate
    myExpTrials = struct;
    % for the experiment
    for t = 1:length(stimName)
        myExpTrials(t).stimulusname = stimName{t};
        myExpTrials(t).visualstimuli = myVidStructArray.(stimName{t});
        [myExpTrials(t).audy, myExpTrials(t).audfreq] = audioread(fullfile(stimuli_path, [myExpTrials(t).stimulusname '.wav']));
        myExpTrials(t).wavedata = myExpTrials(t).audy';
        myExpTrials(t).nrchannels = size(myExpTrials(t).wavedata, 1);
        myExpTrials(t).syllable = stimSyll(t);
        myExpTrials(t).actor = stimActors(t);
        myExpTrials(t).trialtype = 0; % col that will be filled with 1 if trial is a target
    end

    % draw black rect for audio-only presentation
    blackScreen = Screen('MakeTexture', Win, black);




    %% BLOCK AND TRIAL LOOP
    % for sound to be used: perform basic initialization of the sound driver
    InitializePsychSound(1);

    % Repetition loop
    for rep = 1:nReps

        %     % check on participant every 3 blocks
        %     if rep > 1
        %         DrawFormattedText(Win, 'Ready to continue?', 'center', 'center', textColor);
        %         Screen('Flip', Win);
        %         waitForKb('space');
        %     end

        % define an index (v) number of one-back trials (2 or 3) in the block, depending on the VISUAL blocks we are in%
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

            DrawFormattedText(Win, 'TACHE\n Appuyez quand une syllabe est repetee deux fois d''affilee', ...
                              'center', 'center', textColor);
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

            % Set up output file for current run (1 BLOCK = 1 ACQUISITION RUN) %
            dataFileName = [cd, '/data/subj', num2str(subjNumber), ...
                            '_ses-0', num2str(sesNumber), ...
                            '_task-', expName,  ...
                            '_rep-' num2str(rep), ...
                            '_block-' num2str(block), ...
                            '_' modality '_events.tsv'];

            % open/create file and create header
            fid = fopen(dataFileName, 'a'); % 'a'== PERMISSION: open or create file for writing; append data to end of file
            % subject header
            fprintf(fid, ['Experiment:\t' expName '\n']);
            fprintf(fid, ['date:\t' datestr(now) '\n']);
            fprintf(fid, ['Subject:\t' subjNumber '\n']);
            % data header
            fprintf(fid, ['onset\tduration\ttrial_number\tstim_name\tblock\tmodality'
                          '\trepetition\tactor\tconsonant\tvowel\ttarget\tkeypress_number\tresponsekey\tkeypress_time\n']);
            fclose(fid);

            % Pseudorandomization made based on syllable vector for the faces
            [pseudoSyllVector, pseudoSyllIndex] = pseudorandptb(stimSyll);
            for ind = 1:length(stimSyll)
                myExpTrials(pseudoSyllIndex(ind)).pseudorandindex = ind;
            end

            % turn struct into table to reorder it
            tableexptrials = struct2table(myExpTrials);
            pseudorandtabletrials = sortrows(tableexptrials, 'pseudorandindex');

            % convert into structure to use in the trial/ stimui loop below
            pseudorandExpTrials = table2struct(pseudorandtabletrials);

            % add 1-back trials for current block type %
            pseudoRandExpTrialsBack = pseudorandExpTrials;
            for b = 1:(length(stimSyll) + r)
                if r == 2
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

                    elseif b == backTrials(2) + 2 % this trial will have a repeated emotion but a different actor
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

                    elseif b == backTrials(2) + 2 % this trial will have a repeated emotion but a different actor
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

                    elseif b == backTrials(3) + 3 % this trial will have a repeated emotion but a different actor
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
                        DrawFormattedText(Win, 'Faites attention aux LEVRES', 'center', 'center', textColor);
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
                    Screen('FillRect', Win, bgColor);

                    % ISI
                    [~, ~, ISIend] = Screen('Flip', Win, stimEnd + ISI);
                    disp(strcat('Timing trial  ', num2str(trial), ...
                                '- the duration was :', num2str(stimEnd - stimStart), ' sec')); % fb about duration in cw
                    disp(strcat('Timing ISI - the duration was :', num2str(ISIend - stimEnd), ' sec')); % fb about duration in cw

                    %% auditory
                elseif blockModality == auditoryCond

                    if trial == 1
                        DrawFormattedText(Win, 'Faites attention aux VOIX', 'center', 'center', textColor);
                        Screen('Flip', Win);
                        WaitSecs(0.5);
                        % clear instructions from screen
                        Screen('FillRect', Win, bgColor);
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

                    % %             % Stay in a little loop for the file duration:
                    % %             % use frames presentation loop to get the same duration as in the visual condition%
                    % %             for f = 1:nFrames
                    % %
                    % %             Screen('DrawTexture', Win, blackScreen, [], [], 0);
                    % %             [~, ~, lastEventTime] = Screen('Flip', Win, lastEventTime+frameDuration);
                    % %
                    % %             end

                    WaitSecs(2);

                    % Stop playback:
                    [~, ~, ~, stimEnd] = PsychPortAudio('Stop', pahandle);
                    % PsychPortAudio('Stop', pahandle);

                    % Close the audio device:
                    PsychPortAudio('Close', pahandle);

                    % clear stimulus from screen
                    Screen('Flip', Win);
                    [~, ~, ISIend] = Screen('Flip', Win, stimEnd + ISI);

                    disp(strcat('Timing trial ', num2str(trial), '- duration was :', ...
                                num2str(stimEnd - stimStart), ' sec')); % fb about duration in cw
                    disp(strcat('Timing ISI - duration was :', num2str(ISIend - stimEnd), ' sec')); % fb about duration in cw

                end

                % SAVE DATA TO THE OUTPUT FILE

                % get keypresses during this trial
                pressCodeTime = KbQueue('stop', expStart); % 1 column per keypress; row 1 = keyCode, row 2 = time.
                pCTSize = size(pressCodeTime);
                howManyPress = pCTSize(2); % get number of columns = number of keypress
                if howManyPress == 0
                    keyName = '';
                    keyTime = 0;
                else
                    keyName = KbName(pressCodeTime(1, 1)); % get name of the first key pressed (1st row, 1st col)
                    keyTime = pressCodeTime(2, 1); % get time of the first key (2nd row, 1st col)
                end

                % write in the output file

                % header was defined previously as :
                % onset duration trial_number stim_name block modality repetition actor consonant vowel target keypress_number responsekey keypress_time

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

    DrawFormattedText(Win, 'Fin de l''experience :)\nMERCI !', 'center', 'center', textColor);
    Screen('Flip', Win);
    expEnd = GetSecs;
    disp(strcat('Experiment duration: ', num2str((expEnd - expStart) / 60), ' \n Press SPACE to end'));
    KbQueue('flush');
    KbQueue('wait', 'space');
    ListenChar(0);
    ShowCursor;
    sca;

catch
    ListenChar(0);
    ShowCursor;
    sca;
end
