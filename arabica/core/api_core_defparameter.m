function out=api_core_defparameter(varargin)
%API_CORE_DEFPARAMETER Create a parameter or definition structure.
%   %TODO: Write help text
%          () empty def that needs to be filled in
%          ('<type>') manual def upto type
%          %TODO: Everything in between also just fine
%          ('<type>','<name>','<description>','<switch>',<required>,
%          '<format>',<cardinality>,<cardinalitybase>,[<depend>],
%          {'<enumeration>'},filetype,{'<transform>'},<transformbase>),
%          <recurrence>,<recurrencebase>) full manual def
%
%   See also API_CORE_CHECKPARAMETER, API_CORE_DEFFILETYPE,
%   API_CORE_DEFMODULE, API_CORE_PARSEPIPELINE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,15);

out.type=''; %'input' or 'output'
out.name=''; %human readable name e.g. 'Mean','Filename'
out.description=''; %any string describing the parameter
out.switch=''; %command-line name e.g. '-mean','-file', incorporates potential trailing space
out.required=false; %logical for always needed or not, when true the enabled has no meaning
out.format=''; %'','file','directory','string','number' or 'enumerated', where '' means 'string' with cardinality=0
out.cardinality=0; %integer [-2 N] where -2=N, -1=Inf, 0=flag, 1..=number
out.cardinalitybase=NaN; %index of another input parameter used when cardinality=-2 so that our number must match its, or NaN
out.depend=[]; %list of other parameter indices this one depends on
out.enumeration={}; %string list of valid enumerations, when format='enumerated'
out.filetype=api_core_deffiletype; %struct list with alternative filetype definitions, when format='file'
out.filetype(1)=[];
out.transform=cell(0,2); %Nx2 table of 'operation' 'string' pairs where operators can be 'subtract','prepend','append','replace', when format='file'
out.transformbase=NaN; %index of another file parameter used as basename for transforms, when format='file', or NaN
out.recurrence=0; %Arabicas's internal value, not part of LONI, same as cardinality for reoccuring loops of parameters
out.recurrencebase=NaN; %Arabicas's internal value, not part of LONI, index of the base parameter the loop hops back to

%LONI's switchSpaced boolean is incorporated as a trailing space into switch
%LONI's order integers are incorporated as the indexing of the matlab arrays
%LONI's parameter instances additionally have these fields:
%inst.id=''; %machine readable instance id
%inst.enabled=true; %logical for currently in use or not, when required=true this is not believed anyway
%inst.values=''; %one or list {''} of currently fixed parameter values

if ~isempty(varargin)
  api_core_checkopt(varargin{1},'TYPE','input','output');
  out.type=varargin{1};
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
    api_core_checkarg(varargin{1},'DESCRIPTION','str');
    out.description=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'SWITCH','str');
    out.switch=char(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'REQUIRED','scalar logical');
    out.required=logical(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkopt(varargin{1},'FORMAT','','file','directory','string','number','enumerated');
  out.format=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'CARDINALITY','scalar integer');
    if varargin{1}<-2 error('API_CORE_DEFPARAMETER:invalidInput','Input argument CARDINALITY must be >= -2.'); end;
    out.cardinality=double(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'CARDINALITYBASE','scalar integer positive');
    out.cardinalitybase=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'DEPEND','integer positive');
    out.depend=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'ENUMERATION','str');
    if ischar(varargin{1}) out.enumeration={varargin{1}};
    else out.enumeration=varargin{1};
    end;
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'FILETYPE','struct');
    for i=1:numel(varargin{1})
      if ~api_core_checkfiletype(varargin{1}(i))error('API_CORE_DEFPARAMETER:invalidInput','Input argument FILETYPE must be a valid filetype definition.'); end;
    end;
    out.filetype=varargin{1}(:);
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'TRANSFORM','nx2 cellstr');
    for i=1:size(varargin{1},1)
      api_core_checkopt(varargin{1}{i,1},'TRANSFORM.operation','subtract','prepend','append','replace');
    end;
    out.transform=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'TRANSFORMBASE','scalar integer positive');
    out.transformbase=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'recurrence','scalar integer');
    if varargin{1}<-2 error('API_CORE_DEFPARAMETER:invalidInput','Input argument recurrence must be >= -2.'); end;
    out.recurrence=double(varargin{1});
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'recurrenceBASE','scalar integer positive');
    out.recurrencebase=varargin{1};
  end;
  varargin(1)=[];
end;
