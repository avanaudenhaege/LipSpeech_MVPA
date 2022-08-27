function saveStimuliAsMat()
    %
    % loads images of all requested stimuli and saves them as a mat file
    %

    cfg = configuration();

    % needed in case we want to run it by itself
    addpath(genpath(fullfile(cfg.rootDir, 'supporting_functions')));
    addpath(fullfile(cfg.rootDir, 'lib', 'bids-matlab'));

    fprintf('Preparing frame structures for each video \n');

    myVidStructArray = {};
    for a = 1:length(cfg.actor)
        for s = 1:length(cfg.syllable)
            myVidStructArray.([cfg.actor{a}, cfg.syllable{s}]) = loadImages(cfg, ...
                                                                            cfg.actor{a}, ...
                                                                            cfg.syllable{s});
        end
    end

    stimuliMatFile = fullfile(cfg.rootDir, 'stimuli', 'stimuli.mat');

    save(stimuliMatFile, 'myVidStructArray', '-v7.3');

end
