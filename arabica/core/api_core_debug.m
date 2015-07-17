function out=api_core_debug(msg,varargin)
%API_CORE_DEBUG Add a debug message to the current stack or ask status.
%   %TODO: Write help text
%          () outputs true if the current head of the current stack is a debug
%          message or when a sub stack if that sub stack has any debug messages
%          and false otherwise
%          ('<message>',...) add new debug message with the given text and all
%          the following arguments are set as data
%
%          (<exception>,...) add a new debug message based on the given
%          Matlab exception structure or object and all the following
%          arguments are set as data. Note: after adding the message no
%          exception is raised.
%
%          the idea is to clarify and help in places of code where debug
%          states are handled
%
%   Example
%
%       pid=api_core_progress('mypid','new');
%       ...
%       api_core_debug('We have reached this far.');
%       ...
%       if api_core_debug
%           ...
%           possibly react to debugging
%           ...
%       end;
%       ...
%       api_core_progress('run',api_core_l10n('Continuing...'));
%
%
%   See also API_CORE_PROGRESS, API_CORE_COMPLETE, API_CORE_WARNING,
%   API_CORE_ERROR. 

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);
if nargin>0
  mode=api_core_checkarg(msg,{'MESSAGE' 'str';'EXCEPTION' 'scalar struct';'EXCEPTION' 'scalar MException'});
  if mode==1
    res=api_core_progress('debug',msg,varargin{:});
  elseif mode>1
    res=api_core_progress('debug',api_core_l10n('sprintf','%s -- %s',msg.identifier,msg.message),msg,varargin{:});
  end;
else
  res=api_core_progress('head');
  if ~isempty(res.sub) res=horzcat(res,res.sub); end;
  res=~isempty(strmatch('debug',{res.state}));
end;

if nargout>0 out=res;
elseif nargin==0
  if res fprintf('%s\n',api_core_l10n('The progress stack has debug messages.'));
  else fprintf('%s\n',api_core_l10n('The progress stack does not have debug messages.'));
  end;
end;
