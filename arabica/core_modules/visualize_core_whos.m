function [out,args]=visualize_core_whos(varargin)
%VISUALIZE_CORE_WHOS Wrapper for Matlab's builtin whos.
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
%   See also MODULE_CORE_WHO, MODULE_CORE_LOAD, MODULE_CORE_SAVE,
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
    for i=1:numel(args(1).value)
      fn=args(1).value{i};
      temp=['whos(''-file'',''' fn ''''];
      for j=1:numel(vin) temp=[temp ',''' vin{j} '''']; end;
      temp=[temp ');'];
      try temp=evalc(temp);
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn),err);
      end;
      try
        f=figure('Name',sprintf('Whos %s',fn),'NumberTitle','off','MenuBar','none','ToolBar','none','DockControls','off','HitTest','off','Visible','off');
        a=axes('Parent',f,'Position',[0 0 1 1],'Color','none','XTick',[],'YTick',[],'Box','off','HitTest','off');
        text('Parent',a,'Position',[0.02 0.98],'String',temp,'HorizontalAlignment','left','VerticalAlignment','top','HitTest','off');
        set(f,'Visible','on');
      catch err
        api_core_error(api_core_l10n('Cannot create figure!'),err);
      end;
    end;
    out=true;
  end;
end;
