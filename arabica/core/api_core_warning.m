function out=api_core_warning(msg,varargin)
%API_CORE_WARNING Add a warning message to the current stack or ask status.
%   %TODO: Write help text
%          () outputs true if the current head of the current stack is a warning
%          message or when a sub stack if that substack has any warning messages
%          and false otherwise
%          ('<message>',...) add a new warning message with the given text and
%          all the following arguments are set as data
%
%          (<exception>,...) add a new warning message based on the given
%          Matlab exception structure or object and all the following
%          arguments are set as data. Note: after adding the message no
%          exception is raised.
%
%          unlike the matlab warning() this is a completely silent command
%
%          the idea is to clarify and help in places of code where warning
%          states are handled
%
%   Example
%
%       pid=api_core_progress('mypid','new');
%       ...
%       api_core_warning(api_core_l10n('We have a recoverable failure.'));
%       ...
%       if api_core_warning
%           ...
%           possibly react to errors
%           ...
%       end;
%       ...
%       api_core_progress('run',api_core_l10n('Continuing...'));
%
%
%   See also API_CORE_PROGRESS, API_CORE_COMPLETE, API_CORE_DEBUG,
%   API_CORE_ERROR.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);
if nargin>0
  mode=api_core_checkarg(msg,{'MESSAGE' 'str';'EXCEPTION' 'scalar struct';'EXCEPTION' 'scalar MException'});
  if mode==1
    res=api_core_progress('warning',msg,varargin{:});
  elseif mode>1
    res=api_core_progress('warning',api_core_l10n('sprintf','%s -- %s',msg.identifier,msg.message),msg,varargin{:});
  end;
else
  res=api_core_progress('head');
  if ~isempty(res.sub) res=horzcat(res,res.sub); end;
  res=~isempty(strmatch('warning',{res.state}));
end;

if nargout>0 out=res;
elseif nargin==0
  if res api_core_l10n('fprintf','The progress stack has warning messages.\n');
  else api_core_l10n('fprintf','The progress stack does not have warning messages.\n');
  end;
end;
