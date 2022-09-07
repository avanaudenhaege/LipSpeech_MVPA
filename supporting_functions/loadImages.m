function [structureName] = loadImages(cfg, actor, syllable)
    %
    % [structureName] = loadImages(cfg, framesArray)
    %
    % builds a structure with the images/frames of a video
    %
    % the output of the function is a structure with a number of rows equal to nbFrames and 4 fields:
    %
    % - actor
    % - syllable
    % - stimFilename
    % - stimImage: the image data content

    structureName =  struct();

    fprintf('loading %s\n', [actor syllable]);

    allImages = bids.internal.file_utils('FPList', cfg.dir.stimuli, ['^' actor syllable '.*' cfg.video.ext '$']);

    for i = 1:cfg.nbFrames
        thisImage = deblank(allImages(i, :));
        structureName(i).actor = actor;
        structureName(i).syllable = syllable;
        structureName(i).stimFilename = bids.internal.file_utils(thisImage, 'filename');

        stimImage = imread(thisImage);
        if ~isa(stimImage, 'uint8')
            warning('\n Coercing image content to uint8 datatype:\n  %s\n', thisImage);
            stimImage = uint8(stimImage);
        end
        structureName(i).stimImage = stimImage;

    end

end
