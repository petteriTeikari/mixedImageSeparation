function out=api_core_error(msg,varargin)
%API_CORE_ERROR Add an error message to the current stack or ask status.
%   %TODO: Write help text
%          () outputs true if the current head of the current stack is an
%          error message or when a sub stack if that substack has any error
%          messages and false otherwise
%          ('<message>',...) add a new error message with the given text and all
%          the following arguments are set as data Note: after adding the
%          message error() is called to raise an exception
%
%          (<exception>,...) if not already in error state add a new error
%          message based on the given Matlab error structure or object and
%          all the following arguments are set as data. Note: after adding
%          the message no exception is raised.
%
%          unlike the matlab error() this is a completely silent command
%
%          the idea is to clarify and help in places of code where error states
%          are handled
%
%   Example
%
%       pid=api_core_progress('mypid','new');
%       ...
%       try
%           ...
%           api_core_error(api_core_l10n('We have a catastrophic failure.'));
%           ...
%       catch err
%           if api_core_error
%               ...
%               possibly react to errors
%               ...
%           end;
%       end;
%       ...
%
%
%   See also API_CORE_PROGRESS, API_CORE_COMPLETE, API_CORE_DEBUG,
%   API_CORE_WARNING.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);
res=api_core_progress('head');
if ~isempty(res.sub) res=horzcat(res,res.sub); end;
res=~isempty(strmatch('error',{res.state}));
if nargin>0
  mode=api_core_checkarg(msg,{'MESSAGE' 'str';'EXCEPTION' 'scalar struct';'EXCEPTION' 'scalar MException'});
  if mode==1
    res=api_core_progress('error',msg,varargin{:});
    error(sprintf('API_CORE_ERROR:%s',res),msg);
  elseif (mode>1)&&(~res)
    res=api_core_progress('error',api_core_l10n('sprintf','%s -- %s',msg.identifier,msg.message),msg,varargin{:});
  end;
end;

if nargout>0 out=res;
elseif nargin==0
  if res api_core_l10n('fprintf','The progress stack has error messages.\n');
  else api_core_l10n('fprintf','The progress stack does not have error messages.\n');
  end;
end;
