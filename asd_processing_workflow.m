function [processedlist]=asd_processing_workflow(a, b, config, ID, F_index, Featureclassstrings, processedlist)

%Spectral data processing workflow for ASD data
% Written by:
% Mojtaba Karami
%   Email address:
%   m-karami@mscstu.scu.ac.ir
%   noetic.pandas@gmail.com
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
%[additive_approach multiplicative_approach]=jumpcorrection(DNs);
[ad m]=asd_jumpcorrection(b);%call jump correction function
%write results to ascii files
fid=fopen([config{9} 'Jumpcorrection_Additive.ascii'],'w+');
fprintf(fid,'%s\r\n','Jump Correction for ASD spectra: Additive approach');
fprintf(fid,'%s\r\n','Wavelength, Data');
fprintf(fid,'%f, %f\r\n',[a ad]');
fclose(fid);
fid=fopen([config{9} 'Jumpcorrection_Multiplicative.ascii'],'w+');
fprintf(fid,'%s\r\n','Jump Correction for ASD spectra: Multiplicative approach');
fprintf(fid,'%s\r\n','Wavelength, Data');
fprintf(fid,'%f, %f\r\n',[a m]');
fclose(fid);

%Perform Smoothing:
%For the results of Additive approach
[S_ad]=asd_smooth(a, ad);
%For the results of Multiplicative approach
[S_m]=asd_smooth(a, m);
%write to ascii files
fid=fopen([config{9} 'Smoothing_and_Jumpcorrection_Additive.ascii'],'w+');
fprintf(fid,'%s\r\n','Smoothing and Jump Correction for ASD spectra: Additive approach');
fprintf(fid,'%s\r\n','Wavelength, Data');
fprintf(fid,'%f, %f\r\n',[a S_ad]');
fclose(fid);
fid=fopen([config{9} 'Smoothing_and_Jumpcorrection_Multiplicative.ascii'],'w+');
fprintf(fid,'%s\r\n','Smoothing and Jump Correction for ASD spectra: Multiplicative approach');
fprintf(fid,'%s\r\n','Wavelength, Data');
fprintf(fid,'%f, %f\r\n',[a S_m]');
fclose(fid);
%draw and save comparison plot
h=figure('visible','off');
plot(a, S_m,a , b)
legend('Smoothed and Jump-Corrected','Original')
grid on
xlabel('\fontsize{16}\lambda \it\fontsize{12}(nm)')
ylabel('\fontsize{16}Value')
axis([350 2500 0 1.2*max(S_m)]);
saveas(h,[config{9} 'Plot.png'])
close(h)
%Compress The files: produce ZIP file
zip([config{9} 'ASGP_Processed'],{[config{9} '*.ascii'] [config{9} 'Plot.png'] 'speclogo.png'})
delete([config{9} '*.ascii'])
delete([config{9} 'Plot.png'])

%getting ready for upload:
filepath=[config{9} 'ASGP_Processed.zip'];% build file-name string
%extract rest address from config, using third part of the original filename (feature-type index)
rest=config{Featureclassstrings{3,F_index}};

%upload the file using rest interface
[ATTOID,status] = upload(filepath,ID,rest);%remember to put upload function where it has access to urlreadwrite function

if status==1;%successful? if yes, add to the list of processed attachments
processedlist=[processedlist [num2str(ID) '-' num2str(ATTOID) '_' num2str(F_index)]];
end

end