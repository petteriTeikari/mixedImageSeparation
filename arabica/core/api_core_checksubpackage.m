function out=api_core_checksubpackage(varargin)
%API_CORE_CHECKSUBPACKAGE Check if a function or file can be located.
%   API_CORE_CHECKSUBPACKAGE(NAME) tries to locate the named function or
%   file and if not looks for it recursively under the caller's directory.
%   If it is found in a subdirectory its added to Matlab path.
%
%   API_CORE_CHECKSUBPACKAGE(BASE, NAME) tries to locate under base
%   directory BASE.
%
%   API_CORE_CHECKSUBPACKAGE(..., DIRS) tries to locate  only in
%   subdirectories DIRS.
%
%   API_CORE_CHECKSUBPACKAGE(..., DIRS, HUMAN) uses HUMAN as the human
%   readable name of the package to locate and if all else fails asks the
%   user for a directory if running in a desktop.
%
%   OUT = API_CORE_CHECKSUBPACKAGE returns the result as a logical
%
%   Example:
%     API_CORE_CHECKSUBPACKAGE('myfun')
%     API_CORE_CHECKSUBPACKAGE('myfun', 'mydir', 'My Toolbox')
%
%   See also API_CORE_ISPACKAGE, EXIST.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,4);
base='';
dirs={};
name='';
if isempty(varargin{1})||(~isempty(strfind(varargin{1},filesep)))||exist(fullfile(varargin{1}),'dir')||(nargin>3)
  api_core_checknarg(0,1,2,4);
  api_core_checkarg(varargin{1},'BASE','str');
  base=char(varargin{1});
  varargin(1)=[];
else
  d=evalin('caller','fileparts(mfilename(''fullpath''))');
  if ischar(d)&&exist(fullfile(d),'dir') base=d; end;
end;
api_core_checkarg(varargin{1},'NAME','str');
fn=varargin{1};
varargin(1)=[];
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'DIRS','str');
  dirs=cellstr(varargin{1});
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'HUMAN','str');
  name=char(varargin{1});
  varargin(1)=[];
end;

res=(~isempty(fullfile(which(fn))))||exist(fullfile(fn),'file');
if ~res
  i=0;
  while (~res)&&(i<=(numel(dirs)+1))
    d='';
    if i==0
      if exist(fullfile(base),'dir') d=fullfile(base); end;
    elseif i>numel(dirs)
      if (~isempty(name))&&desktop('-inuse')
        ud=uigetdir(base,api_core_l10n('sprintf','Select the directory of the %s package',name));
        if ischar(ud)&&exist(fullfile(ud),'dir') d=fullfile(ud); end;
      end;
    else
      if (~isempty(dirs{i}))&&exist(fullfile(base,dirs{i}),'dir') d=fullfile(base,dirs{i}); end;
    end;
    if ~isempty(d)
      res=exist(fullfile(d,[fn '.m']),'file')||exist(fullfile(d,[fn '.p']),'file')||exist(fullfile(d,[fn '.mex']),'file')||exist(fullfile(d,fn),'file');
      if res
        ws=warning('off','MATLAB:dispatcher:pathWarning');
        addpath(fullfile(d),'-end');
        warning(ws);
        break;
      end;
    end;
    i=i+1;
  end;
  res=(~isempty(fullfile(which(fn))))||exist(fullfile(fn),'file');
end;

if nargout>0 out=res;
else
  if ~isempty(name) name=[' ' name]; end;
  if res api_core_l10n('fprintf','Package%s is present.\n\n',name);
  else api_core_l10n('fprintf','Package%s is not present.\n\n',name);
  end;
end;
