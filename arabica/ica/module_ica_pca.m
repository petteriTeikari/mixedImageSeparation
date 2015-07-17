function [out,args]=module_ica_pca(varargin)
%MODULE_ICA_PCA Perform Principal Component Analysis.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_ICA_ICA, MODULE_CORE_SIMULATE, API_CORE_DEFMODULE,
%   MODULE_CORE.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

[out,args,mode]=module_core(varargin{:});

if strcmp(mode,'validate')
  %TODO: More checking and security here
elseif strcmp(mode,'config')
  %TODO: Default implementation for config
elseif strcmp(mode,'evaluate')
  if out
    out=false;
    %TODO: Maybe in the future include some metadata in temp.xxx
    %TODO: More checking and security here
    i=2;
    if (i<numel(args))&&api_core_checkparameter(args(i),'dim')
      dim=args(i).value;
      i=i+1;
    else dim=Inf;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'var')
      pow=args(i).value;
      i=i+1;
    else pow=1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'symmetric')
      symm={'symmetric'};
      i=i+1;
    else symm={};
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'eigen')
      efn=args(i).value;
      i=i+1;
    else efn='';
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'cov')
      cfn=args(i).value;
      i=i+1;
    else cfn='';
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'merged')
      merge=true;
      i=i+1;
    else merge=false;
    end;
    try vn=whos('-file',args(1).value);
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(1).value),err);
    end;
    if isempty(vn) api_core_error(api_core_l10n('sprintf','Cannot find variables in file "%s"!',args(1).value));
    else
      for j=numel(vn):-1:1
        if ~any(strcmp(vn(j).class,{'double' 'logical' 'single' 'int8' 'uint8' 'int16' 'uint16' 'int32' 'uint32' 'int64' 'uint64'})) vn(j)=[];
        elseif (numel(vn(j).size)~=2)||(vn(j).size(1)>=vn(j).size(2)) vn(j)=[];
        end;
      end;
      if numel(vn)==1 vn=vn.name;
      elseif any(strcmpi('X',{vn(:).name}))
        vn={vn(strcmpi('X',{vn(:).name})).name};
        if numel(vn)==1 vn=vn{1};
        else
          vn=vn{strcmp('X',vn)};
          if isempty(vn) vn='x'; end;
        end;
      else api_core_error(api_core_l10n('sprintf','Cannot find a suitable variable in file "%s"!',args(1).value));
      end;
    end;
    try tempin=load(args(1).value,vn);
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(1).value),err);
    end;
    temp.X=tempin.(vn);
    clear tempin;
    temp.X=api_ica_normalize(temp.X,'mean');
    [temp.d,temp.E,temp.C]=api_ica_pca(temp.X);
    sd=cumsum(temp.d);
    sd=sd./sd(end);
    dimpow=find(sd>=min(1,pow),1,'first');
    [temp.wM,temp.dwM,temp.X]=api_ica_whiten(temp.d,temp.E,temp.X,min(dim,dimpow),symm{:});
    if ~isempty(efn)
      try save(efn,'-struct','temp','d','E');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',efn),err);
      end;
    end;
    if ~isempty(cfn)
      try save(cfn,'-struct','temp','C');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',cfn),err);
      end;
    end;
    if merge vn={'d' 'E' 'C' 'wM' 'dwM' 'X'}; else vn={'wM' 'dwM' 'X'}; end;
    try save(args(end).value,'-struct','temp',vn{:});
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',args(end).value),err);
    end;
    out=true;
  end;
end;
