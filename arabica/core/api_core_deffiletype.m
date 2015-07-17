function out=api_core_deffiletype(varargin)
%API_CORE_DEFFILETYPE Create a filetype definition structure (list).
%   %TODO: Write help text
%          () empty def that needs to be filled in
%          ('<name>') manual def upto name
%          ('<name>','<description>') manual def upto description
%          ('<name>','<description>','<extension>') manual def upto
%          extension
%          ('<name>','<description>','<extension>',{'<needs>'}) full manual
%          def
%
%   See also API_CORE_CHECKMODULE, API_CORE_DEFVERSION, API_CORE_DEFPROTOTYPE,
%   API_CORE_DEFPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,4);

out.name=''; %human readable name e.g. 'Image file (jpeg)'
out.description=''; %any string describing the filetype
out.extension=''; %the filename extension without the leading '.'
out.need={}; %list of other extensions that must be present with a tested filename

if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'NAME','str');
    out.name=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'DESCRIPTION','str');
    out.description=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'EXTENSION','str');
    out.extension=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'NEED','str');
    if ischar(varargin{1}) out.need={varargin{1}};
    else out.need=varargin{1};
    end;
  end;
  varargin(1)=[];
end;
