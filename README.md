# LipSpeech_MVPA

Stimulation for functional runs of fMRI design

programmer: Federica Falagiarda October 2019

ADAPTED BY ALICE VAN AUDENHAEGE - August 2022

Once fully run, this script has given a txt output file per block (= per
acquisition run)%

## BLOCK DESCRIPTION

There are 9 possible syllables portrayed by 3 speakers

- SYL: F P L \* A I E
- speakers : GH (=S2), JB (=S3), AV (=S1)

TOTAL stim per block = 27 stims

Possible modality for each block (n = 2) :

- visual (lipreading) or
- auditory (speech). The order of presentation of modalities is fixed within
  participant but varies across. It is defined manually at the begining of the
  script (orderCondVector).

1 block = 1 acquisition run = 1 modality.

The scanner will be relaunched after each run.

The script waits for the trigger (????? A CONFIRMER) to start the next block.

Time calculation for each run/block :

- 27 stim + 2 or 3 targets
- trial duration = 2s stim + 3s ISI = 5s
- block/run duration = (27 x 5s) + (2 or 3 targets x 5s) = 145 or 150s

## REPETITIONS

A repetition consists of 2 blocks, 1 of each modality (visual and auditory).

The number of repetition desired (nReps) is asked at the begining of the script
(ideally 18-20 reps in total, over 2 sessions).

## TASK

One-back task

The participant is asked to press a button when he/she sees a repeated syllable,
independently of the actor.

This is to force the participant to attend each syllable that is presented
(consonant AND vowel).

## STIMUILI

To be used with a folder named "stimuli" containing the following files stored
on OSF:

https://osf.io/2xtsn/?view_only=e21d5b119a344453bd18748c0145cf26

To download them just type (for MacOS and linux):

```bash
make clean
make stimuli
```
