function out=api_core_defmodule(varargin)
%API_CORE_DEFMODULE Create a module definition structure.
%   %TODO: Write help text
%          () empty def that needs to be filled in
%          ('<type>') manual def upto type
%          ('<type>',<@entry>) manual def upto entry
%          ('<type>',<@entry>,ver) manual def upto version
%          ('<type>',<@entry>,ver,'<name>') manual def upto name
%          ('<type>',<@entry>,ver,'<name>','<package>') manual def upto
%          package
%          %TODO: Everything in between is also just fine
%          ('<type>',<@entry>,ver,'<name>','<package>','<packageversion>',
%          <date>,'<description>',[<icon>],[<posx> <posy>],<rotation>,
%          {'<tags>'},'<uri>',{'<citations>'},{'<authors>'},
%          {'<exeauthors>'},'<exeversion>',<parameters>) full manual def
%
%   See also API_CORE_CHECKMODULE, API_CORE_DEFVERSION,
%   API_CORE_DEFPARAMETER, API_CORE_DEFPACKAGE, API_CORE_PARSEPIPELINE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,18);

out.type='module'; %Arabica's internal value, not part of LONI - one of 'module','wrap','visualize','wizard'
out.entry=@error; %Arabicas's internal value, not part of LONI - the function handle of the module entry point
out.version=api_core_defversion; %Arabicas's internal value, not part of LONI - incorporates package, name and version strings
out.name=''; %human readable name of the module
out.package=''; %human readable name of the package
out.packageversion=''; %version string of the package
out.date=''; %creation date of the module as datestring datevec or datenum or ''
out.description=''; %any string describing the module
out.icon=[]; %base64 encoded string with 86x86 CMYK JPG or array of size HxW or HxWx3 for gray or RGB image with normalized or 0..255 values
out.position=[0 0]; %integer [x y] position (really posX and posY in xml)
out.rotation=false; %logical for rotation (really an integer in xml)
out.tags={}; %list of keyword strings describing the module
out.uri=''; %url of module homepage
out.citations={}; %list of strings for citations for publications of module
out.authors=cell(0,3); %Nx3 list with 'fullname' 'email' 'website' triplets of module authors
out.exeauthors=cell(0,3); %Nx3 list with 'fullname' 'email' 'website' triplets of authors of code behind module
out.exeversion=''; %version string of actual code behind module
out.parameters=api_core_defparameter; %incorporates both input and output
out.parameters(1)=[];

%LONI's package, name and version string are incorporated as api_core_defversion
%LONI's module instances additionally have these fields:
%inst.location=''; %executable location url 'pipeline://server/executable'
%inst.id=''; %machine readable instance id

if ~isempty(varargin)
  api_core_checkopt(varargin{1},'TYPE','module','wrap','visualize','wizard');
  out.type=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'ENTRY','function');
  out.entry=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  if api_core_checkversion(varargin{1}) out.version=varargin{1};
  else error('API_CORE_DEFMODULE:invalidInput','Input argument VERSION must be a valid module version definition.');
  end;
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
    api_core_checkarg(varargin{1},'PACKAGE','str');
    out.package=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'PACKAGEVERSION','str');
    out.packageversion=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},{'DATE' 'str';'DATE' 'scalar double';'DATE' 'double 1x6'});
    out.date=varargin{1};
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
    api_core_checkarg(varargin{1},{'ICON' 'str';'ICON' 'numeric 2d';'ICON' 'numeric NxNx3'});
    out.icon=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'POSITION','integer 1x2');
  out.position=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'ROTATION','scalar logical');
  out.rotation=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'TAGS','str');
    if ischar(varargin{1}) out.tags={varargin{1}};
    else out.tags=varargin{1};
    end;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'URI','str');
    out.uri=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'CITATIONS','str');
    if ischar(varargin{1}) out.citations={varargin{1}};
    else out.citations=varargin{1};
    end;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'AUTHORS','nx3 cellstr');
    out.authors=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'EXEAUTHORS','nx3 cellstr');
    out.exeauthors=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'EXEVERSION','str');
    out.exeversion=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'PARAMETERS','struct');
    for i=1:numel(varargin{1})
      if ~api_core_checkparameter(varargin{1}(i)) error('API_CORE_DEFMODULE:invalidInput','Input argument PARAMETERS must be valid parameter definitions.'); end;
    end;
    out.parameters=varargin{1}(:);
  end;
  varargin(1)=[];
end;
