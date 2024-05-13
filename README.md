# LipSpeech_MVPA

Stimulation for functional runs of fMRI design

Initial script Federica Falagiarda - adapted by Alice Van Audenhaege and Remi Gau
October 2022

## Install

There are some git submodules needed to run the code. 
To clone the repository and all submodules, use the following command:

```
git clone --recursive https://github.com/avanaudenhaege/LipSpeech_MVPA.git
```

## Description

Once fully run, this script has given an events.tsv and events.json output file.

### Blocks

There are 9 possible syllables portrayed by 3 speakers

- SYL: F P L \* A I E
- Speakers : S1, S2, S3
- Number of stimuli per run = 27 stims

Possible modality for each run:

- visual (lipreading) or
- auditory (speech).

The order of presentation of modalities is fixed within participant but varies
across. It is defined manually at the beginning of the script
(`orderCondVector`).

1 acquisition run = 1 block = 1 modality

The scanner will be relaunched after each run.

The script waits for the trigger to start the next run.

Time calculation for each run :

- 27 stim + 2 or 3 targets
- trial duration = 2s stim + 3s ISI = 5s
- block/run duration = (27 x 5s) + (2 or 3 targets x 5s) = 145 or 150s

### Repetitions

A repetition consists of 2 runs, 1 of each modality (visual and auditory).

The number of repetition desired (`nReps`) is asked at the beginning of the
script (ideally 18-20 reps in total, over 2 sessions).


### Stimuli

To be used with a folder named `stimuli` containing the following files stored
on OSF in `PhonologicalDecoding-MVPA_stimuli.zip`

https://osf.io/2xtsn/?view_only=22f09bb4dc5f4a11823103141ca2f735

To download them just type (for MacOS and linux):

```bash
make clean
make stimuli
```
