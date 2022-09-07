function displayIsiStats(cfg, file)
    %
    % Displays mean +/- std of trial
    %

    fileContent = bids.util.tsvread(file);

    stimuliOnsetAsynchrony = diff(fileContent.onset);

    ISI = stimuliOnsetAsynchrony - fileContent.duration(1:end - 1);

    talkToMe(cfg, sprintf('\nTiming - ISI: %0.3f +/- %0.3f sec\n', mean(ISI), std(ISI)));

end
