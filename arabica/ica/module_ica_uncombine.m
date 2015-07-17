function [out,args]=module_ica_uncombine(varargin)
%MODULE_ICA_UNCOMBINE Uncombine multiple mixing processes.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_ICA_COMBINE, MODULE_ICA_ICA, MODULE_ICA_PCA,
%   API_CORE_DEFMODULE, MODULE_CORE.

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
    %TODO: More checking and security here
    try
      tempin=load(args(1).value,'combine');
      temp.combine=tempin.combine;
      clear tempin;
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(1).value),err);
    end;
    try tempin=load(args(2).value,'A','W');
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(2).value),err);
    end;

    %TODO:
    
    clear tempin;
    try save(args(3).value,'-struct','tempout','A','W','combine');
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',args(3).value),err);
    end;
    clear tempout;
    out=true;
  end;
end;
