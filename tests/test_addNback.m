function test_suite = test_addNback() %#ok<*STOUT>
    %
    % (C) Copyright 2020 CPP_PTB developers
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions(); %#ok<*NASGU>
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
end

function test_addNback_basic()

    % set and load all the parameters to run the experiment
    cfg = setParameters;

    stimuliMatFile = fullfile(cfg.dir.root, 'stimuli', 'stimuli.mat');
    if ~exist(stimuliMatFile, 'file')
        saveStimuliAsMat();
    end
    load(stimuliMatFile, 'myVidStructArray');
    stimNames = fieldnames(myVidStructArray);

    for t = 1:length(stimNames)
        expTrials(t).stimulusname = stimNames{t};
        expTrials(t).visualstimuli = myVidStructArray.(stimNames{t});
        expTrials(t).syllable = myVidStructArray.(stimNames{t}).syllable;
        expTrials(t).trialtype = 0;
    end

    nReps = 10;
    rep = 1;

    % vector with # of blocks per condition
    % (if 5 reps, you have 5 blocks for each condition)
    blockPerCond = 1:nReps;

    auditoryCond = 1;
    visualCond = 2;
    blockModality = 1;

    %% design
    tmp = randperm(nReps);
    twoBackBlocksVisual = tmp(1:round(nReps / 2));
    threeBackBlocksVisual = setdiff(blockPerCond, twoBackBlocksVisual);

    tmp = randperm(nReps);
    twoBackBlocksAudio = tmp(1:round(nReps / 2));
    threeBackBlocksAudio = setdiff(blockPerCond, twoBackBlocksAudio);

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

    if blockModality == visualCond
        r = v;
        backTrials = backTrialsVisual;
        modality = 'vis';
    elseif blockModality == auditoryCond
        r = w;
        backTrials = backTrialsAudio;
        modality = 'aud';
    end

    % Pseudorandomization made based on syllable vector for the faces
    [~, pseudoSyllIndex] = pseudorandptb(cfg.stimSyll);
    for ind = 1:length(cfg.stimSyll)
        pseudorandExpTrials(ind) = expTrials(pseudoSyllIndex(ind));
    end

    expTrialsBack = addNback(cfg, pseudorandExpTrials, backTrials, r);

end
