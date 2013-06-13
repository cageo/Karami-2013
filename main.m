%Main script of the ASGP algorithm.
%|-------------------------------------------------------------------------|
%| If it's the first time you run this code, please run FIRSTRUN.m instead.|
%|-------------------------------------------------------------------------|
%This script runs once over the entire workflow including:search through logs,...
%calculate MCI for metadata updates, perform corrections and smoothing, upload proceesing zip package to server 
%
%Written by:
% Mojtaba Karami
%  Email address:
%  m-karami@mscstu.scu.ac.ir
%  noetic.pandas@gmail.com
%
% Copyright (c) 2012, Mojtaba Karami
% All rights reserved.
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
%

disp('<< ASGP Spectral Extension >>')
%1___Extract Feature and Attachment OIDs from server logs
%read config
fid=fopen('config.txt');
config=textscan(fid, '%q', 'commentStyle', '//');
config=config{1,1};
fclose(fid);

%create workspace
[status,mkwrkspcmsg] = mkdir(config{9});
if strcmp(mkwrkspcmsg,'Directory already exists.')
    rmdir(config{9},'s');
    mkdir(config{9});
end
mkdir([config{9} 'downloaded\']);

%extract arcgis server log filenames
filelist=dir([config{1} '*.dat']);
filenames={filelist.name};

    
%extract log file dates
datesnum=[filelist.datenum];
%compare to max date from previous run and keep filenames recent
%files
load('maxdate.mat');
selectedfiles=filenames(datesnum>maxdate);
maxdate=max(datesnum);
save('maxdate.mat', 'maxdate');

%preallocate OIDs with this format [FeatureOID AttachmentOID Featurecode]
%and updatesOID with this format [FeatureOID Featurecode]
 OIDs=zeros(100,3);
 updatesOID=zeros(100,2);
 number=1;
 number2=1;
 disp('Analyzing GISserver logs...')
 %loop to process files consequtively
  for i=1:size(selectedfiles,2)
 %import file to cell array: log
 log=importdata([config{1} selectedfiles{i}]);
 
 %find attachment process log lines and position
 findattachmentacts=[regexp(log, 'Success = True while adding Attachment (with OID: ') regexp(log, ' ) to Feature/ Object with OID: ')];
 
 %extract object IDs (attach. and sampling points) from log  using the findattachmentacts array
    for j=1:size(log,1)
         if size(findattachmentacts{j,1},1)==1
             %find Attachment OID==>
             str=log{j}(findattachmentacts{j,1}+47:findattachmentacts{j,1}+58);
             str=str(isstrprop(str, 'digit'));
             OIDs(number,2)=str2double(str);
             %find Feature OID==>
             str=log{j}(findattachmentacts{j,2}+28:findattachmentacts{j,2}+39);
             str=str(isstrprop(str, 'digit'));
             OIDs(number,1)=str2double(str);
             
             OIDs(number,3)=[(log{j}(findattachmentacts{j,2}+50+size(str,2)))*(log{j}(findattachmentacts{j,2}+51+size(str,2)))];
             number=number+1;
         end
         
    end

    
     %now search for metadata updates:
     findMetadataUpdates=regexp(log, 'Updated Feature/ Object with ObjectID: ');
     %extract OID of metadata updates
     for j=1:size(log,1)
         if size(findMetadataUpdates{j,1},1)==1
            str2=log{j}(findMetadataUpdates{j}+37:findMetadataUpdates{j}+45);
            str2=str2(isstrprop(str2,'digit'));
            updatesOID(number2,1)=str2double(str2);%OID
            updatesOID(number2,2)=[(log{j}(findMetadataUpdates{j}+57+size(str2,2)))*(log{j}(findMetadataUpdates{j}+58+size(str2,2)))];%feature class: multiply the two first charachters to get a unieque number
            number2=number2+1;
         end
     end
  end
disp('Done')
%[polish updatesOID:]
%clip free preallocated space of updatesOID
updatesOID=updatesOID(1:number2-1,:);
%convert raw feature codes to indexes
updatesOID(updatesOID==8686)=1;
updatesOID(updatesOID==9102)=2;
updatesOID(updatesOID==7957)=3;
updatesOID(updatesOID==9213)=4;
updatesOID(updatesOID==8439)=5;
updatesOID(updatesOID==9130)=6;
%delete repeated rows
updatesOID=unique(updatesOID,'rows');
%execute metadata quality calculator
[updatesOID]=MetaQ(updatesOID);


%[polish OIDs:]
%clip free preallocated space of OIDs
OIDs=OIDs(1:number-1,:);
%convert raw feature codes to indexes
OIDs(OIDs==8686)=1;
OIDs(OIDs==9102)=2;
OIDs(OIDs==7957)=3;
OIDs(OIDs==9213)=4;
OIDs(OIDs==8439)=5;
OIDs(OIDs==9130)=6;
%compare to previous processed files and delete repeated imports from OIDs
load('processedlist.mat')
for i=size(OIDs,1):-1:1
        if sum(strcmp([int2str(OIDs(i,1)) '-' int2str(OIDs(i,2)) '_' int2str(OIDs(i,3))],processedlist))>0
            OIDs(i,:)=[];
        end
end



%update max date file
maxdate=max(datesnum);
save('maxdate.mat', 'maxdate');
clear fid str datesnum updatesOID Featurecalc filelist filenames findattachmentacts j log maxdate number selectedfiles


%2____Import Attachment files using OIDs


%Build a set of strings, to use in queries and title of figures. OIDs(:,3) will
%be used as index to reach proper strings in Featureclassstrings:
%preallocate
Featureclassstrings=cell(6,4);
%Build Featureclass names to use in figures
Featureclassstrings{1,1}='Vegetation';
Featureclassstrings{1,2}='Rocks';
Featureclassstrings{1,3}='Impervious/Man-made';
Featureclassstrings{1,4}='Soil';
Featureclassstrings{1,5}='Water';
Featureclassstrings{1,6}='Snow/Ice';
%Build Attachment table names to use in queries
Featureclassstrings{2,1}='VEGETATION__ATTACH';
Featureclassstrings{2,2}='ROCKS__ATTACH';
Featureclassstrings{2,3}='IMPERVIOUS__ATTACH';
Featureclassstrings{2,4}='SOIL__ATTACH';
Featureclassstrings{2,5}='WATER__ATTACH';
Featureclassstrings{2,6}='SNOW__ATTACH';
%Build indexes in order to import REST interface URLs from config file
Featureclassstrings{3,1}=3;
Featureclassstrings{3,2}=4;
Featureclassstrings{3,3}=5;
Featureclassstrings{3,4}=6;
Featureclassstrings{3,5}=7;
Featureclassstrings{3,6}=8;
%Build Feature Table names to use in inserts
Featureclassstrings{4,1}='SDE.VEGETATION';
Featureclassstrings{4,2}='SDE.ROCKS';
Featureclassstrings{4,3}='SDE.IMPERVIOUS';
Featureclassstrings{4,4}='SDE.SOIL';
Featureclassstrings{4,5}='SDE.WATER';
Featureclassstrings{4,6}='SDE.SNOW';


%direct connect to DB using SDE user, download and save attachment files
%------------------------------------
%|    Modify your ODBC connection   |
%|    data here:                    |
%|    NAME,USERNAME, and PASSWORD   |
%------------------------------------
conn=database('<ODBC connection name>','<SDE username>','<SDE password>');
disp('Importing spectral data from Database...')
for i=1:size(OIDs,1)
downloadeddata=fetch(conn, ['SELECT ALL REL_OBJECTID, ATTACHMENTID, ATT_NAME, DATA FROM SDE.' Featureclassstrings{2,OIDs(i,3)} ' WHERE ATTACHMENTID=' num2str(OIDs(i,2))]);
fid=fopen([config{9} 'downloaded\' num2str(OIDs(i,1)) '-' num2str(OIDs(i,2)) '_' num2str(OIDs(i,3)) downloadeddata{1,3}(max(regexp(downloadeddata{1,3},'\.')):size(downloadeddata{1,3},2))],'w');
fwrite(fid, downloadeddata{1,4}, 'int8');
fclose('all');
end
disp('Done')
clear count downloadeddata


%3____call plot-and-upload script
run plotandupload
close(conn);
if size(dir([config{9} '*.png']),1)>0
    disp(['<<' num2str(size(dir([config{9} '*.png']),1)) ' plots successfully generated.>>'])
else
    disp('No plots created!')
end




rmdir([config{9} 'downloaded\'],'s')
delete([config{9} '*.*'])
save('processedlist.mat','processedlist')
clear all