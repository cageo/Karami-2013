function [b_additive b_multiplicative]=asd_jumpcorrection(b)
%%JUMP CORRECTION FOR ASD (jumps at 1000nm and 1800nm)
%inputs
%a: wavelength
%b: values
%
% outputs
% b_additive and b_multiplicative
%
%
% This function is written by:
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



%estimate the correct gradient at jump points
t1=(b(651)-b(650)+b(653)-b(652))/2;
t2=(b(1451)-b(1450)+b(1453)-b(1452))/2;
%compute the offset for jump points,assuming that the reference detector is no.2:
offset=b(652)-b(651)-t1;
offset2=-b(1452)+b(1451)+t2;

%perform correction: additive approach
b_additive=b;
b_additive(1:651)=b_additive(1:651)+offset;
b_additive(1452:2151)=b_additive(1452:2151)+offset2;
%perform correction: multiplicative approach
b_multiplicative=b;
c1=(b_multiplicative(651)+offset)/b_multiplicative(651);
c3=(b_multiplicative(1452)+offset2)/b_multiplicative(1452);

b_multiplicative(1:651)=b(1:651)*c1;
b_multiplicative(1452:2151)=b(1452:2151)*c3;

end