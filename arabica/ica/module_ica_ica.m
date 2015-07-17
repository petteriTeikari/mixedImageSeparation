function [out,args]=module_ica_ica(varargin)
%MODULE_ICA_ICA Perform Independent Component Analysis.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_ICA_PCA, MODULE_CORE_SIMULATE, API_CORE_DEFMODULE,
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
    if ~api_core_checksubpackage('fpica','fastica','FastICA')
      api_core_error(api_core_l10n('sprintf','Cannot locate the FastICA package!'));
      return;
    end;
    %TODO: Maybe in the future include some metadata in temp.xxx
    %TODO: More checking and security here
    i=2;
    params={};
    if (i<numel(args))&&api_core_checkparameter(args(i),'runs')
      n=args(i).value;
      i=i+1;
    else n=1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'approach')
      params(end+(1:2))={'approach' args(i).value};
      i=i+1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'nonlinearity')
      if strcmp(args(i).value,'cubic') nl='pow3';
      elseif strcmp(args(i).value,'tanh') nl='tanh';
      elseif strcmp(args(i).value,'gaussian') nl='gaus';
      elseif strcmp(args(i).value,'skewness') nl='skew';
      end;
      params(end+(1:2))={'nonlinearity' nl};
      i=i+1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'dim')
      params(end+(1:2))={'dim' args(i).value};
      i=i+1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'ics')
      params(end+(1:2))={'ics' args(i).value};
      i=i+1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'boot')
      boot=-args(i).value;
      i=i+1;
    else boot=0;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'keeporder')
      boot=abs(boot);
      i=i+1;
    end;
    if boot~=0 params(end+(1:2))={'bootstrap' boot}; end;
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
    [temp.A,temp.W,temp.wM,temp.dwM]=api_ica_ica(tempin.(vn),n,params{:});
    try save(args(end).value,'-struct','temp');
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',args(end).value),err);
    end;
    out=true;
  end;
end;
