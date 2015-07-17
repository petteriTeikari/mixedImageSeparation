function out=api_core_defpackage(varargin)
%API_CORE_DEFPACKAGE Create a package definition structure.
%   %TODO: Write help text
%          () empty def that needs to be filled in
%          (ver) manual def upto version
%          (ver,req) manual def upto requires
%          (ver,req,sug) manual def upto suggests
%          (ver,req,sug,'<path>') manual def upto path
%          (ver,req,sug,'<path>',<@entry>) manual def upto entry
%          (ver,req,sug,'<path>',<@entry>,'<name>') manual def upto name
%          (ver,req,sug,'<path>',<@entry>,'<name>',modules) manual def upto
%          modules
%          (ver,req,sug,'<path>',<@entry>,'<name>',modules,{<templates>})
%          manual def upto templates
%          (ver,req,sug,'<path>',<@entry>,'<name>',modules,{<templates>},
%          {<api>}) manual def upto apis
%          (ver,req,sug,'<path>',<@entry>,'<name>',modules,{<templates>},
%          {<api>},'<homeurl>') manual def upto homeurl
%          (ver,req,sug,'<path>',<@entry>,'<name>',modules,{<templates>},
%          {<api>},'<homeurl>','<updateurl>') manual def upto updateurl
%          (ver,req,sug,'<path>',<@entry>,'<name>',modules,{<templates>},
%          {<api>},'<homeurl>','<updateurl>','<description>') full manual
%          def
%
%   See also API_CORE_CHECKPACKAGE, API_CORE_ISPACKAGE, API_CORE_DEFMODULE,
%   API_CORE_DEFVERSION, API_CORE_PARSEDIR, API_CORE_PARSECONTENTS.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,12);

out.version=api_core_defversion('framework');
out.requires=api_core_defversion;
out.requires(1)=[];
out.suggests=api_core_defversion;
out.suggests(1)=[];
out.path='';
out.entry=@error;
out.name='';
out.modules=api_core_defmodule;
out.modules(1)=[];
out.templates={};
out.api={};
out.homeurl='';
out.updateurl='';
out.description='';

if ~isempty(varargin)
  if api_core_checkversion(varargin{1})&&strcmp(varargin{1}.container,'framework') out.version=varargin{1};
  else error('API_CORE_DEFPACKAGE:invalidInput','VERSION must be a valid package version definition.');
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    for i=1:numel(varargin{1})
      if ~api_core_checkversion(varargin{1}(i)) error('API_CORE_DEFPACKAGE:invalidInput','All entries in REQUIRES list must be valid package version definitions.'); end;
    end;
    temp=varargin{1}(:);
    out.reguires=temp;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    for i=1:numel(varargin{1})
      if ~api_core_checkversion(varargin{1}(i)) error('API_CORE_DEFPACKAGE:invalidInput','All entries in SUGGESTS list must be valid package version definitions.'); end;
    end;
    temp=varargin{1}(:);
    out.suggests=temp;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'PATH','str');
    if ~exist(varargin{1},'dir') error('API_CORE_DEFPACKAGE:invalidInput','PATH must be empty or point to an existing directory.'); end;
    out.path=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'ENTRY','function');
  out.entry=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'NAME','str');
    out.name=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'MODULES','struct');
    for i=1:numel(varargin{1})
      if ~api_core_checkmodule(varargin{1}(i)) error('API_CORE_DEFPACKAGE:invalidInput','All entries in MODULES list must be valid module definitions.'); end;
    end;
    temp=varargin{1}(:);
    out.modules=temp;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'TEMPLATES','str');
    if ischar(varargin{1}) out.templates={varargin{1}};
    else out.templates=varargin{1};
    end;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'API','str');
    if ischar(varargin{1}) out.api={varargin{1}};
    else out.api=varargin{1};
    end;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'HOMEURL','str');
    out.homeurl=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'UPDATEURL','str');
    out.updateurl=char(varargin{1});
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
