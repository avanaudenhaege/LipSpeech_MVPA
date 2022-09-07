function [cfg, myExpTrials] = postInitializationSetup(cfg, myExpTrials, myVidStructArray)
    % generic function to finalize some set up after psychtoolbox has been initialized
    %
    %
    % (C) Copyright 2022 Remi Gau

    % timings in my trial sequence
    % (substract interFrameInterval/3 to make sure that flipping is done
    % at 3sec straight and not 1 frame later)
    cfg.timing.ISI = 3 - cfg.screen.ifi / 6;
    cfg.timing.frameDuration = 1 / cfg.video.frameRate - cfg.screen.ifi / 6;

    talkToMe(cfg, '\nTurning images into textures.\n');

    stimNames = fieldnames(myVidStructArray);

    for iStim = 1:numel(stimNames)
        thisStime = stimNames{iStim};
        for iFrame = 1:numel(myVidStructArray.(thisStime))
            myVidStructArray.(thisStime)(iFrame).duration = cfg.timing.frameDuration;  %#ok<*SAGROW>
            stimImage = myVidStructArray.(thisStime)(iFrame).stimImage;
            myVidStructArray.(thisStime)(iFrame).imageTexture = Screen('MakeTexture', ...
                                                                       cfg.screen.win, ...
                                                                       stimImage);
        end
    end
    % add textures to myExpTrials structure
    for t = 1:length(stimNames)
        myExpTrials(t).visualStimuli = myVidStructArray.(stimNames{t});
    end

    %% set where to display videos depending on requested apparent size

    % assuming all videos have the same size
    cfg.video.height = size(myVidStructArray.(stimNames{1})(1).stimImage, 1);
    cfg.video.width = size(myVidStructArray.(stimNames{1})(1).stimImage, 1);

    cfg.video = degToPix('apparentHeight', cfg.video, cfg);
    cfg.video.apparentWidthPix = cfg.video.width / cfg.video.height * cfg.video.apparentHeightPix;

    cfg.screen.stimulusRect  = [cfg.screen.center(1) - cfg.video.apparentWidthPix / 2, ...
                                cfg.screen.center(2) - cfg.video.apparentHeightPix / 2, ...
                                cfg.screen.center(1) + cfg.video.apparentWidthPix / 2, ...
                                cfg.screen.center(2) + cfg.video.apparentHeightPix / 2];

    %% resample sounds if necessary
    if exist('resample') %#ok<EXIST>

        for t = 1:length(stimNames)

            thisStime = stimNames{iStim};

            if cfg.audio.fs ~= myExpTrials(t).audfreq

                talkToMe(sprintf('Resampling %s sound from %i Hz to %i Hz... ', ...
                                 thisStime, ...
                                 myExpTrials(t).audfreq, ...
                                 cfg.audio.fs));

                myExpTrials(t).audioData = resample(myExpTrials(t).audioData, ...
                                                    cfg.audio.fs, ...
                                                    myExpTrials(t).audfreq);
            end
        end

    end

end
