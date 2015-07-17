function [out,val]=api_core_checkparameter(ptest,varargin)
%API_CORE_CHECKPARAMETER Check parameter structure(s).
%   %TODO: Write help text
%          (ptest) if valid parameter or definition structure
%          output is bool for validity test
%
%   See also API_CORE_DEFPARAMETER.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,2,1,3);
api_core_checkarg(ptest,'TEST','struct');
res=(numel(fieldnames(ptest))==15)&&all(strcmp(sort(fieldnames(ptest)),sort({'type';'name';'description';'switch';'required';'format';'cardinality';'cardinalitybase';'depend';'enumeration';'filetype';'transform';'transformbase';'recurrence';'recurrencebase'})));
if res mode=1;
else
  res=(numel(fieldnames(ptest))==16)&&all(strcmp(sort(fieldnames(ptest)),sort({'type';'name';'description';'switch';'required';'format';'cardinality';'cardinalitybase';'depend';'enumeration';'filetype';'transform';'transformbase';'recurrence';'recurrencebase';'value'})));
  if res mode=2; end;
end;
%TODO: Check validity of each field in ptest(:)

if ~res mode=0; end;
val=[];
if mode==1
  api_core_checknarg(0,2,1,2);
  if nargin>1
    api_core_checkarg(varargin{1},'PARAMETER','struct');
    %TODO: Check given params in varargin{1}(:) like api_core_parsecli does
  end;
elseif mode==2
  if nargin>1
    api_core_checkarg(varargin{1},'SWITCH','str');
    smr=['^-*' varargin{1} '\s*\d*$'];
    res=0;
    for i=1:numel(ptest)
      if (~isempty(regexpi(ptest(i).switch,smr)))||(~isempty(regexpi(ptest(i).name,smr))) res=i; break; end;
    end;
    if res>0 val=ptest(res).value;
    elseif nargin>2 val=varargin{2};
    elseif numel(ptest)==1
      if isempty(ptest.format)||any(strcmp(ptest.format,{'file' 'directory' 'string'})) val='';
      elseif strcmp(ptest.format,'number') val=[];
      elseif strcmp(ptest.format,'enumerated') val={};
      end;
    end;
  end;
end;

if nargout>0 out=res;
else
  if nargin>1
    %TODO: Pretty-print validity of params or matching switch
  else
    if mode<2
      if res api_core_l10n('fprintf','Valid parameter definition(s).\n\n');
      else
        api_core_l10n('fprintf','Not valid parameter definition(s).\n');
        if exist('err','var') fprintf('  %s\n\n',err); else fprintf('\n'); end;
      end;
    else
      if res api_core_l10n('fprintf','Valid parameter(s).\n\n');
      else
        api_core_l10n('fprintf','Not valid parameter(s).\n');
        if exist('err','var') fprintf('  %s\n\n',err); else fprintf('\n'); end;
      end;
    end;
  end;
end;
