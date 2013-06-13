%Script for the first run of the code.
%
%In this script we intentionally disabled the mechanisms that the
%code uses to skip old and already-checked logs or the attachments
%it processed before. As a result, the code will process all server logs.

maxdate=0;
save('maxdate.mat', 'maxdate');
processedlist=cell(1,0);
save('processedlist.mat','processedlist')
run main