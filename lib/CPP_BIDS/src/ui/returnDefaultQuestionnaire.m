function [items, cfg] = returnDefaultQuestionnaire(cfg)
    %
    %  Set default questions for subject / session / run number and group ID.
    %  Also sets default values for those when in debug mode.
    %
    %   USAGE ::
    %
    %     q = returnDefaultQuestionnaire()
    %
    % (C) Copyright 2022 CPP_BIDS developers

    if nargin < 1
        cfg = struct('debug', []);
    end

    if ~isfield(cfg, 'debug') || isempty(cfg.debug)
        cfg.debug.do = false;
    end

    items(1) = struct('question', 'Enter subject group (leave empty if none): ', ...
                      'response', '', ...
                      'mustBePosInt', false, ...
                      'show', true);

    items(2).question = 'Enter subject number (1-999): ';
    items(2).response = '';
    items(2).mustBePosInt = true;
    items(2).show = true;

    items(3).question = 'Enter the session number (i.e day ; 1-999): ';
    items(3).response = '';
    items(3).mustBePosInt = true;
    items(3).show = true;

    items(4).question = 'Enter the run number (1-999): ';
    items(4).response = '';
    items(4).mustBePosInt = true;
    items(4).show = true;

    if cfg.debug.do

        items(1).response = 'ctrl';
        items(2).response = 666;
        items(3).response = 666;
        items(4).response = 666;

        cfg.subject.subjectGrp = items(1).response;
        cfg.subject.subjectNb = items(2).response;
        cfg.subject.sessionNb = items(3).response;
        cfg.subject.runNb = items(4).response;

    end

end
