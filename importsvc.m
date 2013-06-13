function [target, reference] = importsvc(fileNames)
%IMPORTSVC Import a Spectra Vista Corporation signature file
%   [target, reference] = IMPORTSVC(filename) imports a data
%   file or data files recorded by a Spectra Vista Corporation
%   (SVC) field portable spectrometer into the workspace.
%   The filename argument can be a single file or multiple files
%   specified by wildcards (e.g. '*.sig'). Two arrays of strucutres
%   are returned, one with target spectra and one with reference
%   spectra.
%   This fuctions is originaly writen by Iain Robinson under FSF Post Processing Toolbox, fsf@nerc.ac.uk
%
% Copyright (c) 2011, Iain Robinson and Alasdair Mac Arthur All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
%    * Redistributions of source code must retain the above copyright
%      notice, this list of conditions and the following disclaimer.
%    * Redistributions in binary form must reproduce the above copyright
%      notice, this list of conditions and the following disclaimer in
%      the documentation and/or other materials provided with the distribution
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

[folder, files, extension] = fileparts(fileNames); % Separate the filenames string into parts. (The variable version is unused.)
listOfFilesAndFolders = dir(fullfile(folder, [files, extension])); % Get a list of the files and folders that match the specified filenames.
listOfFiles = listOfFilesAndFolders([listOfFilesAndFolders.isdir]==0); % Exclude folders (such as . and ..) from the list, to give a list of files only.
listOfFileNames = {listOfFiles.name};  % Copy the names of the files into a cell array.

% Check that the list of file names is not empty.
if isempty(listOfFileNames)
    error('No files were found which match:\n\t%s', fileNames);
end

% Import each file in the list, one at a time.
for i = 1:length(listOfFileNames)
    % Get the file name and the file name with the folder path.
    fileName = listOfFileNames{i};
    fileNameWithPath = fullfile(folder, fileName);
    [pathstr, fileNameWithoutExtension, ext] = fileparts(fileName); % pathstr and ext are unused variables.

    
    % Check that the file exists.
    if ~exist(fileNameWithPath, 'file')
        error('The file:\n\t%s\nwas not found.', fileNameWithPath);
    end
        
    % Read the file into a character array.
    fileRaw = fileread(fileNameWithPath);

    % Text data from DOS or Windows systems has extra carriage
    % return characters (\r) which cause problems for processing
    % The line below strips out all return characters, leaving
    % only the newline characters (\n).
    file = regexprep(fileRaw, '\r', ''); %...file is a character array (not a file handle).

    % Identify the file type.
    
    % Check that the file is a SVC HR-1024 signature file.
    if regexp(file, '/*** Spectra Vista HR-1024 ***/')
        % Read the HR-1024 header. This is done in a separate subfunction.
        [T,R] = parseHeaderHR1024(file);
        
        % Read the HR-1024 data.
        dataStructure = regexp(file,'^(?<wavelength>[\.\d]+)\s+?(?<reference>[-\.\d]+)\s+?(?<target>[-\.\d]+)\s+?([-\.\d]+)', 'names', 'lineanchors');
        
        % Convert character arrays to vectors
        wavelength = str2double({dataStructure.wavelength});
        referenceData = str2double({dataStructure.reference});
        targetData = str2double({dataStructure.target});

        % Transpose the data vectors from row to column vectors.
        wavelength = wavelength';
        referenceData = referenceData';
        targetData = targetData';
    elseif regexp(file, 'GER SIGNATURE* FILE')
        % File appears to be a signature file, identify instrument model.
        if regexp(file, 'instrument=\s*1500')
            % Read the GER1500 header.
            [T, R] = parseHeaderGER1500(file);
            
            % Read the GER1500 data. Note the ordering of the columns is
            % different to the HR-1024.
            dataStructure = regexp(file,'^(?<wavelength>[\.\d]+)\s+?(?<target>[-\.\d]+)\s+?(?<reference>[-\.\d]+)\s+?([-\.\d]+)', 'names', 'lineanchors');
        
            % Convert character arrays to vectors
            wavelength = str2double({dataStructure.wavelength});
            referenceData = str2double({dataStructure.reference});
            targetData = str2double({dataStructure.target});

            % Transpose the data vectors from row to column vectors.
            wavelength = wavelength';
            referenceData = referenceData';
            targetData = targetData';
        elseif regexp(file, 'instrument=\s*3700')
            % Read the GER3700 header.
            [T, R] = parseHeaderGER3700(file);
            
            % Read the GER3700 data.
            dataStructure = regexp(file,'^(?<wavelength>[\.\d]+)\s+?(?<target>[-\.\d]+)\s+?(?<reference>[-\.\d]+)\s+?([-\.\d]+)', 'names', 'lineanchors');
        
            % Convert character arrays to vectors
            wavelength = str2double({dataStructure.wavelength});
            referenceData = str2double({dataStructure.reference});
            targetData = str2double({dataStructure.target});

            % Transpose the data vectors from row to column vectors.
            wavelength = wavelength';
            referenceData = referenceData';
            targetData = targetData';
        else
            error('The file\n\t%s\nappears to be a GER signature file, but the instrument model could not be identified or is not supported by this import function. Please run\n\thelp importsvc\n\tfor a list of supported instruments.', fileName);
        end
    else
        error('The file\n\t%s\ndoes not appear to be from a Spectra Vista Corporation instrument.', fileName);
    end
                
    % COPY DATA INTO A STRUCTURE
    %
    % Give the spectrum a name. The name could probably be taken from
    % inside the file, but here the fileName (without the path and
    % extension) is used.
    %
    % Target spectra have an extra field called 'pair' which matches it
    % up with the corresponding reference spectrum. These values can be
    % edited in the workspace if need be.
    spectrumName = fileNameWithoutExtension;
    
    reference(i).name = [ spectrumName, '_reference' ];
    reference(i).datetime = R.DateTime; %...copied from the header.
    reference(i).header = R;
    reference(i).wavelength = wavelength;
    reference(i).data = referenceData;

    target(i).name = spectrumName;
    target(i).datetime = T.DateTime;
    target(i).header = T;
    target(i).pair = reference(i).name; %...the corresponding reference spectrum.
    target(i).wavelength = wavelength;
    target(i).data = targetData;
end
end

function [T, R] = parseHeaderGER1500(file)
%
% READ THE HEADER
%
% T is a structure containing the target header.
% R is a structure containing the reference header.

% Name and type of the spectrum. The name comes from the name field
% in the file. The .sig extension (if present) is removed.
T.Name = cell2mat(regexp(file, '^name= (.*?)(?:\.sig)?$', 'tokens', 'once', 'lineanchors'));
R.Name = T.Name;
T.Type = 'Target';
R.Type = 'Reference';

% Instrument information.
T.InstrumentModel = 'GER 1500';
R.InstrumentModel = 'GER 1500';
T.InstrumentManufacturer = 'Spectra Vista Corporation';
R.InstrumentManufacturer = 'Spectra Vista Corporation';
T.InstrumentSerialNumber = cell2mat(regexp(file, '^instrument=\s*?\S.+?: (\d+)\s*?$', 'tokens', 'once', 'lineanchors'));
R.InstrumentSerialNumber = T.InstrumentSerialNumber;

% Date and time
targetDatetimeString = regexp(file, '^time= (\d+/\d+/\d+\s+\d+:\d+:\d+),', 'tokens', 'once', 'lineanchors');
referenceDatetimeString = regexp(file, '^time= \d+/\d+/\d+\s+\d+:\d+:\d+,\s*(\d+/\d+/\d+\s+\d+:\d+:\d+)\s*?$', 'tokens', 'once', 'lineanchors');
% Check that the date and time were found. If they were not found
% this indicates that they were in a format that could not be
% recognised. This warning may result from using an old version of
% SVC GER 1500 software (less than version 2.1.0).
if isempty(targetDatetimeString)
    warning('The date and time for the target spectrum in file:\n\t%s\nwere in an unrecognised format and could not be imported.', T.Name);
    T.DateTime = 'Unknown';
else
    targetDateVector = datevec(targetDatetimeString, 'dd/mm/yyyy HH:MM:SS');
    T.DateTime = datestr(targetDateVector);
end
if isempty(referenceDatetimeString)
    warning('The date and time for the reference spectrum in file:\n\t%s\nwere in an unrecognised format and could not be imported.', T.Name);
    R.DateTime = 'Unknown';
else            
    referenceDateVector = datevec(referenceDatetimeString, 'dd/mm/yyyy HH:MM:SS');
    R.DateTime = datestr(referenceDateVector);
end
R.DateTimeSource = 'Unknwon'; % The time may come from the spectrometer's clock or the computer's.
T.DateTimeSource = 'Unknown';

% Memory slots
T.MemorySlot = str2double(regexp(file, '^memory slot = (\d+)\s*,', 'tokens', 'once', 'lineanchors'));
R.MemorySlot = str2double(regexp(file, '^memory slot = \d+\s*,(\d+)', 'tokens', 'once', 'lineanchors'));
if isempty(T.MemorySlot)
    T.MemorySlot = 'Unknown';
end
if isempty(R.MemorySlot)
    R.MemorySlot = 'Unknown';
end
% Check whether either of the memory slots is set to zero. This can
% occur if a mistake is made during data recording, but could also
% occur in other situations.
if T.MemorySlot == 0
    warning('The target spectrum named:\n\t%s\nwas in memory slot 0. This could indicate that it is invalid.', T.Name);
end
if R.MemorySlot == 0
    warning('The reference spectrum named:\n\t%s\nwas in memory slot 0. This could indicate that it is invalid.', R.Name);
end

% Averaging and integration
targetAveragingIndex = str2double(regexp(file, '^averaging= (\d+)\s*,', 'tokens', 'once', 'lineanchors'));
referenceAveragingIndex = str2double(regexp(file, '^averaging= \d+,(\d+)', 'tokens', 'once', 'lineanchors'));
T.Averaging = 2^(targetAveragingIndex - 1);
R.Averaging = 2^(referenceAveragingIndex - 1);
% Issue a warning if different averaging settings were used for
% target and reference spectra.
if T.Averaging ~= R.Averaging
    warning('Different integration time settings were used for the target and reference spectra in the file:\n\t%s', T.Name);
end
targetIntegrationTimeIndex = str2double(regexp(file, '^integration .peed= (\d+)\s*,', 'tokens', 'once', 'lineanchors'));
referenceIntegrationTimeIndex = str2double(regexp(file, '^integration .peed= \d+\s*,\s*(\d+)', 'tokens', 'once', 'lineanchors'));
T.IntegrationTime = 5*2^(targetIntegrationTimeIndex - 1);
T.IntegrationTimeUnits = 'ms';
R.IntegrationTime = 5*2^(referenceIntegrationTimeIndex - 1);
R.IntegrationTimeUnits = 'ms';        

% Fore optic
opticNames = { 'Standard 4� field of view', 'Fiber optic', '8� field of view', 'Diffuser', 'Unknown'};
targetOpticNumber = str2double(regexp(file, '^optic= (\d+)', 'tokens', 'once', 'lineanchors'));
referenceOpticNumber = str2double(regexp(file, '^optic= \d+\s*,\s*(\d+)', 'tokens', 'once', 'lineanchors'));
% Issue a warning if different fore optics were used for the target
% and reference spectra.
if targetOpticNumber ~= referenceOpticNumber
    warning('Different fore optics were used for the target and reference spectra in the file:\n\t%s', T.Name);
end
T.ForeOptic = opticNames{targetOpticNumber};
R.ForeOptic = opticNames{referenceOpticNumber};

% Comments
T.Comments = deblank(char(regexp(file, '^comm=(.*?)$', 'tokens', 'once', 'lineanchors')));
R.Comments = T.Comments;
end

function [T,R] = parseHeaderGER3700(file)
%
% READ THE HEADER
%
% T is a structure containing the target header.
% R is a structure containing the reference header.

% Name and type of the spectrum. The name comes from the name field
% in the file. The .sig extension (if present) is removed.
T.Name = cell2mat(regexp(file, '^name= (.*?)(?:\.sig)?$', 'tokens', 'once', 'lineanchors'));
R.Name = T.Name;
T.Type = 'Target';
R.Type = 'Reference';

% Instrument information.
T.InstrumentModel = 'GER 3700';
R.InstrumentModel = 'GER 3700';
T.InstrumentManufacturer = 'Spectra Vista Corporation';
R.InstrumentManufacturer = 'Spectra Vista Corporation';
T.InstrumentSerialNumber = cell2mat(regexp(file, '^instrument=\s*?\S.+?: (\d+)\s*?$', 'tokens', 'once', 'lineanchors'));
R.InstrumentSerialNumber = T.InstrumentSerialNumber;

% Date and time
targetDatetimeString = regexp(file, '^time= (\d+/\d+/\d+\s+\d+:\d+:\d+),', 'tokens', 'once', 'lineanchors');
referenceDatetimeString = regexp(file, '^time= \d+/\d+/\d+\s+\d+:\d+:\d+,\s*(\d+/\d+/\d+\s+\d+:\d+:\d+)\s*?$', 'tokens', 'once', 'lineanchors');
% Check that the date and time were found. If they were not found
% this indicates that they were in a format that could not be
% recognised. This warning may result from using an old version of
% SVC GER 1500 software (less than version 2.1.0).
if isempty(targetDatetimeString)
    warning('The date and time for the target spectrum in file:\n\t%s\nwere in an unrecognised format and could not be imported.', T.Name);
    T.DateTime = 'Unknown';
else
    targetDateVector = datevec(targetDatetimeString, 'dd/mm/yyyy HH:MM:SS');
    T.DateTime = datestr(targetDateVector);
end
if isempty(referenceDatetimeString)
    warning('The date and time for the reference spectrum in file:\n\t%s\nwere in an unrecognised format and could not be imported.', T.Name);
    R.DateTime = 'Unknown';
else            
    referenceDateVector = datevec(referenceDatetimeString, 'dd/mm/yyyy HH:MM:SS');
    R.DateTime = datestr(referenceDateVector);
end
R.DateTimeSource = 'Unknwon'; % The time may come from the spectrometer's clock or the computer's.
T.DateTimeSource = 'Unknown';

% Averaging and integration
targetAveragingIndex = str2double(regexp(file, '^averaging= (\d+)\s*,', 'tokens', 'once', 'lineanchors'));
referenceAveragingIndex = str2double(regexp(file, '^averaging= \d+,(\d+)', 'tokens', 'once', 'lineanchors'));
T.Averaging = 2^(targetAveragingIndex - 1);
R.Averaging = 2^(referenceAveragingIndex - 1);
% Issue a warning if different averaging settings were used for
% target and reference spectra.
if T.Averaging ~= R.Averaging
    warning('Different integration time settings were used for the target and reference spectra in the file:\n\t%s', T.Name);
end
targetIntegrationSpeedSiDetector = str2double(regexp(file, '^Si integration .peed= (\d+),', 'tokens', 'once', 'lineanchors'));
targetIntegrationSpeedPbSDetector = str2double(regexp(file, '^PbS integration .peed= (\d+),', 'tokens', 'once', 'lineanchors'));
referenceIntegrationSpeedSiDetector = str2double(regexp(file, '^Si integration .peed= \d+,(\d+)', 'tokens', 'once', 'lineanchors'));
referenceIntegrationSpeedPbSDetector = str2double(regexp(file, '^PbS integration .peed= \d+,(\d+)', 'tokens', 'once', 'lineanchors'));        
% The integration speed appears to be an index from which the
% integration time (in ms) can be calculated. However the
% calculation of the integration time from the index is not given
% in the instrument's manual. The following lines are therefore
% commented out.
% H.IntegrationTimeSiDetector = ???? ;
% H.IntegrationTimePbSDetector = ???? ;
% H.IntegrationTimeUnits = 'ms';

% Fore optic
opticNames = { 'Standard 4� field of view', 'Fiber optic', '8� field of view', 'Diffuser', 'Unknown'};
targetOpticNumber = str2double(regexp(file, '^optic= (\d+)', 'tokens', 'once', 'lineanchors'));
referenceOpticNumber = str2double(regexp(file, '^optic= \d+\s*,\s*(\d+)', 'tokens', 'once', 'lineanchors'));
% Issue a warning if different fore optics were used for the target
% and reference spectra.
if targetOpticNumber ~= referenceOpticNumber
    warning('Different fore optics were used for the target and reference spectra in the file:\n\t%s', T.Name);
end
T.ForeOptic = opticNames{targetOpticNumber};
R.ForeOptic = opticNames{referenceOpticNumber};

T.Temperatures = str2double(regexp(file, 'temperature=([-\.\d]+), ?([-\.\d]+), ?([-\.\d]+)', 'tokens', 'once'));
T.MatchingFactors = str2double(regexp(file, 'matchfactor= ([-\.\d]+), ([-\.\d]+), ([-\.\d]+)', 'tokens', 'once'));
R.Temperatures = str2double(regexp(file, 'temperature=[-\.\d]+, ?[-\.\d]+, ?[-\.\d]+, ?([-\.\d]+), ?([-\.\d]+), ?([-\.\d]+)', 'tokens', 'once'));
R.MatchingFactors = str2double(regexp(file, 'matchfactor= ([-\.\d]+), ([-\.\d]+), ([-\.\d]+)', 'tokens', 'once'));

% Comments
T.Comments = deblank(char(regexp(file, '^comm=(.*?)$', 'tokens', 'once', 'lineanchors')));
R.Comments = T.Comments;
end

function [T,R] = parseHeaderHR1024(file)
% T is a structure containing the target header.
% R is a structure containing the reference header.
%
% Instrument information.
R.Name = cell2mat(regexp(file, '^name= (.*?)$', 'tokens', 'once', 'lineanchors'));
T.Name = R.Name;
R.Type = 'Reference';
T.Type = 'Target';
T.InstrumentModel = 'HR-1024';
R.InstrumentModel = 'HR-1024';
T.InstrumentManufacturer = 'Spectra Vista Corporation';
R.InstrumentManufacturer = 'Spectra Vista Corporation';
T.InstrumentSerialNumber = cell2mat(regexp(file, '^instrument=\s*?HR:\s*?(\d+)\s*?$', 'tokens', 'once', 'lineanchors'));
R.InstrumentSerialNumber = T.InstrumentSerialNumber;
% Warning: The date and time format for HR-1024 files is not
% consistent. Files originating from a PDA use the American
% date format. Files from a laptop use the British format.
%
% Identify the date format used. If the abbreviations 'AM' or
% 'PM' appear in the input file's time field then the date
% should be in the American format (mm/dd/yy). Otherwise assume
% the date is in the British format (dd/mm/yyyy). Note also the
% difference in the number of digits used to write the year.
if ~isempty(regexp(file, '^time= \d+/\d+/\d+ \d+:\d+:\d+ (AM)|(PM)', 'lineanchors', 'once'));
    % Read a date in the American format.
    targetDatetimeString = regexp(file, '^time= .*?, (\d+/\d+/\d+ \d+:\d+:\d+ .M)', 'tokens', 'once', 'lineanchors');
    referenceDatetimeString = regexp(file, '^time= (\d+/\d+/\d+ \d+:\d+:\d+ .M),', 'tokens', 'once', 'lineanchors');
    targetDateVector = datevec(targetDatetimeString{1}, 'mm/dd/yy HH:MM:SS AM');
    referenceDateVector = datevec(referenceDatetimeString{1}, 'mm/dd/yy HH:MM:SS AM');
    T.DateTime = datestr(targetDateVector);
    R.DateTime = datestr(referenceDateVector);
elseif ~isempty(regexp(file, '^time= \d+/\d+/\d+ \d+:\d+:\d+', 'lineanchors', 'once'));
    % Read a date in the British format.
    targetDatetimeString = regexp(file, '^time= .*?, (\d+/\d+/\d+ \d+:\d+:\d+)', 'tokens', 'once', 'lineanchors');
    referenceDatetimeString = regexp(file, '^time= (\d+/\d+/\d+ \d+:\d+:\d+),', 'tokens', 'once', 'lineanchors');
    targetDateVector = datevec(targetDatetimeString, 'dd/mm/yyyy HH:MM:SS');
    referenceDateVector = datevec(referenceDatetimeString, 'dd/mm/yyyy HH:MM:SS');
    T.DateTime = datestr(targetDateVector);
    R.DateTime = datestr(referenceDateVector);
else
    warning('The date and time format in the file:\n\t%s\nwas not recognised and could not be imported.');
    T.DateTime = 'Unknown';
    R.DateTime = 'Unknown';
end
T.DateTimeSource = 'Unknown'; % The time may come from the spectrometer's clock, the computer's or the PDA's.
R.DateTimeSource = 'Unknown';
T.MemorySlot = str2double(regexp(file, '^memory slot=.*?,\s*?(\d+).*?$', 'tokens', 'once', 'lineanchors'));
R.MemorySlot = str2double(regexp(file, '^memory slot=\s*?(\d+).*?,', 'tokens', 'once', 'lineanchors'));
if T.MemorySlot == 0 && R.MemorySlot == 0
    T.AcquisitionDevice = 'Computer or PDA';
    R.AcquisitionDevice = 'Computer or PDA';
else
    T.AcquisitionDevice = 'Spectromter memory slot';
    R.AcquisitionDevice = 'Spectrometer memory slot';
end
T.ScanTime = str2double(regexp(file, '^scan time= .*?,\s?([\.\d]+)', 'tokens', 'once', 'lineanchors'));
R.ScanTime = str2double(regexp(file, '^scan time=\s*([\.\d]+),', 'tokens', 'once', 'lineanchors'));
T.ScanTimeUnits = 's';
R.ScanTimeUnits = 's';
R.IntegrationTimeVNIR = str2double(regexp(file, '^integration= ([\.\d]+), [\.\d]+, [\.\d]+, [\.\d]+, [\.\d]+, [\.\d]+\s*?$', 'tokens', 'once', 'lineanchors'));
T.IntegrationTimeVNIR = str2double(regexp(file, '^integration= [\.\d]+, [\.\d]+, [\.\d]+, ([\.\d]+), [\.\d]+, [\.\d]+\s*?$', 'tokens', 'once', 'lineanchors'));
R.IntegrationTimeSWIR1 = str2double(regexp(file, '^integration= [\.\d]+, ([\.\d]+), [\.\d]+, [\.\d]+, [\.\d]+, [\.\d]+\s*?$', 'tokens', 'once', 'lineanchors'));
T.IntegrationTimeSWIR1 = str2double(regexp(file, '^integration= [\.\d]+, [\.\d]+, [\.\d]+, [\.\d]+, ([\.\d]+), [\.\d]+\s*?$', 'tokens', 'once', 'lineanchors'));
R.IntegrationTimeSWIR2 = str2double(regexp(file, '^integration= [\.\d]+, [\.\d]+, ([\.\d]+), [\.\d]+, [\.\d]+, [\.\d]+\s*?$', 'tokens', 'once', 'lineanchors'));
T.IntegrationTimeSWIR2 = str2double(regexp(file, '^integration= [\.\d]+, [\.\d]+, [\.\d]+, [\.\d]+, [\.\d]+, ([\.\d]+)\s*?$', 'tokens', 'once', 'lineanchors'));
R.IntegrationTimeUnits = 'ms';
T.IntegrationTimeUnits = 'ms';
referenceDarkTypeCode = cell2mat(regexp(file, 'scan settings= (\w+), \w+, \w+, \w+\s*?$', 'tokens', 'once', 'lineanchors'));        
targetDarkTypeCode = cell2mat(regexp(file, 'scan settings= \w+, \w+, (\w+), \w+\s*?$', 'tokens', 'once', 'lineanchors'));
switch referenceDarkTypeCode
    case 'AD'
        R.DarkType = 'auto';
    case 'SD'
        R.DarkType = 'scaled';
    case 'UD'
        R.DarkType = 'unknown';
end
switch targetDarkTypeCode
    case 'AD'
        T.DarkType = 'auto';
    case 'SD'
        T.DarkType = 'scaled';
    case 'UD'
        T.DarkType = 'unknown';
end
targetIntegrationTypeCode = str2mat(regexp(file, 'scan settings= \w+, \w+, \w+, (\w+)\s*?$', 'tokens', 'once', 'lineanchors'));
referenceIntegrationTypeCode = str2mat(regexp(file, 'scan settings= \w+, (\w+), \w+, \w+\s*?$', 'tokens', 'once', 'lineanchors'));
switch targetIntegrationTypeCode
    case 'AI'
        T.IntegrationType = 'auto';
    case 'FI'
        T.IntegrationType = 'fixed';
    case 'UI'
        T.IntegrationType = 'unknown';
end
switch referenceIntegrationTypeCode
    case 'AI'
        R.IntegrationType = 'auto';
    case 'FI'
        R.IntegrationType = 'fixed';
    case 'UI'
        R.IntegrationType = 'unknown';
end

% Read all numbers listed on the external data set line.
externalDataSet1 = str2num(cell2mat(regexp(file, '^external data set1= ([-\+\.\d].*?)$', 'tokens', 'once', 'lineanchors')));
externalDataSet2 = str2num(cell2mat(regexp(file, '^external data set2= ([-\+\.\d].*?)$', 'tokens', 'once', 'lineanchors')));
% There should be 16 numbers: the 1 to 8 belong to the reference
% spectrum, 9 to 16 belong to the target spectrum. If 16 numbers
% were found, copy them into the header (H).
if length(externalDataSet1) == 16
    T.ExternalDataSet1 = externalDataSet1(9:16);
    R.ExternalDataSet1 = externalDataSet1(1:8);
else
    T.ExternalDataSet1 = []; %... otherwise set it to empty.
    R.ExternalDataSet1 = [];
end
if length(externalDataSet2) == 16
    T.ExternalDataSet2 = externalDataSet2(9:16);
    R.ExternalDataSet2 = externalDataSet2(1:8);
else
    T.ExternalDataSet2 = [];
    R.ExternalDataSet2 = [];
end

% Spectra recorded on a laptop have two additional fields: dark
% and mask. These fields will be missing from spectra recorded
% on a PDA. The dark and mask fields do not appear to belong
% specifically to either the dark or reference spectra, so are
% copied into both headers.
darkString = cell2mat(regexp(file, '^external data dark= ([-\+\.\d].*?)$', 'tokens', 'once', 'lineanchors'));
if ~isempty(darkString)
    R.ExternalDataDark = str2num(darkString);
    T.ExternalDataDark = R.ExternalDataDark; %...same as reference specturm.
else
    R.ExternalDataDark = 'Data missing';
    T.ExternalDataDark = 'Data missing';
end
maskString = cell2mat(regexp(file, '^external data mask= ([-\+\.\d].*?)$', 'tokens', 'once', 'lineanchors'));
if ~isempty(maskString)
    R.ExternalDataMask = str2num(maskString);
    T.ExternalDataMask = R.ExternalDataMask;
else
    R.ExternalDataMask = 'Data missing';
    T.ExternalDataMask = 'Data missing';
end

% Optic attached to lens barrel.
R.ForeOptic = cell2mat(regexp(file, '^optic=\s*?(\S.*?),', 'tokens', 'once', 'lineanchors'));
T.ForeOptic = cell2mat(regexp(file, '^optic=.*?,\s*?(\S.*?)$', 'tokens', 'once', 'lineanchors'));

% Detector temperatures
temperatures = str2num(cell2mat(regexp(file, '^temp=(.*?)$', 'tokens', 'once', 'lineanchors')));
R.TemperatureVNIRDetector = temperatures(1);
R.TemperatureSWIR1Detector = temperatures(2);
R.TemperatureSWIR2Detector = temperatures(3);                        
T.TemperatureVNIRDetector = temperatures(4);
T.TemperatureSWIR1Detector = temperatures(5);
T.TemperatureSWIR2Detector = temperatures(6);

% Battery voltages
R.BatteryVoltage = str2double(regexp(file, '^battery=\s*?([\.\+\d]+),', 'tokens', 'once', 'lineanchors'));
T.BatteryVoltage = str2double(regexp(file, '^battery=.*?,\s*?([\.\+\d]+)', 'tokens', 'once', 'lineanchors'));

% Errors (reported by the spectrometer, not by this script)
R.ErrorCode = str2double(regexp(file, '^error=\s*(\d+),', 'tokens', 'once', 'lineanchors'));
T.ErrorCode = str2double(regexp(file, '^error=.*?,\s*?(\d+)\s*?$', 'tokens', 'once', 'lineanchors'));
if R.ErrorCode ~= 0 || T.ErrorCode ~= 0
    warning('PostProcessing:SpectrometerReportedError', 'The spectrometer reported an error code whilst recording the spectra in file:\n\t%s', fileName);
end

% Overlap handling and matching
% These header fields are the same for both reference and target
% spectra.
% Overlapped data: preserved or removed?
if regexp(file, 'verlap: ?.emove')
    R.OverlapDataHandling = 'Removed';
    T.OverlapDataHandling = 'Removed';
    R.OverlapTransitionWavelength = str2double(regexp(file,'verlap: ?emove ?@ ?(\d+)', 'tokens', 'once', 'lineanchors'));
    T.OverlapTransitionWavelength = R.OverlapTransitionWavelength;
elseif regexp(file,'(Overlap: ?.reserve)')
    R.OverlapDataHandling = 'Preserved';
    T.OverlapDataHandling = 'Preserved';
    R.OverlapTransitionWavelength = 'Not applicable';
    T.OverlapTransitionWavelength = 'Not applicable';
else
    R.OverlapDataHandling = 'Unknown';
    T.OverlapDataHandling = 'Unknown';
    R.OverlapTransitionWavelength = 'Unknown';
    T.OverlapTransitionWavelength = 'Unknown';
end
% Matching type: None/Radiance/Reflectance
matchingTypeString = cell2mat(regexp(file, 'Matching Type: ?(\w+)', 'tokens', 'once', 'lineanchors'));
if ~isempty(matchingTypeString)
    R.OverlapMatchingType = matchingTypeString;
    T.OverlapMatchingType = matchingTypeString;
else
    R.OverlapMatchingType = 'Unknown';
    T.OVerlapMatchingType = 'Unknown';
end

if (strcmp(R.OverlapMatchingType, 'Reflectance') || strcmp(R.OverlapMatchingType, 'Radiance'))
    regionStart = str2double(regexp(file,'Matching Type: \w+ @ (\d+)', 'tokens', 'once', 'lineanchors'));
    regionEnd = str2double(regexp(file,'Matching Type: \w+ @ \d+ - (\d+)', 'tokens', 'once', 'lineanchors'));
    R.OverlapMatchingRegionWavelengthRange = [ regionStart, regionEnd ];
    T.OverlapMatchingRegionWavelengthRange = [ regionStart, regionEnd ];
else
    R.OverlapMatchingRegionWavelengthRange = 'Not applicable';
    T.OverlapMatchingRegionWavelengthRange = 'Not applicable';
end
if regexp(file, 'NIR-SWIR [Oo]ff')
    R.OverlapNIRSWIRAlgorithmEnabled = 'No';
    T.OverlapNIRSWIRAlgorithmEnabled = 'No';
elseif regexp(file, 'NIR-SWIR [Oo]n') %...Could be 'On' or 'on'.
    R.OverlapNIRSWIRAlgorithmEnabled = 'Yes';
    T.OverlapNIRSWIRAlgorithmEnabled = 'Yes';
else
    R.OverlapNIRSWIRAlgorithmEnabled = 'Unknown';
    T.OverlapNIRSWIRAlgorithmEnabled = 'Unknown';
end

referenceMatchingString = cell2mat(regexp(file, 'factors= ([-\+\.\d]+), [-\+\.\d]+, [-\+\.\d]+', 'tokens', 'once', 'lineanchors'));
targetMatchingString = cell2mat(regexp(file, 'factors= [-\+\.\d]+, ([-\+\.\d]+), [-\+\.\d]+', 'tokens', 'once', 'lineanchors'));
if ~isempty(referenceMatchingString)
    R.OverlapMatchingFactor = str2double(referenceMatchingString);
else
    R.OverlapMatchingFactor = 'Not applicable';
end
if ~isempty(targetMatchingString)
    T.OverlapMatchingFactor = str2double(targetMatchingString);
else
    T.OverlapMatchingFactor = 'Not applicable';
end

% The following line is commented out because this script does not
% import the _reflectance_ spectrum from the data file.
% reflectanceMatchingString = cell2mat(regexp(file, 'factors= [-\+\.\d]+, [-\+\.\d]+, ([-\+\.\d]+)', 'once', 'lineanchors'));

% GPS
% Determine whether GPS was active. If it was, read the GPS
% coordinates.

if regexp(file, '^longitude=\s+,\s+$', 'lineanchors')
    % If GPS not inactive then the longitude filed will contain only
    % whitespace.
    R.GPSActive = 'No';
    T.GPSActive = 'No';
    % Set coordinates to unknown.
    R.GPSCoordinates = 'Unknown';
    T.GPSCoordinates = 'Unknown';
end
if regexp(file, '^longitude=.*?\d+.*?$', 'lineanchors')
    % GPS was active when the reference spectrum was recorded.
    R.GPSActive = 'Yes';
    referenceLongitudeDegrees = str2double(regexp(file, '^longitude=\s*(\d\d\d)\d\d\.\d+', 'lineanchors', 'tokens', 'once'));
    referenceLongitudeMinutes = str2double(regexp(file, '^longitude=\s*\d\d\d(\d\d\.\d+)', 'lineanchors', 'tokens', 'once'));
    referenceLongitudeDirection = char(regexp(file, '^longitude=\s*[\d\.]+,([EW]),', 'lineanchors', 'tokens', 'once'));
    referenceLatitudeDegrees = str2double(regexp(file, '^latitude=\s*(\d\d)\d\d\.\d+', 'lineanchors', 'tokens', 'once'));
    referenceLatitudeMinutes = str2double(regexp(file, '^latitude=\s*\d\d(\d\d\.\d+)', 'lineanchors', 'tokens', 'once'));
    referenceLatitudeDirection = char(regexp(file, '^latitude=\s*[\d\.]+,([NS]),', 'lineanchors', 'tokens', 'once'));
    % Convert directions to signs.
    % East is positive, west is negative.
    % North is positive, south is negative.
    if referenceLongitudeDirection == 'E'
        referenceLongitudeSign = 1;
    else
        referenceLongitudeSign = -1;
    end
    if referenceLatitudeDirection == 'N'
        referenceLatitudeSign = 1;
    else
        referenceLatitudeSign = -1;
    end    
    % Convert to a row vector giving the GPS coordinates (latitude, longitude) in decimal degrees.
    R.GPSCoordinates = [ referenceLatitudeSign * (referenceLatitudeDegrees + referenceLatitudeMinutes / 60),
                         referenceLongitudeSign * (referenceLongitudeDegrees + referenceLongitudeMinutes / 60) ]';    
end
if regexp(file, '^longitude=.*?,\s*\d+', 'lineanchors')
    T.GPSActive = 'Yes';
    targetLongitudeDegrees = str2double(regexp(file, '^longitude=\s*[\d\.]+,\S,\s*(\d\d\d)\d\d\.\d+', 'lineanchors', 'tokens', 'once'));
    targetLongitudeMinutes = str2double(regexp(file, '^longitude=\s*[\d\.]+,\S,\s*\d\d\d(\d\d\.\d+)', 'lineanchors', 'tokens', 'once'));
    targetLongitudeDirection = char(regexp(file, '^longitude=\s*[\d\.]+,\S,\s*[\d\.]+,([EW])', 'lineanchors', 'tokens', 'once'));
    targetLatitudeDegrees = str2double(regexp(file, '^latitude=\s*[\d\.]+,\S,\s*(\d\d)\d\d\.\d+', 'lineanchors', 'tokens', 'once'));
    targetLatitudeMinutes = str2double(regexp(file, '^latitude=\s*[\d\.]+,\S,\s*\d\d(\d\d\.\d+)', 'lineanchors', 'tokens', 'once'));
    targetLatitudeDirection = char(regexp(file, '^latitude=\s*[\d\.]+,\S,\s*[\d\.]+,([NS])', 'lineanchors', 'tokens', 'once'));
    if targetLongitudeDirection == 'E'
        targetLongitudeSign = 1;
    else
        targetLongitudeSign = -1;
    end
    if targetLatitudeDirection == 'N'
        targetLatitudeSign = 1;
    else
        targetLatitudeSign = -1;
    end
    T.GPSCoordinates = [ targetLatitudeSign * (targetLatitudeDegrees + targetLatitudeMinutes / 60),
                         targetLongitudeSign * (targetLongitudeDegrees + targetLongitudeMinutes / 60) ]';    
end

% If necessary, GPS coordinates could be converted to an
% Ordnance Survey grid reference. This could be achieved with a
% publically-available conversion program. The lines commented
% out below illustrate how to do this with a Java program
% called JCoord.            
% 1. Download the Java archive (JAR file):
%    http://www.jstott.me.uk/jcoord/
% 2. Add the file to the Java class path, e.g.:
%    javaaddpath('jcoord-1.0.jar')
% 3. Convert coordinates to grid reference:
%    R.OSGridReference = uk.me.jstott.jcoord.LatLng(R.GPSCoordinates(1), R.GPSCoordinates(2)).toOSRef.toSixFigureString()

% Get the GPS time if it is present.
referenceGPSTime = regexp(file, '^gpstime=\s*(\d\d)(\d\d)([\d\.]+)', 'tokens', 'once', 'lineanchors');
if ~isempty(referenceGPSTime)
    R.GPSTime = char(strcat(referenceGPSTime(1), ':', referenceGPSTime(2), ':', referenceGPSTime(3), 'Z'));
else
    R.GPSTime = 'Unknown';
end
targetGPSTime = regexp(file, '^gpstime=\s*[\d\.]+\s*,\s*(\d\d)(\d\d)([\d\.]+)', 'tokens', 'once', 'lineanchors');
if ~isempty(targetGPSTime)
    T.GPSTime = char(strcat(targetGPSTime(1), ':', targetGPSTime(2), ':', targetGPSTime(3), 'Z'));
else
    T.GPSTime = 'Unknown';
end

% Read the coments.
R.Comments = deblank(char(regexp(file, 'comm=(.*?)$', 'tokens', 'once', 'lineanchors')));
T.Comments = R.Comments;
end

