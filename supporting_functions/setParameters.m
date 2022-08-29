% (C) Copyright 2020 CPP visual motion localizer developpers

function [cfg] = setParameters()

    % Template PTB experiment

    % Initialize the parameters and general configuration variables
    cfg = struct();

    cfg.expName = 'LipSpeechMVPA';

    cfg.dir.root = bids.internal.file_utils(fullfile(fileparts(mfilename('fullpath')), '..'), 'cpath');
    cfg.dir.stimuli = fullfile(cfg.dir.root, 'stimuli');
    cfg.dir.output = fullfile(cfg.dir.root, 'data');

    %% Debug mode settings

    cfg.debug.do = true; % To test the script out of the scanner, skip PTB sync
    cfg.debug.smallWin = false; % To test on a part of the screen, change to 1
    cfg.debug.transpWin = true; % To test with trasparent full size screen

    cfg.verbose = 1;

    cfg.skipSyncTests = 0;

    %% Engine parameters
    cfg.testingDevice = 'mri';
    cfg.eyeTracker.do = false;

    %% Auditory Stimulation
    cfg.audio.do = true;
    cfg.audio.channels = 2;

    %% Task(s)

    % Instruction
    cfg.task.instructions = 'TACHE\n Appuyez quand une syllabe est repetee deux fois d''affilee';

    cfg = setMonitor(cfg);

    % Keyboards
    cfg = setKeyboards(cfg);

    % MRI settings
    cfg = setMRI(cfg);

    cfg.pacedByTriggers.do = false;

    %% Experiment Design

    % Time between events in secs
    cfg.timing.ISI = 1;
    % Number of seconds before the motion stimuli are presented
    cfg.timing.onsetDelay = 2;
    % Number of seconds after the end all the stimuli before ending the run
    cfg.timing.endDelay = 2;

    % stimXsize = 1920; % never used
    % stimYsize = 1080; % never used

    cfg.vidDuration = 2;
    cfg.videoFrameRate = 25;
    % total num of frames in a whole video
    cfg.nbFrames = cfg.videoFrameRate * cfg.vidDuration;

    cfg.subject.ask = {'ses'};

    % Fixation cross (in pixels)
    cfg.fixation.type = 'cross';
    cfg.fixation.colorTarget = cfg.color.red;
    cfg.fixation.color = cfg.color.white;
    cfg.fixation.width = .25;
    cfg.fixation.lineWidthPix = 3;
    cfg.fixation.xDisplacement = 0;
    cfg.fixation.yDisplacement = 0;

    cfg.target.maxNbPerBlock = 1;
    cfg.target.duration = 0.1; % In secs

    cfg.extraColumns = {'stim_file', ...
                        'block', ...
                        'modality', ...
                        'repetition', ...
                        'actor', ...
                        'consonant', ...
                        'vowel', ...
                        'target', ...
                        'key_name'};

    % define actors and syllables used as stim
    % (S1 = AV, S2 = GH, S3 = JB)
    cfg.actor = {'S1', 'S2', 'S3'};
    cfg.syllable = {'pa', 'pi', 'pe', 'fa', 'fi', 'fe', 'la', 'li', 'le'};

    if cfg.debug.do
        cfg.actor = cfg.actor(1:3);
        cfg.syllable = cfg.syllable(1:2);
    end

    % variables necessary during randomization
    cfg.stimSyll = repmat(cfg.syllable, 1, numel(cfg.actor));

    tmp = [];
    for a = 1:numel(cfg.actor)
        tmp = [tmp repmat(cfg.actor(a), 1, numel(cfg.syllable))];
    end
    cfg.stimActors = tmp;

    cfg.design.nbTrials = numel(cfg.stimSyll);

end

function cfg = setKeyboards(cfg)
    cfg.keyboard.escapeKey = 'ESCAPE';
    cfg.keyboard.responseKey = {'s', 'd', 'space'};
    cfg.keyboard.keyboard = [];
    cfg.keyboard.responseBox = [];

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.keyboard.keyboard = [];
        cfg.keyboard.responseBox = [];
    end
end

function cfg = setMRI(cfg)

    % letter sent by the trigger to sync stimulation and volume acquisition
    cfg.mri.triggerKey = 's';
    cfg.mri.triggerNb = 1;

    cfg.mri.repetitionTime = 1.75;

    cfg.bids.MRI.Instructionss = cfg.task.instructions;
    cfg.bids.MRI.TaskDescription = ['One-back task.', ...
                                    'The participant is asked to press a button, ', ...
                                    'when he/she sees a repeated syllable independently of the actor.', ...
                                    'This is to force the participant to attend each syllable ', ...
                                    'that is presented (consonant AND vowel).'];
    cfg.bids.MRI.CogAtlasID = 'https://www.cognitiveatlas.org/task/id/tsk_4a57abb949bcd/';
    cfg.bids.MRI.CogPOID = 'http://www.wiki.cogpo.org/index.php?title=N-back_Paradigm';

end

function cfg = setMonitor(cfg)

    % Monitor parameters for PTB
    cfg.color.white = [255 255 255];
    cfg.color.black = [0 0 0];
    cfg.color.red = [255 0 0];
    cfg.color.grey = mean([cfg.color.black; cfg.color.white]);
    cfg.color.background = cfg.color.black;
    cfg.text.color = cfg.color.white;

    % Monitor parameters
    cfg.screen.monitorWidth = 50; % in cm
    cfg.screen.monitorDistance = 40; % distance from the screen in cm

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.screen.monitorWidth = 25;
        cfg.screen.monitorDistance = 95;
    end

end
