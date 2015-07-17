function [out,err]=api_core_checkpackage(ptest,varargin)
%API_CORE_CHECKPACKAGE Check or compare package structure(s).
%   %TODO: Write help text
%          (ptest) if valid package definition
%          (ptest,...) in addition to validity check that there are no name
%          clashes and that all requirements are fulfilled
%          output is bool for validity test
%          for each input output is matching list of bools for check result
%
%   See also API_CORE_DEFPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,2,1,Inf);
api_core_checkarg(ptest,'TEST','struct');
res=(numel(fieldnames(ptest))==12)&&all(strcmp(sort(fieldnames(ptest)),sort({'version';'requires';'suggests';'path';'entry';'name';'modules';'templates';'api';'homeurl';'updateurl';'description'})));
%TODO: Check validity of each field in ptest(:)

err={};
if res&&(nargin>1)
  while ~isempty(varargin)
    if ~isempty(varargin{1})
      api_core_checkarg(varargin{1},'PACKAGE','struct');
      pv=[ptest(:).version];
      pn={pv(:).name};
      for i=1:numel(varargin{1})
        res=api_core_checkpackage(varargin{1}(i));
        if res
          rn={varargin{1}(i).requires(:).name};
          [l,j,k]=intersect(rn,pn);
          res=numel(l)==numel(rn);
          if res
            for l=1:numel(rn)
              res=api_core_checkversion(ptest(k(l)).version,varargin{1}(i).requires(j(l)));
              res=isnumeric(res)&&(res>=0);
              if ~res
                err{end+1}=api_core_l10n('sprintf','Too old version of required package "%s"!',rn{j(l)});
                break;
              end;
            end;
          else
            l=setdiff(1:numel(rn),j);
            for j=1:numel(l) err{end+1}=api_core_l10n('sprintf','Missing required package "%s"!',rn{l(j)}); end;
          end;
        else err{end+1}=api_core_l10n('sprintf','Not a valid package definition!');
        end;
        if ~res break; end;
      end;
    end;
    if res varargin(1)=[];
    else break;
    end;
  end;
end;

if nargout>0 out=res;
elseif nargin>1
    %TODO: Pretty-print using err and other valid details
else
  if res api_core_l10n('fprintf','Valid package definition(s).\n\n');
  else api_core_l10n('fprintf','Not valid package definition(s).\n\n');
  end;
end;
