%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ATTOID,status,output] = upload(filepath,ID,rest)
%This function adds an attachment to a feature on the Feature service.
%In other words, it uploads a given file to ESRI ArcGIS Server's REST
%interface using POST method.
% -----------------------------------------------------------
% |     You need to drop this function in:                   |
% |     <your matlab folder>\toolbox\matlab\iofun\           |
% |     so that it can enjoy using urlreadwrite function     |
% |     This function requires Java.                         |
% ------------------------------------------------------------
%
%inputs:
%   filepath: Filepath 
%   ID:       Feature ObjectID
%   rest:     Feature Service address (REST interface) that the feature
%   blongs to
%
%
%outputs:
%   ATTOID: New Attachment's ObjectID
%   output: Servers response
%   status (0 or 1)   
%
%
%   This function is partially based on urlreadpost by Dan Ellis
%   Modified by:
%     Mojtaba Karami
% Dan Ellis's code is a function for file upload using POST.
% I've modified Dan's code for ArcGIS REST interface 
%

% Copyright (c) 2010, Dan Ellis
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the Columbia University nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
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

%build addattachment URL
urlChar=[rest '/' ID '/addAttachment/'];
%load file
fid=fopen(filepath);
myfile = fread(fid,Inf,'*uint8');
fclose(fid);


if ~usejava('jvm')
   error('MATLAB:urlreadpost:NoJvm','ADDATTACHMENT requires Java.');
end

import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;

% Be sure the proxy settings are set.
com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings

% Check number of inputs and outputs.
error(nargchk(3,3,nargin))
error(nargoutchk(0,3,nargout))
if ~ischar(urlChar)
    error('MATLAB:urlreadpost:InvalidInput','The first input, the URL, must be a character array.');
end

% Do we want to throw errors or catch them?
if nargout == 2
    catchErrors = true;
else
    catchErrors = false;
end

% Set default outputs.
output = '';
status = 0;

% Create a urlConnection.
[urlConnection,errorid,errormsg] = urlreadwrite(mfilename,urlChar);
if isempty(urlConnection)
    if catchErrors, return
    else error(errorid,errormsg);
    end
end

% POST method.  Write param/values to server.
        urlConnection.setDoOutput(true);
        boundary = '***********************';
        urlConnection.setRequestProperty( ...
            'Content-Type',['multipart/form-data; boundary=',boundary]);
        printStream = java.io.PrintStream(urlConnection.getOutputStream);
        % also create a binary stream
        dataOutputStream = java.io.DataOutputStream(urlConnection.getOutputStream);
        eol = [char(13),char(10)];
          printStream.print(['--',boundary,eol]);
          printStream.print(['Content-Disposition: form-data; name="attachment"']);
            printStream.print(['; filename="' filepath '"',eol]);
            printStream.print(['Content-Type: image/x-png',eol]);%here we define the content type of all files as png for simplicity
            printStream.print([eol]);
            dataOutputStream.write(myfile,0,length(myfile));
            printStream.print([eol]);
    
          printStream.print(['--',boundary,eol]);
          printStream.print(['Content-Disposition: form-data; name="f"']);
            printStream.print([eol]);
            printStream.print([eol]);
            printStream.print(['json',eol]);

        
        printStream.print(['--',boundary,'--',eol]);
        printStream.close;

% Read the data from the connection.
try
    inputStream = urlConnection.getInputStream;
    byteArrayOutputStream = java.io.ByteArrayOutputStream;
    % This StreamCopier is unsupported and may change at any time.
    isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
    isc.copyStream(inputStream,byteArrayOutputStream);
    inputStream.close;
    byteArrayOutputStream.close;
    output = native2unicode(typecast(byteArrayOutputStream.toByteArray','uint8'),'UTF-8');
catch
    if catchErrors, return
    else error('MATLAB:urlreadpost:ConnectionFailed','Error downloading URL. Your network connection may be down or your proxy settings improperly configured.');
    end
end
%evaluate Attachment OID
s=regexp(output,':');
t=regexp(output,',');
ATTOID=str2double(output(s(2)+1:t(1)-1));


status = 1;
end