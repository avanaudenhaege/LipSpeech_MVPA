function expTrialsBack = addNback(cfg, expTrials, backTrials, r)

    IS_TARGET = 1;

    % add 1-back trials for current block type %
    expTrialsBack = expTrials;

    for b = 1:(length(cfg.stimSyll) + r)

        if b <= backTrials(1)
            expTrialsBack(b) = expTrials(b);

            % repetition of the previous syllable - different actor
        elseif b == backTrials(1) + 1

            expTrialsBack(b) = pickAnotherStim(expTrials, backTrials, b, 1);
            expTrialsBack(b).trialtype = IS_TARGET;

            % repetition of the previous syllable - different actor
        elseif b == backTrials(2) + 2

            expTrialsBack(b) = pickAnotherStim(expTrials, backTrials, b, 2);
            expTrialsBack(b).trialtype = IS_TARGET;

        elseif b > backTrials(1) + 1 && b < backTrials(2) + 2
            expTrialsBack(b) = expTrials(b - 1);

        end

        %%
        if r == 2

            if b > backTrials(2) + 2
                expTrialsBack(b) = expTrials(b - 2);

            end

        elseif r == 3

            % repetition of the previous syllable - different actor
            if b == backTrials(3) + 3

                expTrialsBack(b) = pickAnotherStim(expTrials, backTrials, b, 3);
                expTrialsBack(b).trialtype = IS_TARGET;

            elseif b > backTrials(2) + 2 && b < backTrials(3) + 3
                expTrialsBack(b) = expTrials(b - 2);

            elseif b > backTrials(3) + 3
                expTrialsBack(b) = expTrials(b - 3);

            end

        end

    end

end

function value = pickAnotherStim(expTrials, backTrials, b, nBackValue)

    % find where the same-syllable-different-actor rows are %
    syllVector = {expTrials.syllable};
    syllRepeated = {expTrials(backTrials(nBackValue)).syllable};
    syllTF = ismember(syllVector, syllRepeated);
    syllIndices = find(syllTF);

    % get rid of current actor
    syllIndices(syllIndices == b - nBackValue) = [];

    % and choose randomly among the others

    value = expTrials(randsample(syllIndices, 1));

end
