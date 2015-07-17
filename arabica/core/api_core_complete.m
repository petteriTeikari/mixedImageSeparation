function out=api_core_complete(st,varargin)
%API_CORE_COMPLETE Terminate the current stack if possible or ask status.
%   %TODO: Write help text
%          () outputs true if the current head of the current stack is in a
%          terminal state and false otherwise
%          ('complete','<message>',...) if not already terminated add a new
%          complete message with the given text and all the following
%          arguments are set as data
%          ('cancel','<message>',...) if not already terminated add a new
%          cancel message with the given text and all the following
%          arguments are set as data
%
%          the idea is to clarify and help in places of code where error
%          states are handled, by making sure that no matter what is the
%          case after this call the state is terminated
%
%   Example
%
%       pid=api_core_progress('mypid','new');
%       ...
%       try
%           ...
%           api_core_error(api_core_l10n('Potentially catastrophic failure.'));
%           ...
%       catch err
%           if api_core_error
%               ...
%               possibly react to errors
%               ...
%           end;
%       end;
%       ...
%       api_core_complete(api_core_l10n('We are done in any case.'));
%       ...
%
%
%   See also API_CORE_PROGRESS, API_CORE_DEBUG, API_CORE_WARNING,
%   API_CORE_ERROR.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);

res=api_core_progress('head');
res=(~isempty(strmatch('complete',{res.state})))||(~isempty(strmatch('cancel',{res.state})))||(~isempty(strmatch('error',{res.state})));
if nargin>0
  st=api_core_checkopt(st,'STATUS','complete','cancel');
  if res res=api_core_progress('head');
  else res=api_core_progress(st,varargin{:});
  end;
end;

if nargout>0 out=res;
elseif nargin==0
  if res api_core_l10n('fprintf','The progress stack is terminated.\n');
  else api_core_l10n('fprintf','The progress stack is not terminated.\n');
  end;
end;
