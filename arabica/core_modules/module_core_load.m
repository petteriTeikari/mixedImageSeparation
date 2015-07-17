function [out,args]=module_core_load(varargin)
%MODULE_CORE_LOAD Wrapper for Matlab's builtin load.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%          (<definition>,'validate') validate parameters
%          (<definition>,'config') interactive configuration
%          (<definition>,'evaluate',params) evaluate with parameters
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_CORE_SAVE, MODULE_CORE_SIMULATE, API_CORE_DEFMODULE,
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
    %TODO: Maybe in the future include some metadata in tempout.xxx
    %TODO: More checking and security here
    i=2;
    while (i<numel(args))&&api_core_checkparameter(args(i),'var')
      clear tempin tempout;
      vin={};
      vout={};
      for j=1:numel(args(i).value)
        vn=regexp(args(i).value{j},'^\s*(?<out>\S+)\s*=\s*(?<in>\S+)\s*$','names');
        if numel(vn)==1
          vin{end+1}=vn.in;
          vout{end+1}=vn.out;
        else
          vn=regexp(args(i).value{j},'^\s*(?<in>\S+)\s*$','names');
          if numel(vn)==1
            vin{end+1}=vn.in;
            vout{end+1}=vn.in;
          end;
        end;
      end;
      i=i+1;
      if (i<=numel(args))&&api_core_checkparameter(args(i),'out')
        fn=args(i).value;
        i=i+1;
      end;
      try tempin=load(args(1).value,vin{:});
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',args(1).value),err);
      end;
      for j=1:numel(vout)
        if ~isfield(tempin,vin{j}) api_core_error(api_core_l10n('sprintf','Variable named "%s" does not exist!',vin{j})); end;
        tempout.(vout{j})=tempin.(vin{j});
      end;
      try save(fn,'-struct','tempout');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fn),err);
      end;
    end;
    out=true;
  end;
end;
