function [processedlist]=svc_processing_workflow(target, reference, config, ID, F_index, Featureclassstrings, processedlist)
% Spectral data processing workflow for SVC data
%
%inputs:
%   target: vector of measured values
%   reference: vactor of reference values
%   config: configurations cell array (see main.m)
%   ID: feature's ObjectID
%   F_index: index for the feature type (see main.m)
%   featureclassstrings: cell array of featureclass strings (see main.m)
%   processedlist: a list of processed ObjectIDs
%
%outputs:
%   processedlist: an updated list of processed ObjectIDs
%
%This function is written by:
% Mojtaba Karami
%  Email address:
%  m-karami@mscstu.scu.ac.ir
%  noetic.pandas@gmail.com
%
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
%%%%%%%%%%%%%%%%%%%%%%%%<<<<<<<is it HR1024? it has 1024 bands>>>>>>>>>>>> 
if size(target.data,1)==1024
    %remove overlaps
    %number of bands will change from 1024 to 1007
    target = svc_removeoverlap(target,1000);
    reference = svc_removeoverlap(reference,1000);
    %estimate the correct gradient at the jump point
    t1=(((target.data(505)-target.data(504))/(target.wavelength(505)-target.wavelength(504)))+((target.data(507)-target.data(506))/(target.wavelength(507)-target.wavelength(506))))/2;
    t2=(((reference.data(505)-reference.data(504))/(reference.wavelength(505)-reference.wavelength(504)))+((reference.data(507)-reference.data(506))/(reference.wavelength(507)-reference.wavelength(506))))/2;
    %gradient to value:
    t1=t1*(target.wavelength(506)-target.wavelength(505));
    t2=t2*(reference.wavelength(506)-reference.wavelength(505));
    %compute an offset to correct the jump at the point, detector 1 is reference:
    offset1=target.data(505)-target.data(506)+t1;
    offset2=reference.data(505)-reference.data(506)+t2;
    
    %perform additive correction
    target_additive=target.data;
    target_additive(506:1007)=target.data(506:1007)+offset1;
    reference_additive=reference.data;
    reference_additive(506:1007)=reference.data(506:1007)+offset2;
    
    %perform multiplicative correction
    %compute coefficients
    c1=(target.data(506)+offset1)/target.data(506);
    c2=(reference.data(506)+offset2)/reference.data(506);
    
    target_multiplicative=target.data;
    target_multiplicative(506:1007)=target.data(506:1007)*c1;
    reference_multiplicative=reference.data;
    reference_multiplicative(506:1007)=reference.data(506:1007)*c2;
    %export overlap-removed data to asciis
    fid=fopen([config{9} 'SVC_HR1024_Overlap-removed_additive.ascii'],'w+');
    fprintf(fid,'%s\r\n','Overlap remove and Jump correction at 1000nm for SVC-HR1024 spectra: Additive approach');
    fprintf(fid,'%s\r\n','Wavelength, Reflectance, Target, Reference');
    fprintf(fid,'%f, %f, %f, %f\r\n',[target.wavelength target_additive./reference_additive target_additive reference_additive]');
    fclose(fid);
    fid=fopen([config{9} 'SVC_HR1024_Overlap-removed_multiplicative.ascii'],'w+');
    fprintf(fid,'%s\r\n','Overlap remove and Jump correction at 1000nm for SVC-HR1024 spectra: Multiplicative approach');
    fprintf(fid,'%s\r\n','Wavelength, Reflectance, Target, Reference');
    fprintf(fid,'%f, %f, %f, %f\r\n',[target.wavelength target_multiplicative./reference_multiplicative target_multiplicative reference_multiplicative]');
    fclose(fid);
        
    %smooth additive and multiplicative reflectance
    smooth_additive=adsmoothdiff([target.wavelength target_additive./reference_additive],[min(target.wavelength):max(target.wavelength)]',10,0.8,5,7);
    smooth_multiplicative=adsmoothdiff([target.wavelength target_multiplicative./reference_multiplicative],[min(target.wavelength):max(target.wavelength)]',10,0.8,5,7);
    %export smoothed reflectances to asciis
    fid=fopen([config{9} 'SVC_HR1024_Smooth_Overlap-removed_additive_reflectance.ascii'],'w+');
    fprintf(fid,'%s\r\n','Smoothing, Overlap remove and Jump correction at 1000nm for SVC-HR1024 spectra: Additive approach');
    fprintf(fid,'%s\r\n','Wavelength, Reflectance');
    fprintf(fid,'%f, %f\r\n',[smooth_additive(:,1) smooth_additive(:,2)]');
    fclose(fid);
    fid=fopen([config{9} 'SVC_HR1024_Smooth_Overlap-removed_multiplicative_reflectance.ascii'],'w+');
    fprintf(fid,'%s\r\n','Smoothing, Overlap remove and Jump correction at 1000nm for SVC-HR1024 spectra: Multiplicative approach');
    fprintf(fid,'%s\r\n','Wavelength, Reflectance');
    fprintf(fid,'%f, %f\r\n',[smooth_multiplicative(:,1) smooth_multiplicative(:,2)]');
    fclose(fid);
    %draw and save comparison plot
    h=figure('visible','off');
    plot(smooth_multiplicative(:,1), smooth_multiplicative(:,2),target.wavelength, target.data./reference.data)
    legend('Smoothed and Corrected','Original')
    grid on
    xlabel('\fontsize{16}\lambda \it\fontsize{12}(nm)')
    ylabel('\fontsize{16}Value')
    axis([350 2500 0 1.2*max(smooth_multiplicative(:,2))]);
    saveas(h,[config{9} 'Plot.png'])
    close(h)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<<<<is it GER 1500? it has 256 bands>>>>>
elseif size(target.data,1)==256
    %warning: number of bands will change: no resampling method is implemented
    smooth=adsmoothdiff([target.wavelength target.data./reference.data],[target.wavelength(1):target.wavelength(256)]',10,0.8,5,7);
    fid=fopen([config{9} 'SVC_GER1500_Smooth_Reflectance.ascii'],'w+');
    fprintf(fid,'%s\r\n','Smoothing for SVC-GER1500 spectra');
    fprintf(fid,'%s\r\n','Wavelength, Reflectance');
    fprintf(fid,'%f, %f\r\n',[smooth(:,1) smooth(:,2)]');
    fclose(fid);
    %draw and save comparison plot
    h=figure('visible','off');
    plot(smooth(:,1), smooth(:,2),target.wavelength, target.data./reference.data)
    legend('Smoothed','Original')
    grid on
    xlabel('\fontsize{16}\lambda \it\fontsize{12}(nm)')
    ylabel('\fontsize{16}Value')
    axis([350 2500 0 1.2*max(smooth(:,2))]);
    saveas(h,[config{9} 'Plot.png'])
    close(h)
end

%Compress files
zip([config{9} 'ASGP_Processed'],{[config{9} '*.ascii'] [config{9} 'Plot.png'] 'speclogo.png'});
delete([config{9} '*.ascii']);
delete([config{9} 'Plot.png'])
%getting ready for upload
filepath=[config{9} 'ASGP_Processed.zip'];
%extract rest address from config, using third part of the original filename (feature-type index)
rest=config{Featureclassstrings{3,F_index}};

%upload the file using rest interface
[ATTOID,status] = upload(filepath,ID,rest);

if status==1;
processedlist=[processedlist [num2str(ID) '-' num2str(ATTOID) '_' num2str(F_index)]];
end
end