function cfg = configuration()

% (S1 = AV, S2 = GH, S3 = JB)
cfg.actor = {'S1', 'S2', 'S3'};
cfg.syllable = {'pa', 'pi', 'pe', 'fa', 'fi', 'fe', 'la', 'li', 'le'};

    cfg.rootDir = fileparts(mfilename('fullpath'));
    cfg.stimuliPath = fullfile(cfg.rootDir, 'stimuli');

    cfg.vidDuration = 2;
    cfg.videoFrameRate = 25;
    % total num of frames in a whole video
    cfg.nFrames = cfg.videoFrameRate * cfg.vidDuration;

    % triggers
    cfg.testingDevice = 'mri';
    cfg.triggerKey = 's'; % keycode for the trigger
    cfg.numTriggers = 1; % number of excluded volumes (first 2 triggers)
    cfg.win = Win;
    cfg.text.color = textColor;
    cfg.bids.MRI.RepetitionTime = 1.75;

end
