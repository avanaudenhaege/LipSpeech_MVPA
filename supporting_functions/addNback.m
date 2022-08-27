function expTrialsBack = addNback(cfg, expTrials, backTrials, r)

    % add 1-back trials for current block type %
    expTrialsBack = expTrials;
    for b = 1:(length(cfg.stimSyll) + r)
        if r == 2
            if b <= backTrials(1)
                expTrialsBack(b) = expTrials(b);

                % this trial will be a target
                % (repetition of the previous syllable - different actor)
            elseif b == backTrials(1) + 1
                % find where the same-syll-different-actor rows are %
                syllVector = {expTrials.syllable};
                syllRepeated = {expTrials(backTrials(1)).syllable};
                syllTF = ismember(syllVector, syllRepeated);
                syllIndices = find(syllTF);
                syllIndices(syllIndices == (b - 1)) = []; % get rid of current actor
                % and choose randomly among the others
                expTrialsBack(b) = expTrials(randsample(syllIndices, 1));
                % add 1 in trialtype column
                expTrialsBack(b).trialtype = 1;

                % this trial will have a repeated emotion but a different actor
            elseif b == backTrials(2) + 2
                % find where the same-emotion-different-actor rows are %
                syllVector = {expTrials.syllable};
                syllRepeated = {expTrials(backTrials(2)).syllable};
                syllTF = ismember(syllVector, syllRepeated);
                syllIndices = find(syllTF);
                syllIndices(syllIndices == b - 2) = []; % get rid of current actor
                % and choose randomly among the others
                expTrialsBack(b) = expTrials(randsample(syllIndices, 1));
                % add 1 in trialtype column
                expTrialsBack(b).trialtype = 1;

            elseif b > backTrials(1) + 1 && b < backTrials(2) + 2
                expTrialsBack(b) = expTrials(b - 1);

            elseif b > backTrials(2) + 2
                expTrialsBack(b) = expTrials(b - 2);

            end

        elseif r == 3
            if b <= backTrials(1)
                expTrialsBack(b) = expTrials(b);

                % this trial will be a target (repetition of the previous syllable - different actor)
            elseif b == backTrials(1) + 1
                % find where the same-syll-different-actor rows are %
                syllVector = {expTrials.syllable};
                syllRepeated = {expTrials(backTrials(1)).syllable};
                syllTF = ismember(syllVector, syllRepeated);
                syllIndices = find(syllTF);
                syllIndices(syllIndices == (b - 1)) = []; % get rid of current actor
                % and choose randomly among the others
                expTrialsBack(b) = expTrials(randsample(syllIndices, 1));
                % add 1 in trialtype column
                expTrialsBack(b).trialtype = 1;

                % this trial will have a repeated emotion but a different actor
            elseif b == backTrials(2) + 2
                % find where the same-emotion-different-actor rows are %
                syllVector = {expTrials.syllable};
                syllRepeated = {expTrials(backTrials(2)).syllable};
                syllTF = ismember(syllVector, syllRepeated);
                syllIndices = find(syllTF);
                syllIndices(syllIndices == b - 2) = []; % get rid of current actor
                % and choose randomly among the others
                expTrialsBack(b) = expTrials(randsample(syllIndices, 1));
                % add 1 in trialtype column
                expTrialsBack(b).trialtype = 1;

                % this trial will have a repeated emotion but a different actor
            elseif b == backTrials(3) + 3
                % find where the same-emotion-different-actor rows are %
                syllVector = {expTrials.syllable};
                syllRepeated = {expTrials(backTrials(3)).syllable};
                syllTF = ismember(syllVector, syllRepeated);
                syllIndices = find(syllTF);
                syllIndices(syllIndices == b - 3) = []; % get rid of current actor
                % and choose randomly among the others
                expTrialsBack(b) = expTrials(randsample(syllIndices, 1));
                % add 1 in trialtype column
                expTrialsBack(b).trialtype = 1;

            elseif b > backTrials(1) + 1 && b < backTrials(2) + 2
                expTrialsBack(b) = expTrials(b - 1);

            elseif b > backTrials(2) + 2 && b < backTrials(3) + 3
                expTrialsBack(b) = expTrials(b - 2);

            elseif b > backTrials(3) + 3
                expTrialsBack(b) = expTrials(b - 3);

            end
        end
    end

end
