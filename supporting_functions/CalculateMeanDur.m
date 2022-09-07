function [meanDur]  = CalculateMeanDur(file)

%%%pbm in access to the file path (cfg.dir.outputSubject) 
%%%Undefined variable "cfg" or class "cfg.dir.outputSubject".


% in main script ==> filename = logFile.filename


filepathToRead = fullfile(cfg.dir.outputSubject,cfg.fileName.modality, file);

file_content = bids.util.tsvread(filepathToRead); 
meanDur = mean([file_content.duration]);

