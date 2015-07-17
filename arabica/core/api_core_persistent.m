function out=api_core_persistent(mode,varargin)
%API_CORE_PERSISTENT Interface to persistent storage.
%   %TODO: Write help text
%          () output or print status
%          ('status') print or output status
%          ('lock') initialize storage
%          ('unlock') clear everything and uninitialize
%          ('who') print or output who of all
%          ('who',<path>...) print or output who under path
%          ('get',<path>...) get the value of path
%          ('set',<path>...,<value>) set the value of path
%          ('clear',<path>...) clear the path
%
%          lock and unlock output whether the status was really changed and both
%          get and set output the value
%
%          the idea is that this function seldomly if ever needs to be called
%          directly but other functions offer better access while automatically
%          finding the calling package name and keeping the storage intact
%
%   See also API_CORE_INIT, API_CORE_CONFIG, API_CORE_STORE, API_CORE_PROGRESS,
%   PERSISTENT, MLOCK.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

persistent storage;
persistent lock;
if ~isstruct(storage) storage=struct([]); end;
if isempty(lock) lock={false now}; end;

api_core_checknarg(0,1,0,Inf);
if exist('mode','var') mode=api_core_checkopt(mode,'MODE','unlock','lock','status','who','get','set','clear'); else mode='status'; end;
%TODO: Maybe in the future make varargin type safe too
%TODO: Maybe in the future add function friend lists or check api_core_caller=={'core' ''}

if strcmp(mode,'unlock')
  res=false;
  if lock{1}
    res=true;
    storage=struct([]);
    lock={false now};
  end;
  if mislocked munlock; end;
  if nargout>0 out=res; end;
elseif strcmp(mode,'lock')
  res=false;
  if ~lock{1}
    res=true;
    lock={true now};
  end;
  if ~mislocked mlock; end;
  if nargout>0 out=res; end;
elseif strcmp(mode,'status')
  if nargout>0 out=lock{1};
  else
    if lock{1} api_core_l10n('fprintf','Locked since %<datetime>.\n',lock{2});
    else api_core_l10n('fprintf','Unlocked since %<datetime>.\n',lock{2});
    end;
  end;
elseif strcmp(mode,'who')
  if ~lock{1} error('API_CORE_PERSISTENT:invalidState','Before using who the persistent storage must be locked.'); end;
  ss=path2subs(struct('type',{'()'},'subs',{{1}}),varargin{:});
  try temp=subsref(storage,ss); catch temp=struct([]); end;
  
  st=api_core_whos(temp);
  if ischar(ss(end).subs) st.name=ss(end).subs; else st.name=''; end;
  if isstruct(temp)
    names=fieldnames(temp);
    for i=1:length(names)
      st(1+i)=api_core_whos(temp.(names{i}));
      st(1+i).name=names{i};
    end;
  end;
  if nargout>0 out=st;
  else
    api_core_l10n('fprintf','  Name                        Size       Bytes  Class       Attributes\n\n');
    ts=[sprintf('%i',st(1).size(1)) sprintf('x%i',st(1).size(2:end))];
    if st(1).sparse ta='sparse'; else ta=''; end;
    if st(1).complex
      if isempty(ta) ta='complex'; else ta=[ta ', complex']; end;
    end;
    fprintf('  %-20s  %10s  %10i  %-10s  %s\n\n',st(1).name,ts,st(1).bytes,st(1).class,ta);
    if length(st)>1
      api_core_l10n('fprintf','  Fieldname                   Size       Bytes  Class       Attributes\n\n');
      for i=2:length(st)
        ts=[sprintf('%i',st(i).size(1)) sprintf('x%i',st(i).size(2:end))];
        if st(i).sparse ta='sparse'; else ta=''; end;
        if st(i).complex
          if isempty(ta) ta='complex'; else ta=[ta ', complex']; end;
        end;
        fprintf('  %-20s  %10s  %10i  %-10s  %s\n',st(i).name,ts,st(i).bytes,st(i).class,ta);
      end;
      fprintf('\n');
    end;
  end;
elseif strcmp(mode,'get')
  if ~lock{1} error('API_CORE_PERSISTENT:invalidState','Before using get the persistent storage must be locked.'); end;
  try out=subsref(storage,path2subs(struct('type',{'()'},'subs',{{1}}),varargin{:}));
  catch err
    if strcmp(err.identifier,'MATLAB:nonExistentField') out=[]; else rethrow(err); end;
  end;
elseif strcmp(mode,'set')
  if ~lock{1} error('API_CORE_PERSISTENT:invalidState','Before using set the persistent storage must be locked.'); end;
  ss=path2subs(struct('type',{'()'},'subs',{{1}}),varargin{1:(end-1)});
  if isempty(ss) error('API_CORE_PERSISTENT:invalidInput','The PATH cannot be empty.'); end;
  % subsasgn(storage,ss,varargin{end}); % old
  storage = subsasgn(storage,ss,varargin{end});
  if nargout>0 out=varargin{end}; end;
elseif strcmp(mode,'clear')
  if ~lock{1} error('API_CORE_PERSISTENT:invalidState','Before using clear the persistent storage must be locked.'); end;
  ss=path2subs(struct('type',{'()'},'subs',{{1}}),varargin{:});
  try
    res=subsref(storage,ss);
    if (length(ss)>1)&&strcmp(ss(end).type,'.')
      if length(ss)==2 storage=rmfield(storage,ss(end).subs);
      else
          %subsasgn(storage,ss(1:(end-1)),rmfield(subsref(storage,ss(1:(end-1))),ss(end).subs));
          storagae = subsasgn(storage,ss(1:(end-1)),rmfield(subsref(storage,ss(1:(end-1))),ss(end).subs));
          
      end;
      if nargout>0 out=res; end;
    end;
  catch err
    if any(strcmp(err.identifier,{'MATLAB:nonExistentField' 'MATLAB:rmfield:InvalidFieldname'})) out=[]; else rethrow(err); end;
  end;
end;

function s=path2subs(varargin)
%PATH2SUBS Convert any kind of path reference into subsref.
%   %TODO: Write help text
%          
%
%   See also SUBSREF, SUBSASGN.

thedot={'.'};
s=struct('type',{},'subs',{});
for i=1:length(varargin)
  if isstruct(varargin{i}) s=horzcat(s,varargin{i}(:).');
  elseif iscell(varargin{i}) s=horzcat(s,path2subs(varargin{i}{:}));
  elseif ischar(varargin{i})
    for j=1:size(varargin{i},1);
      l=strtrim(regexp(varargin{i}(j,:),'[^.]*','match'));
      s=horzcat(s,struct('type',thedot(ones(size(l))),'subs',l));
    end;
  end;
  %TODO: Maybe in the future support other subs than . too
end;
