%REMOVEOVERLAP Remove wavelength-overlapped data from spectra.
%   S = SVC_REMOVEOVERLAP(R, w) removes overlapped data from the spectrum
%   (or spectra) in the structure array R by joining the spectrum at the
%   specified wavelength w.
%
%   [S, n] = SVC_REMOVEOVERLAP(R, w) removes overlapped data by joining at
%   wavelength w, and also returns the index n of the first SWIR pixel.
%
%  Originaly written by Iain Robinson
%
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

function [output, firstSWIRIndex] = svc_removeoverlap(input, joinWavelength)
    % Input is a structure array of spectra. Loop through each spectrum in
    % the array and process individually.
    for n = 1:numel(input)
        % FIND OVERLAP REGION
        % Find the overlap region by building a list of overlapped
        % wavelengths and their corresponding indexes.
        
        % The wavelength vector of a spectrum is usually strictly
        % increasing. However in spectra with overlapped data the
        % wavelengths switch from increasing to decreasing at the
        % transition between detectors. The overlap region is found by
        % looking for this point.

        % First, create an empty array which will hold a list of the
        % indexes of the transition wavelengths. For example, for a
        % VNIR-to-SWIR transition the transition wavelength is the shortest
        % (i.e. the first) wavelength of the SWIR detector.
        transitionIndexes = [];
        
        % Loop through all wavelength values, starting from the second.
        for i = 2:numel(input(n).wavelength)
            % If this (the i-th) wavelength value is less than the previous
            % one this indicates a transition between detectors.
            if input(n).wavelength(i) < input(n).wavelength(i-1)
                % Add the index of this wavelength to the list.
                transitionIndexes = [ transitionIndexes, i ];
            end
        end

        % This function is desigend to handle only a single overlap region.
        % If a spectrum contains multiple overlap regions report an error
        % and stop the function.
        if isempty(transitionIndexes)
            error('No transition wavelengths were found in spectrum number %d', n);
        elseif numel(transitionIndexes) > 1
            error('More than one overlap region was found in specturm number %d. The removeoverlap function can only remove a single overlapped region.', n)
        end

        % There is only a single transition wavelength in the spectrum, so
        % the spectrum can now be divided into two spectral regions. These
        % will be called VNIR and SWIR (although the function can in
        % general be applied to any transition).
        firstSWIRIndex = transitionIndexes(1);
        
        % SEPARATE REGIONS
        % Separate the VNIR and SWIR spectral regions.
        wavelengthVNIR = input(n).wavelength(1:firstSWIRIndex - 1);
        dataVNIR = input(n).data(1:firstSWIRIndex - 1);
        wavelengthSWIR = input(n).wavelength(firstSWIRIndex:end);
        dataSWIR = input(n).data(firstSWIRIndex:end);

        % JOIN REGIONS
        % Join the spectral regions at the specified wavelength.
        
        % Find the wavelength range of the overlap region.
        overlapRegion = [ wavelengthSWIR(1), wavelengthVNIR(end) ];
        
        % Check that the specified join wavelength is within the overlap region.
        if joinWavelength < overlapRegion(1) || joinWavelength > overlapRegion(2)
            error('The specified join wavelength %.1f nm does not lie within the overlap region (%.1f-%.1f) nm of spectrum number %d.', joinWavelength, overlapRegion(1), overlapRegion(2), n);
        end
        
        % Create the joined wavelength and data.
        wavelengthJoined = [ wavelengthVNIR(wavelengthVNIR < joinWavelength); wavelengthSWIR(wavelengthSWIR >= joinWavelength) ];
        dataJoined = [ dataVNIR(wavelengthVNIR < joinWavelength); dataSWIR(wavelengthSWIR >= joinWavelength) ];

        % CREATE THE OUTPUT SPECTRUM
        % Copy the input spectrum structure, then overwrite wavelength and
        % data fields with the new values.
        output(n) = input(n);
        output(n).wavelength = wavelengthJoined;
        output(n).data = dataJoined;
    end
end