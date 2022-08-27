function cfg = configuration()

    cfg.debug.do = true;

    cfg.verbose = 1;

    cfg.dir.root = fileparts(mfilename('fullpath'));
    cfg.dir.stimuli = fullfile(cfg.dir.root, 'stimuli');
    cfg.dir.output = fullfile(cfg.dir.root, 'data');

    cfg.vidDuration = 2;
    cfg.videoFrameRate = 25;
    % total num of frames in a whole video
    cfg.nbFrames = cfg.videoFrameRate * cfg.vidDuration;

    cfg.instructions = 'TACHE\n Appuyez quand une syllabe est repetee deux fois d''affilee';

    % colors
    cfg.color.white = 255;
    cfg.color.black = 0;
    cfg.color.background = cfg.color.black;
    cfg.text.color = cfg.color.white;

    % triggers
    cfg.testingDevice = 'mri';
    cfg.triggerKey = 's'; % keycode for the trigger
    cfg.numTriggers = 1; % number of excluded volumes (first 2 triggers)
    cfg.bids.MRI.RepetitionTime = 1.75;

    % define actors and syllables used as stim
    % (S1 = AV, S2 = GH, S3 = JB)
    cfg.actor = {'S1', 'S2', 'S3'};
    cfg.syllable = {'pa', 'pi', 'pe', 'fa', 'fi', 'fe', 'la', 'li', 'le'};

    if cfg.debug.do
        cfg.actor = cfg.actor(1);
        cfg.syllable = cfg.syllable(1:3);
    end

    % variables necessary during randomization
    cfg.stimSyll = repmat(cfg.syllable, 1, numel(cfg.actor));

    tmp = [];
    for a = 1:numel(cfg.actor)
        tmp = [tmp repmat(cfg.actor(a), 1, numel(cfg.syllable))];
    end
    cfg.stimActors = tmp;

    cfg = checkCFG(cfg);

end
