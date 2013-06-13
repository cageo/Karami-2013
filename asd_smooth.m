function [S]=asd_smooth(a, b)
% Adaptive smoothing workflow for ASD Fieldspec 3
% This workflow uses adsmoothfiff function for smoothing
% It estimates amount of noise using %RMSE over a 3rd order polynomial fit
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


%ESTIMATE WHETHER THE DATA IS LOWNOISE OR HIGHNOISE:
%evaluate a 3rd order polynomial fit: 
ynew=adsmoothdiff([a b],[350:2500]',20,0.8,3,4);
%calculate mean standard error of points
noise=mean(ynew(:,3));

    if noise>0.01   %<---- you can change this noisiness threshold value
        %<<HIGH NOISE SPECTRA>>

        %First, filter outliers
        b(b>1.1)=1.1;
        b(b<0)=0;
        %filtering outliers on 1st water apsorption band
        bbb=b(931:1171);
        i=mean(bbb);
        bbb(bbb>i*1.6)=i*1.1;
        bbb(bbb<i*0.6)=i*0.6;
        b(931:1171)=bbb;
        %filtering outliers on 2nd water apsorption band
        bbb=b(1251:1751);
        i=mean(bbb);
        bbb(bbb>i*1.6)=i*1.1;
        bbb(bbb<i*0.6)=i*0.6;
        b(1251:1751)=bbb;
        %filtering outliers on 3rd water apsorption band
        bbb=b(1701:2151);
        i=mean(bbb);
        bbb(bbb>i*1.6)=i*1.1;
        bbb(bbb<i*0.6)=i*0.6;
        b(1701:2151)=bbb;

        %smooth 1st water absorption band: 1400nm
        S=b;
        ynew=adsmoothdiff([a b],[1280:1520]',100,0.8,3,5);
        S(931:1171)=ynew(:,2);
        %smooth 2nd water absorption band: 1900nm
        ynew=adsmoothdiff([a b],[1600:2100]',150,0.8,3,5);
        S(1251:1751)=ynew(:,2);
        %smooth 3rd water absorption band: 2500nm (2900nm)
        ynew=adsmoothdiff([a b],[2050:2500]',150,0.8,3,5);
        S(1701:2151)=ynew(:,2);
        %smooth all spectra
        ynew=adsmoothdiff([a S],[350:2500]',50,0.8,4,5);
        S=ynew(:,2);
    else
        %<<<LOW NOISE SPECTRA>>>
        %use the existing 3rd order polynomial fit
        S=ynew(:,2);
    end

end