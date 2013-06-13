%This workflow script:
%a> makes .png plots
%b> updates plot path in DB Table (Geodatabase fields) through ODBC 
%c> copies generated plot files to shared directory of Web server
%d> executes the spectral processing workflow (jump correction, smoothing, zip package, upload the package through REST interface)
%
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
%

%3____process workspace files,
%provide seperate lists for known file types
filelist=[dir([config{9} 'downloaded\*.txt']);dir([config{9} 'downloaded\*.ascii'])];
ascii={filelist.name};
filelist=[dir([config{9} 'downloaded\*.asd']);dir([config{9} 'downloaded\*.0*']);dir([config{9} 'downloaded\*.1*']);dir([config{9} 'downloaded\*.2*']);dir([config{9} 'downloaded\*.3*']);dir([config{9} 'downloaded\*.4*']);dir([config{9} 'downloaded\*.5*']);dir([config{9} 'downloaded\*.6*']);dir([config{9} 'downloaded\*.7*']);dir([config{9} 'downloaded\*.8*']);dir([config{9} 'downloaded\*.9*'])];
asds={filelist.name};
filelist=dir([config{9} 'downloaded\*.sig']);
sigfiles={filelist.name};
%a list of envi files and other file formats should be added here. Further, a seperate loop should be
%added in order to import them.

disp('Processing SIG files...')
%plot .sig
for i=1:size(sigfiles,2)
    %add filename (ObjID-AttchID_FeatureID) to processed list before
    %beginning of the Import process. This way, if the script stopped by an error, the file
    %is automaticlly blacklisted, and in the next run the script wont process it. 
    processedlist=[processedlist sigfiles{i}(1:regexp(sigfiles{i},'\.')-1)];
    [target reference] = importsvc([config{9} 'downloaded\' sigfiles{i}]);
    %extract OID from filename
    ID=sigfiles{i}(1:regexp(sigfiles{i}, '-')-1);
    F_index=str2double(sigfiles{i}(regexp(sigfiles{i},'_')+1:regexp(sigfiles{i},'\.')-1));
    h=figure('visible','off');
    plot(target.wavelength,target.data,'linewidth',2,'Color','b')
    grid on
    xlabel('\fontsize{16}\lambda \it\fontsize{12}(nm)')
    ylabel('\fontsize{16}Value')
    title({['\fontsize{18}\bf Object no. ' ID];cell2mat(['\it\fontsize{18}\bf (' Featureclassstrings(1,OIDs(OIDs(:,1)==str2double(ID)&OIDs(:,3)==str2double(sigfiles{i}(regexp(sigfiles{i},'_')+1:regexp(sigfiles{i},'\.')-1)),3)) ')'])})
    axis([350 2500 0 1.2*max(target.data)]);
    %save plot
    saveas(h,[config{9} sigfiles{i} '.png'])
    close(h)
    %update image path using update: (connection structure, table name string, fieldname, url, whereclause)
    whereclause=['where OBJECTID = ' ID];
    update(conn, Featureclassstrings{4,F_index}, {'PLOT'}, {[config{11} sigfiles{i} '.png']} , whereclause)
    %copy plot to Webserver shared directory
    copyfile([config{9} sigfiles{i} '.png'],config{10});
    %process and upload
    [processedlist]=svc_processing_workflow(target, reference, config, ID, F_index, Featureclassstrings, processedlist);
end
disp('Done')

disp('Processing ASD files...')
%plot .asd/.000/etc
for i=1:size(asds,2)
    processedlist=[processedlist asds{i}(1:regexp(asds{i},'\.')-1)];
    [measuredSpectrum, lambda] = importasd([config{9} 'downloaded\' asds{i}]);
    %extract OID from filename
    ID=asds{i}(1:regexp(asds{i}, '-')-1);
    F_index=str2double(asds{i}(regexp(asds{i},'_')+1:regexp(asds{i},'\.')-1));
    h=figure('visible','off');
    plot(lambda,measuredSpectrum,'linewidth',2,'Color','b')
    grid on
    xlabel('\fontsize{16}\lambda \it\fontsize{12}(nm)')
    ylabel('\fontsize{16}Value')
    title({['\fontsize{18}\bf Object no. ' ID];cell2mat(['\it\fontsize{18}\bf (' Featureclassstrings(1,OIDs(OIDs(:,1)==str2double(ID)&OIDs(:,3)==str2double(asds{i}(regexp(asds{i},'_')+1:regexp(asds{i},'\.')-1)),3)) ')'])})
    axis([350 2500 0 1.2*max(measuredSpectrum)]);
    %save plot
    saveas(h,[config{9} asds{i} '.png'])
    close(h)
    %update image path using update: (connection structure, table name string, fieldname, url, whereclause)
    whereclause=['where OBJECTID = ' ID];    
    update(conn, Featureclassstrings{4,F_index}, {'PLOT'}, {[config{11} asds{i} '.png']} , whereclause)
    %copy plot to Webserver shared directory
    copyfile([config{9} asds{i} '.png'],config{10});
    
    %process and upload
    a=lambda;
    b=measuredSpectrum;
    [processedlist]=asd_processing_workflow(a, b, config, ID, F_index, Featureclassstrings, processedlist);
end
disp('Done')
%plot .txt and ascii
disp('Processing ASCII and TXT...')
for i=1:size(ascii,2)
    processedlist=[processedlist ascii{i}(1:regexp(ascii{i},'\.')-1)];
    %read and extract data
    a=fileread([config{9} 'downloaded\' ascii{i}]);
    a=regexprep(a, '\r', '');
    dataStructure = regexp(a, '^(?<wavelength>[\.\d]+)[;,\s]+(?<data>[eE-\+\.\d]+)', 'names', 'lineanchors');
    wavelength = str2double({dataStructure.wavelength});
    data = str2double({dataStructure.data});
    %extract OID from filename
    ID=ascii{i}(1:regexp(ascii{i}, '-')-1);
    F_index=str2double(ascii{i}(regexp(ascii{i},'_')+1:regexp(ascii{i},'\.')-1));
    %plot
    h=figure('visible','off');
    plot(wavelength,data,'linewidth',2,'Color','b')
    grid on
    xlabel('\fontsize{16}\lambda \it\fontsize{12}(nm)')
    ylabel('\fontsize{16}Value')
    title({['\fontsize{18}\bf Object no. ' ID];cell2mat(['\it\fontsize{18}\bf (' Featureclassstrings(1,OIDs(OIDs(:,1)==str2double(ID)&OIDs(:,3)==str2double(ascii{i}(regexp(ascii{i},'_')+1:regexp(ascii{i},'\.')-1)),3)) ')'])})
    axis([350 2500 0 1.2*max(data)]);
    %save plot
    saveas(h,[config{9} ascii{i} '.png'])
    close(h)
    %update image path using update: (connection structure, table name string, fieldname, url, whereclause)
    whereclause=['where OBJECTID = ' ID];
    update(conn, Featureclassstrings{4,F_index}, {'PLOT'}, {[config{11} ascii{i} '.png']} , whereclause)
    %copy plot to Webserver shared directory
    copyfile([config{9} ascii{i} '.png'],config{10});
    
    %process and upload
    a=wavelength';
    b=data';
    %ASD, SVC-HR1024 or SVC-1500?
    switch size(b,1)
        case 2151
    [processedlist]=asd_processing_workflow(a, b, config, ID, F_index, Featureclassstrings, processedlist);
        case 1024
    [processedlist]=svc_processing_workflow(target, reference, config, ID, F_index, Featureclassstrings, processedlist);        
        case 256
    [processedlist]=svc_processing_workflow(target, reference, config, ID, F_index, Featureclassstrings, processedlist);        
    end
end
disp('Done')

close(conn)
close all
clear a b lambda fid filelist dataStructure data ans h target measuredSpectrum wavelength 