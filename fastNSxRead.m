function [Header,varargout] = fastNSxRead(varargin)

% Converts NSx files to MAT files and saves as *.nsxmat within the same
% directory as the source. The function has a single input that is the full
% file name (FNameIn) to the NSx file to be converted. NSxMat file is matlab
% filespec v7.3, which can be indexed using the function "matfile".
% Converts neuroshare filespec 2.1, 2.2, and 2.3.
%
% Example: [header, D] = fastNSxRead('File', NS5file);
% Example: [Header, D] = fastNSxRead('File', ns5file, 'Range', NIPRange);
% %NIP range = [startSample, endSample] e.g. NIPRange = [30e3*1, 30e3*200]
% note for NS2 files, niprange is in 1khz, and should be ROUNDED
%
% Version Date: 20160614
% Author: Tyler Davis
%
% Changelog:
% 20160614-td: Added NIPStart to header


% Parsing input
p = inputParser;
defaultRange = [];
defaultFile = '';
addParameter(p,'Range',defaultRange,@(x)length(x)==2);
addParameter(p,'File',defaultFile,@(x)exist(x,'file'));
parse(p,varargin{:});

% Defining variables
Range = p.Results.Range;
FNameIn = p.Results.File;

if isempty(FNameIn)
    [PathIn,NameIn,ExtIn] = lastPath('\*.ns?','Choose nsx file...');
    FNameIn = fullfile(PathIn,[NameIn,ExtIn]);
end

switch FNameIn{1}(end-2:end)
    case 'ns6' % smw
        Header.Fs = 30000;
    case 'ns5'
        Header.Fs = 30000;
    case 'ns4'
        Header.Fs = 10000;
    case 'ns3'
        Header.Fs = 2000;
    case 'ns2'
        Header.Fs = 1000;
    otherwise
        disp('Choose an NSx file')
        return
end

% Getting fileid
FID = fopen(FNameIn, 'r', 'l');
Header.FileID = fread(FID, [1,8], '*char');

% Reading NSx file header
if strcmp(Header.FileID,'NEURALSG') %v2.1    
    Header.FsStr        = fread(FID, [1,16],  '*char');
    Header.Period       = fread(FID, [1,1],   '*uint32');
    Header.ChannelCount = fread(FID, [1,1],   'uint32=>double');
    for k = 1:Header.ChannelCount
        Header.ChannelID(k,:) = fread(FID, [1,1],  '*uint32');
    end
else %v2.2 or v2.3
    Header.FileSpec     = fread(FID, [1,2],   '*uchar');
    Header.HeaderBytes  = fread(FID, [1,1],   '*uint32');
    Header.FsStr        = fread(FID, [1,16],  '*char');
    Header.Comment      = fread(FID, [1,252], '*char');
    Header.NIPStart     = fread(FID, [1,1],   '*uint32');
    Header.Period       = fread(FID, [1,1],   '*uint32');
    Header.Resolution   = fread(FID, [1,1],   '*uint32');
    Header.TimeOrigin   = fread(FID, [1,8],   '*uint16');
    Header.ChannelCount = fread(FID, [1,1],   'uint32=>double');    
    for k = 1:Header.ChannelCount
        Header.Type(k,:)           = fread(FID, [1,2],  '*char');
        Header.ChannelID(k,:)      = fread(FID, [1,1],  '*uint16');
        Header.ChannelLabel(k,:)   = fread(FID, [1,16], '*char');
        Header.PhysConnector(k,:)  = fread(FID, [1,1],  '*uint8');
        Header.ConnectorPin(k,:)   = fread(FID, [1,1],  '*uint8');
        Header.MinDigVal(k,:)      = fread(FID, [1,1],  '*int16');
        Header.MaxDigVal(k,:)      = fread(FID, [1,1],  '*int16');
        Header.MinAnlgVal(k,:)     = fread(FID, [1,1],  '*int16');
        Header.MaxAnlgVal(k,:)     = fread(FID, [1,1],  '*int16');
        Header.Units(k,:)          = fread(FID, [1,16], '*char');
        Header.HighFreqCorner(k,:) = fread(FID, [1,1],  '*uint32');
        Header.HighFreqOrder(k,:)  = fread(FID, [1,1],  '*uint32');
        Header.HighFiltType(k,:)   = fread(FID, [1,1],  '*uint16');
        Header.LowFreqCorner(k,:)  = fread(FID, [1,1],  '*uint32');
        Header.LowFreqOrder(k,:)   = fread(FID, [1,1],  '*uint32');
        Header.LowFiltType(k,:)    = fread(FID, [1,1],  '*uint16');
    end        
end

BegOfDataHeader = ftell(FID);
fseek(FID, 0, 'eof');
EndOfFile = ftell(FID);
fseek(FID, BegOfDataHeader, 'bof');

% Checking for multiple data headers (v2.2 and v2.3 only) and calculating
% channel length
if strcmp(Header.FileID,'NEURALSG')
    Header.DataBytes = EndOfFile - BegOfDataHeader;
    Header.ChannelSamples = Header.DataBytes/Header.ChannelCount/2;
else
    k = 1;
    while ftell(FID)~=EndOfFile
        DataHeader(k,1) = fread(FID, [1,1], '*uint8'); %This value should always be 1
        if DataHeader(k,1)~=1
            disp('Error reading data headers!')
            return
        end
        DataTimestamp(k,1) = fread(FID, [1,1], '*uint32');
        ChannelSamples(k,1) = fread(FID, [1,1], 'uint32=>double');
        BegOfData(k,1) = ftell(FID); %Location of data after data header
        if ~ChannelSamples(k,1) %Stop if length data is zero
            DataBytes(k,1) = EndOfFile - BegOfData(k,1);
            ChannelSamples(k,1) = DataBytes/Header.ChannelCount/2;
            break
        end
        fseek(FID,ChannelSamples(k,1)*Header.ChannelCount*2,'cof');
        DataBytes(k,1) = ftell(FID) - BegOfData(k,1);
        k = k+1;
    end
    
    % Check if pauses exist in data
    if (length(DataHeader)==2 && ChannelSamples(1)~=1) || length(DataHeader)>2
        disp('Pauses exist in this data set! This version of nsx2mat cannot parse paused data')
        return
    end
    
    % Check if data length in header is equal to calculated data length
    if DataBytes(end)~=ChannelSamples(end)*Header.ChannelCount*2
        disp('Header and calculated data lengths are different!')
        return
    end
    
    % Move back to beginning of last data segment
    fseek(FID,BegOfData(end),'bof');
    
    % Discarding info from extra data header and updating main header
    % An extra data header and a single sample of data are found when files are automatically split using firmware 6.03
    Header.DataBytes = DataBytes(end);
    Header.ChannelSamples = ChannelSamples(end);
    
    % Modifying header for split files
    if DataTimestamp(end)>0
        Header.ChannelSamples = Header.ChannelSamples + DataTimestamp(end) - 1;
    end
end

if nargout>1
    % Determining system memory to maximize data segments
    SystemMemory = regexp(evalc('feature memstats'),'\d*(?= MB)','match');
    SystemMemory = str2double(SystemMemory{2})*1e6; % Units bytes
    
    if isempty(Range)
        MaxSamples = floor((0.75*SystemMemory)/Header.DataBytes*Header.ChannelSamples);
        Range = [1,min(MaxSamples,Header.ChannelSamples)];
    end
    
    % Seeking to beginning of data segment
    fseek(FID,BegOfData(end)+(Range(1)-1)*2*Header.ChannelCount,'bof');
    
    % Reading data
    fprintf('Loading %0.1f GB of data\n',(diff(Range)+1)*2*Header.ChannelCount/1e9)
    varargout{1} = fread(FID,[Header.ChannelCount,(diff(Range)+1)],'*int16');
end

% Closing file
fclose(FID);






