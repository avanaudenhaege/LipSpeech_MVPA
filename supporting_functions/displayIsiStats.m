function displayIsiStats(cfg, file)
    %
    % Displays mean +/- std of trial
    %

    fileContent = bids.util.tsvread(file);

    trialsIdx = ~strcmp(fileContent.trial_type, 'response');

    stimuliOnsetAsynchrony = diff(fileContent.onset(trialsIdx));

    durations = fileContent.duration(trialsIdx);

    ISI = stimuliOnsetAsynchrony - durations(1:end - 1);

    talkToMe(cfg, sprintf('\nTiming - ISI: %0.3f +/- %0.3f sec\n', mean(ISI), std(ISI)));

end
