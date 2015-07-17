function [opt,err,id]=api_core_checkopt(arg,name,varargin)
%API_CORE_CHECKOPT Check best matching option.
%   API_CORE_CHECKOPT(ARG, NAME, VALID) for a char array or a cell array of
%   strings VALID checks whether the argument ARG matches any option
%   in VALID. If not, API_CORE_CHECKOPT issues a formatted error message
%   using NAME.
%
%   API_CORE_CHECKOPT(ARG, NAME, VALID1, VALID2, ...) checks according to the
%   list of options {VALID1, VALID2, ...}.
%
%   API_CORE_CHECKOPT(ARG, NAME) simply returns ARG.
%
%   OPT = API_CORE_CHECKOPT(...) returns the best matching option.
%
%   [OPT, ERR] = API_CORE_CHECKOPT(...) does not issue a formatted error
%   message. Instead it returns the error message in ERR.
%
%   [OPT, ERR, ID] = API_CORE_CHECKOPT(...) does not issue a formatted error
%   message. Instead it returns the error message in ERR and the
%   error id in ID.
%
%   Example:
%     API_CORE_CHECKOPT('bi','A', 'linear', 'bilinear')
%
%   See also API_CORE_CHECKARG, API_CORE_CHECKNARG, API_CORE_CHECKPARAM,
%   STRMATCH.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

lid='';
lerr='';
lopt='';

try
  if nargin==2 lopt=arg;
  elseif nargin>=3
    if nargin==3 opts=varargin{1};
    else opts=varargin;
    end;
    targ=lower(arg);
    topts=lower(opts);
    i=strmatch(targ,topts,'exact');
    if length(i)~=1 i=strmatch(targ,topts); end;
    if length(i)==1
      if ischar(opts) lopt=deblank(opts(i,:));
      else lopt=opts{i};
      end;
    elseif isempty(i)
      if ischar(opts) temp=sort(cellstr(opts));
      else temp=sort(opts);
      end;
      lerr=sprintf('Option "%s" for %s is invalid, correct values include: "%s"',arg,name,temp{1});
      lerr=[lerr sprintf(', "%s"',temp{2:end})];
    else
      if ischar(opts) temp=sort(cellstr(opts(i,:)));
      else temp=sort(opts(i));
      end;
      lerr=sprintf('Option "%s" for %s is ambiguous, possible matches include: "%s"',arg,name,temp{1});
      lerr=[lerr sprintf(',"%s"',temp{2:end})];
    end;
  elseif nargin<2 error('API_CORE_CHECKOPT:invalidInput','Not enough input arguments.');
  end;
catch err
  if isempty(err.identifier)||isempty(strmatch(err.identifier,'API_CORE_CHECKOPT'))
    if ~((ischar(arg)&&(size(arg,1)==1))||(iscellstr(arg)&&(length(arg)==1)))
      error('API_CORE_CHECKOPT:invalidInput','Invalid ARG input argument.');
    elseif ~((ischar(name)&&(size(name,1)==1))||(iscellstr(name)&&(length(name)==1)))
      error('API_CORE_CHECKOPT:invalidInput','Invalid NAME input argument.');
    elseif nargin==3
      %TODO: Check char array or cellstr
      error('API_CORE_CHECKOPT:invalidInput','Invalid VALID input argument.');
    elseif nargin>3
      %TODO: Check list of strings
      error('API_CORE_CHECKOPT:invalidInput','Invalid option list.');
    else error('API_CORE_CHECKOPT:invalidInput','Invalid input argument(s).');
    end;
  else rethrow(err);
  end;
end;

if lerr
  st=dbstack(1);
  if isempty(st) name='API_CORE_CHECKOPT';
  else name=upper(st(1).name);
  end;
  if isempty(lid) lid='invalidInput'; end;
  lid=[name ':' lid];
end;

[opt,err,id]=deal(lopt,lerr,lid);
if (nargout<=1)&&(~isempty(lerr))
  cerr.message=lerr;
  cerr.identifier=lid;
  cerr.stack=st;
  lasterror(cerr);
  rethrow(cerr);
elseif nargout>3 error('API_CORE_CHECKOPT:invalidOutput','Too many output arguments.');
end;
