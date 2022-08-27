% Clear all the previous stuff
clear;
clc;

if ~ismac
    close all;
    clear Screen;
end

% make sure we got access to all the required functions and inputs
initEnv();

% set and load all the parameters to run the experiment
cfg = setParameters;

cfg = userInputs(cfg);

%% DESIGN

auditoryCond = 1;
visualCond = 2;

% num of different blocks (= different acquisition runs) per rep --> one per modality
nBlocks = 2;

nReps = input('NUMBER OF REPETITIONS :');
% if no value is supplied, do 10 reps
if isempty(nReps)
    nReps = 10;
end
if cfg.debug.do
    nReps = 2;
end

%% define order of modalities within a subject

% modality orded will be fixed within participant, and balanced across %
% 1 = auditory,
% 2 = visual
firstCondition = input('START WITH MODALITY ... ? (AUD=1 or VIS=2) :');

if firstCondition == 1
    secondCondition = 2;
elseif firstCondition == 2
    secondCondition = 1;
else
    % if error while encoding firstCondition, exp will start with AUD MODALITY
    firstCondition = 1;
    secondCondition = 2;
end

orderCondVector = [firstCondition, secondCondition];

% ADD TARGET TRIALS
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

talkToMe(cfg, '\n');

%%  Experiment

% Safety loop: close the screen if code crashes
try

    %% Init the experiment
    cfg = initPTB(cfg);

    % timings in my trial sequence
    % (substract interFrameInterval/3 to make sure that flipping is done
    % at 3sec straight and not 1 frame later)
    cfg.timing.ISI = 3 - cfg.screen.ifi / 6;
    cfg.timing.frameDuration = 1 / cfg.videoFrameRate - cfg.screen.ifi / 6;

    cfg = postInitializationSetup(cfg);

    talkToMe(cfg, 'turning images into textures.\n');
    for iStim = 1:numel(stimNames)
        thisStime = stimNames{iStim};
        for iFrame = 1:numel(myVidStructArray.(thisStime))
            myVidStructArray.(thisStime)(iFrame).duration = cfg.timing.frameDuration;  %#ok<*SAGROW>
            myVidStructArray.(thisStime)(iFrame).imageTexture = Screen('MakeTexture', ...
                                                                       cfg.screen.win, ...
                                                                       myVidStructArray.(thisStime)(iFrame).stimImage);
        end
    end
    % add textures to myExpTrials structure
    for t = 1:length(stimNames)
        myExpTrials(t).visualstimuli = myVidStructArray.(stimNames{t});
    end

    unfold(cfg);

    % Repetition loop

    for rep = 1:nReps

        cfg.subject.runNb = rep;

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
        backTrialsVisual = sort(randperm(cfg.design.nbTrials, v));
        backTrialsAudio = sort(randperm(cfg.design.nbTrials, w));

        % blocks correspond to modality, so each 'rep' has 2 blocks = 2 acquisition runs
        for block = 1:nBlocks

            Screen('FillRect', cfg.screen.win, cfg.color.background, cfg.screen.winRect);

            DrawFormattedText(cfg.screen.win, ...
                              cfg.task.instruction, ...
                              'center', 'center', cfg.text.color);

            Screen('Flip', cfg.screen.win);

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

            cfg.task.name = [cfg.expName modality];
            cfg.fileName.task = cfg.task.name;

            cfg = createFilename(cfg);

            % Prepare for the output logfiles with all
            logFile.extraColumns = cfg.extraColumns;
            logFile = saveEventsFile('init', cfg, logFile);
            logFile = saveEventsFile('open', cfg, logFile);

            % Pseudorandomization made based on syllable vector for the faces
            [~, pseudoSyllIndex] = pseudorandptb(cfg.stimSyll);
            for ind = 1:length(cfg.stimSyll)
                pseudorandExpTrials(ind) = myExpTrials(pseudoSyllIndex(ind));
            end

            pseudoRandExpTrialsBack = addNback(cfg, pseudorandExpTrials, backTrials, r);

            % Show experiment instruction
            standByScreen(cfg);

            talkToMe('WAITING FOR TRIGGER (instructions displayed on the screen) \n');

            % prepare the KbQueue to collect responses
            getResponse('init', cfg.keyboard.responseBox, cfg);

            %% Experiment Start

            cfg = getExperimentStart(cfg);

            getResponse('start', cfg.keyboard.responseBox);

            for iTrial = 1:cfg.design.nbTrials

                fprintf('\n - Running trial %.0f \n', iTrial);

                %         % Check for experiment abortion from operator
                checkAbort(cfg, cfg.keyboard.keyboard);
                %
                %         [thisEvent, thisFixation, cfg] = preTrialSetup(cfg, iBlock, iTrial);
                %
                %         % play the dots and collect onset and duraton of the event
                %         [onset, duration] = doTrial(cfg, thisEvent, thisFixation);
                %
                %         thisEvent = preSaveSetup( ...
                %                                  thisEvent, ...
                %                                  iBlock, ...
                %                                  iTrial, ...
                %                                  duration, onset, ...
                %                                  cfg, ...
                %                                  logFile);
                %
                % saveEventsFile('save', cfg, thisEvent);
                %
                %         % collect the responses and appends to the event structure for
                %         % saving in the tsv file
                responseEvents = getResponse('check', cfg.keyboard.responseBox, cfg);
                responseEvents.isStim = false;
                responseEvents(1).fileID = logFile.fileID;
                responseEvents(1).extraColumns = logFile.extraColumns;
                saveEventsFile('save', cfg, responseEvents);
                %
                %         waitFor(cfg, cfg.timing.ISI);
                %
            end

            % End of the run for the BOLD to go down
            waitFor(cfg, cfg.timing.endDelay);

        end

    end

    cfg = getExperimentEnd(cfg);

    % Close the logfiles
    saveEventsFile('close', cfg, logFile);

    getResponse('stop', cfg.keyboard.responseBox);
    getResponse('release', cfg.keyboard.responseBox);

    createJson(cfg, cfg);

    farewellScreen(cfg);

    cleanUp();

catch

    cleanUp();
    psychrethrow(psychlasterror);

end
