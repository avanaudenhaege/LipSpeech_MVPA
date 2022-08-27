function [structureName] = loadImages(cfg, actor, syllable)
    %
    % [structureName] = loadImages(cfg, framesArray)
    %
    % builds a structure with the images/frames of a video
    %
    % the output of the function is a structure with a number of rows equal to nFrames and 4 fields:
    %
    % - actor
    % - syllable
    % - stimFilename
    % - stimImage: the image data content

    structureName =  struct();

    fprintf('\nloading %s', [actor syllable]);

    allImages = bids.internal.file_utils('FPList', cfg.stimuliPath, ['^' actor syllable '.*.png$']);

    for i = 1:cfg.nFrames
        thisImage = deblank(allImages(i, :));
        structureName(i).actor = actor;
        structureName(i).syllable = syllable;
        structureName(i).stimFilename = bids.internal.file_utils(thisImage, 'filename');
        structureName(i).stimImage = imread(thisImage);
    end

end
