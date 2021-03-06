function [updatesOID]=MetaQ(updatesOID)
% This function evaluates MCI (Metadata Coverage Index) for updated
% records residing in ArcGIS feature server
%
% Written by:
% Mojtaba Karami
%   Email address:
%   m-karami@mscstu.scu.ac.ir
%   noetic.pandas@gmail.com
%
%
%   inputs: A list of ObjectIDs of the features (you may want to look at main.m to see how is it made) 
%   output: -
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


%------------------------------------
%|    Modify your ODBC connection   |
%|    data here:                    |
%|    NAME,USERNAME, and PASSWORD   |
%------------------------------------
conn=database('<ODBC connection name>','<SDE username>','<SDE password>');

disp('Calculating Metadata Quality (MCI) for new entries...')
%construct required query and insert strings
%if you need to modify the list of FILEDS, modify them here
mystrings=cell(6,2);
mystrings{1,1}='SELECT SDE.VEGETATION.OBJECTID,  SDE.VEGETATION.CAMPAIGNNAME,  SDE.VEGETATION.INVESTIGATOR,  SDE.VEGETATION.INSTRUMENT,  SDE.VEGETATION.FOREOPTIC,  SDE.VEGETATION.PLACENAME,  SDE.VEGETATION.LANDCOVER,  SDE.VEGETATION.CLOUDCOVER,  SDE.VEGETATION.CLOUDTYPE,  SDE.VEGETATION.WEATHER,  SDE.VEGETATION.ILLUMSOURCE,  SDE.VEGETATION.SNGLEMIX,  SDE.VEGETATION.RAWPROC,  SDE.VEGETATION.DESC_,  SDE.VEGETATION.DATE_,  SDE.VEGETATION.SCIENTIFICNAME,  SDE.VEGETATION.COMMONNAME_EN,  SDE.VEGETATION.COMMONNAME_LOCAL,  SDE.VEGETATION.SUBSPECIES,  SDE.VEGETATION.DENSITY,  SDE.VEGETATION.DEVELOPEMENTSTAGE,  SDE.VEGETATION.AGE,  SDE.VEGETATION.TEMP,  SDE.VEGETATION.PRESSURE,  SDE.VEGETATION.ILLUMINATIONZENITH,  SDE.VEGETATION.ILLUMINATIONAZIMUTH,  SDE.VEGETATION.SENSORZENITH,  SDE.VEGETATION.SENSORAZIMUTH,  SDE.VEGETATION.UNITS,  SDE.VEGETATION.DATAFORMAT,  SDE.VEGETATION.RELATIVEHUM,  SDE.VEGETATION.WINDSPEED,  SDE.VEGETATION.SENSORDIST,  SDE.VEGETATION.PLOT FROM SDE.VEGETATION';
mystrings{2,1}='SELECT SDE.ROCKS.OBJECTID,  SDE.ROCKS.CAMPAIGNNAME,  SDE.ROCKS.INVESTIGATOR,  SDE.ROCKS.INSTRUMENT,  SDE.ROCKS.FOREOPTIC,  SDE.ROCKS.PLACENAME,  SDE.ROCKS.LANDCOVER,  SDE.ROCKS.CLOUDCOVER,  SDE.ROCKS.CLOUDTYPE,  SDE.ROCKS.WEATHER,  SDE.ROCKS.ILLUMSOURCE,  SDE.ROCKS.SNGLEMIX,  SDE.ROCKS.RAWPROC,  SDE.ROCKS.DESC_,  SDE.ROCKS.DATE_,  SDE.ROCKS.FORMATION,  SDE.ROCKS.MINERAL,  SDE.ROCKS.MINERALCLASS,  SDE.ROCKS.FORMULAS,  SDE.ROCKS.GRAINSIZE,  SDE.ROCKS.NAME,  SDE.ROCKS.ROCKTYPESUBTYPE,  SDE.ROCKS.TEXTURE,  SDE.ROCKS.WEATHERED,  SDE.ROCKS.TEMP,  SDE.ROCKS.PRESSURE,  SDE.ROCKS.ILLUMINATIONZENITH,  SDE.ROCKS.ILLUMINATIONAZIMUTH,  SDE.ROCKS.SENSORZENITH,  SDE.ROCKS.SENSORAZIMUTH,  SDE.ROCKS.UNITS,  SDE.ROCKS.DATAFORMAT,  SDE.ROCKS.RELATIVEHUM,  SDE.ROCKS.WINDSPEED,  SDE.ROCKS.SENSORDIST,  SDE.ROCKS.PLOT FROM SDE.ROCKS';
mystrings{3,1}='SELECT SDE.IMPERVIOUS.OBJECTID,  SDE.IMPERVIOUS.CAMPAIGNNAME,  SDE.IMPERVIOUS.INVESTIGATOR,  SDE.IMPERVIOUS.INSTRUMENT,  SDE.IMPERVIOUS.FOREOPTIC,  SDE.IMPERVIOUS.PLACENAME,  SDE.IMPERVIOUS.LANDCOVER,  SDE.IMPERVIOUS.CLOUDCOVER,  SDE.IMPERVIOUS.CLOUDTYPE,  SDE.IMPERVIOUS.WEATHER,  SDE.IMPERVIOUS.ILLUMSOURCE,  SDE.IMPERVIOUS.SNGLEMIX,  SDE.IMPERVIOUS.RAWPROC,  SDE.IMPERVIOUS.DESC_,  SDE.IMPERVIOUS.DATE_,  SDE.IMPERVIOUS.FEATURETYPE,  SDE.IMPERVIOUS.AGE,  SDE.IMPERVIOUS.MATERIALS,  SDE.IMPERVIOUS.WET,  SDE.IMPERVIOUS.DUSTY,  SDE.IMPERVIOUS.PAINTED,  SDE.IMPERVIOUS.TEMP,  SDE.IMPERVIOUS.PRESSURE,  SDE.IMPERVIOUS.ILLUMINATIONZENITH,  SDE.IMPERVIOUS.ILLUMINATIONAZIMUTH,  SDE.IMPERVIOUS.SENSORZENITH,  SDE.IMPERVIOUS.SENSORAZIMUTH,  SDE.IMPERVIOUS.UNITS,  SDE.IMPERVIOUS.DATAFORMAT,  SDE.IMPERVIOUS.RELATIVEHUM,  SDE.IMPERVIOUS.WINDSPEED,  SDE.IMPERVIOUS.SENSORDIST,  SDE.IMPERVIOUS.PLOT FROM SDE.IMPERVIOUS';
mystrings{4,1}='SELECT ALL SDE.SOIL.OBJECTID,  SDE.SOIL.CAMPAIGNNAME,  SDE.SOIL.INVESTIGATOR,  SDE.SOIL.INSTRUMENT,  SDE.SOIL.FOREOPTIC,  SDE.SOIL.PLACENAME,  SDE.SOIL.LANDCOVER,  SDE.SOIL.CLOUDCOVER,  SDE.SOIL.CLOUDTYPE,  SDE.SOIL.WEATHER,  SDE.SOIL.ILLUMSOURCE,  SDE.SOIL.SNGLEMIX,  SDE.SOIL.RAWPROC,  SDE.SOIL.DESC_,  SDE.SOIL.DATE_,  SDE.SOIL.SOILTEXTURE,  SDE.SOIL.MINERALS,  SDE.SOIL.BULKDENSITY,  SDE.SOIL.POROSITY,  SDE.SOIL.ORGANICCONSTITUENT,  SDE.SOIL.SOILHORIZON,  SDE.SOIL.WET,  SDE.SOIL.MOISTURECONTENT,  SDE.SOIL.TEMP,  SDE.SOIL.PRESSURE,  SDE.SOIL.ILLUMINATIONZENITH,  SDE.SOIL.ILLUMINATIONAZIMUTH,  SDE.SOIL.SENSORZENITH,  SDE.SOIL.SENSORAZIMUTH,  SDE.SOIL.UNITS,  SDE.SOIL.DATAFORMAT,  SDE.SOIL.RELATIVEHUM,  SDE.SOIL.WINDSPEED,  SDE.SOIL.SENSORDIST,  SDE.SOIL.PLOT FROM SDE.SOIL';
mystrings{5,1}='SELECT SDE.WATER.OBJECTID, SDE.WATER.CAMPAIGNNAME, SDE.WATER.INVESTIGATOR,  SDE.WATER.INSTRUMENT,  SDE.WATER.FOREOPTIC,  SDE.WATER.PLACENAME,  SDE.WATER.LANDCOVER,  SDE.WATER.CLOUDCOVER,  SDE.WATER.CLOUDTYPE,  SDE.WATER.WEATHER,  SDE.WATER.ILLUMSOURCE,  SDE.WATER.SNGLEMIX,  SDE.WATER.RAWPROC,  SDE.WATER.DESC_,  SDE.WATER.DATE_,  SDE.WATER.APPEARENTCOLOR, SDE.WATER.APPEARENTCOLOR_FOREL_ULE_,  SDE.WATER.TRUECOLOR,  SDE.WATER.DEPTH,  SDE.WATER.SECCHIDEPTH,  SDE.WATER.CHLOROPHYL,  SDE.WATER.TEMPERATURE,  SDE.WATER.ICECOVER,  SDE.WATER.TDS,  SDE.WATER.TSS,  SDE.WATER.TEMP,  SDE.WATER.PRESSURE,  SDE.WATER.ILLUMINATIONZENITH,  SDE.WATER.ILLUMINATIONAZIMUTH,  SDE.WATER.SENSORZENITH,  SDE.WATER.SENSORAZIMUTH,  SDE.WATER.UNITS,  SDE.WATER.DATAFORMAT,  SDE.WATER.RELATIVEHUM,  SDE.WATER.WINDSPEED,  SDE.WATER.SENSORDIST,  SDE.WATER.PLOT FROM SDE.WATER';
mystrings{6,1}='SELECT SDE.SNOW.OBJECTID,  SDE.SNOW.CAMPAIGNNAME,  SDE.SNOW.INVESTIGATOR,  SDE.SNOW.INSTRUMENT,  SDE.SNOW.FOREOPTIC,  SDE.SNOW.PLACENAME,  SDE.SNOW.LANDCOVER,  SDE.SNOW.CLOUDCOVER,  SDE.SNOW.CLOUDTYPE,  SDE.SNOW.WEATHER,  SDE.SNOW.ILLUMSOURCE,  SDE.SNOW.SNGLEMIX,  SDE.SNOW.RAWPROC,  SDE.SNOW.DESC_,  SDE.SNOW.DATE_,  SDE.SNOW.DENSITY,  SDE.SNOW.GRAINSHAPE,  SDE.SNOW.GRAINSIZE,  SDE.SNOW.SNOWTEMPERATURE,  SDE.SNOW.VEGETATION,  SDE.SNOW.LIQUIDWATERCONTENT,  SDE.SNOW.IMPURITIES,  SDE.SNOW.HARDNESS,  SDE.SNOW.TEMP,  SDE.SNOW.PRESSURE,  SDE.SNOW.ILLUMINATIONZENITH,  SDE.SNOW.ILLUMINATIONAZIMUTH,  SDE.SNOW.SENSORZENITH,  SDE.SNOW.SENSORAZIMUTH,  SDE.SNOW.UNITS,  SDE.SNOW.DATAFORMAT,  SDE.SNOW.RELATIVEHUM,  SDE.SNOW.WINDSPEED,  SDE.SNOW.SENSORDIST,  SDE.SNOW.PLOT FROM SDE.SNOW';

mystrings{1,2}='SDE.VEGETATION';
mystrings{2,2}='SDE.ROCKS';
mystrings{3,2}='SDE.IMPERVIOUS';
mystrings{4,2}='SDE.SOIL';
mystrings{5,2}='SDE.WATER';
mystrings{6,2}='SDE.SNOW';


score=0;
stringscore='???';
for i=1:size(updatesOID,1)
    whereclause=[' WHERE OBJECTID =' num2str(updatesOID(i,1))];
    data=fetch(conn, [mystrings{updatesOID(i,2),1} whereclause]);       
    total=size(data,2);
    %count NaNs and nulls, store in n
    n=sum(strcmp(data, 'null'));
    for j=1:total
        n=n+sum(isnan(data{j}));
    end
    
    %calculate the score: +2 for "coordinations of the sampling point" and
    %for "target type"
    score=(total+2-n)/(total+2);
    %construct a string from score out of 10
    stringscore=[int2str(round(score*10)) '/10'];
    %submit the score using update
    update(conn, mystrings{updatesOID(i,2),2}, {'METAQUALITY'}, {stringscore} , whereclause);
end
disp('Done')
disp(['<<Metadata Quality estimated for ' num2str(i) ' Entries>>'])
end