function [out,args]=module_ica_estimate(varargin)
%MODULE_ICA_PCA Perform Principal Component Analysis.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_ICA_ICA, MODULE_ICA_CLUSTER, API_CORE_DEFMODULE,
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
    i=4;
    fn=cell(0,2);
    if (i<=numel(args))&&api_core_checkparameter(args(i),'centroid')
      fn(end+1,1:2)={'centroid' args(i).value};
      i=i+1;
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'variance')
      fn(end+1,1:2)={'variance' args(i).value};
      i=i+1;
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'quantile')
      fn(end+1,1:2)={'quantile' args(i).value};
      i=i+1;
    end;
    try
      tempin=load(args(1).value,'cluster');
      temp.c=tempin.cluster;
      try
        tempin=load(args(1).value,'rank');
        temp.r=tempin.rank;
      catch
      end;
      clear tempin;
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(1).value),err);
    end;
    fnin=args(2).value;
    for i=1:numel(fnin)
      try tempin=load(fnin{i},'A','W');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fnin{i}),err);
      end;
      if isfield(temp,'A')
        temp.A=cat(2,temp.A,tempin.A);
        temp.W=cat(1,temp.W,tempin.W);
      else
        temp.A=tempin.A;
        temp.W=tempin.W;
      end;
      clear tempin;
    end;
    try
      tempin=load(args(3).value,'X');
      temp.X=tempin.X;
      clear tempin;
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(3).value),err);
    end;
    for i=1:size(fn,1)
      if isfield(temp,'r') [tempout.A,tempout.W,tempout.S]=api_ica_estimate(fn{i,1},temp.c,temp.r,temp.A,temp.W,temp.X);
      else [tempout.A,tempout.W,tempout.S]=api_ica_estimate(fn{i,1},temp.c,temp.A,temp.W,temp.X);
      end;
      try save(fn{i,2},'-struct','tempout','A','W','S');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fn{i,2}),err);
      end;
      clear tempout;
    end;
    out=true;
  end;
end;
