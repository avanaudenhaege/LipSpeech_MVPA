function test_suite = test_displayIsiStats() %#ok<*STOUT>
    %
    % (C) Copyright 2020 CPP_PTB developers
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions(); %#ok<*NASGU>
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
end

function test_displayIsiStats_basic()
    cfg.verbose = 1;
    file = fullfile(pwd, 'data', 'sub-1_ses-1_task-LipSpeechMVPAaud_run-1_events.tsv');
    displayIsiStats(cfg, file);
end
