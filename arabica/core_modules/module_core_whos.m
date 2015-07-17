function [out,args]=module_core_whos(varargin)
%MODULE_CORE_WHOS Wrapper for Matlab's builtin whos.
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
%   See also VISUALIZE_CORE_WHO, MODULE_CORE_LOAD, MODULE_CORE_SAVE,
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
    i=2;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'var')
      vin=args(i).value;
      i=i+1;
    else vin={};
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'out')
      fno=args(i).value;
      i=i+1;
    else fno={};
    end;
    for i=1:numel(args(1).value)
      fn=args(1).value{i};
      temp=['whos(''-file'',''' fn ''''];
      for j=1:numel(vin) temp=[temp ',''' vin{j} '''']; end;
      temp=[temp ');'];
      try temp=evalc(temp);
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn),err);
      end;
      temp=[sprintf('Whos %s:\n\n',fn) temp];
      fprintf('\n%s',temp);
      if ~isempty(fno)
        try
          fid=fopen(fno{i},'w');
          fprintf(fid,'%s',temp);
          fclose(fid);
        catch err
          api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fno{i}),err);
        end;
      end;
    end;
    out=true;
  end;
end;
