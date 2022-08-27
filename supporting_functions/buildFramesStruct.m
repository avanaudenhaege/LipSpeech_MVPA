function [structureName] = buildFramesStruct(mainWindow, structureName, nbFrames, frameDuration, framesArray, stimuli_path)

    % [structureName] = buildFramesStruct(structureName, nbFrames, frameDuration, framesArray, framePath)
    % builds a structure with the images/frames of a video %
    % needs to be run with a PTB open and running window %
    %
    % the output of the function is a structure with a number of rows equal to nbFrames and 4 fields: %
    % stimNames: the name of the current frame/image %
    % stimImage: the image read through the name (framesArray) in the given location (framePath) %
    % duration: the desired duration of the frame on screen (frameDuration) %
    % imageTexture: the texture of the image read through Screen('MakeTexture')

    for i = 1:nbFrames
        structureName(i).stimNames = framesArray{i};
        structureName(i).stimImage = imread(fullfile(stimuli_path, [char(framesArray{i}) '.png']));
        structureName(i).duration = frameDuration;
        structureName(i).imageTexture = Screen('MakeTexture', mainWindow, structureName(i).stimImage);
    end

end
