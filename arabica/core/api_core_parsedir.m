function out=api_core_parsedir(dirpath,def)
%API_CORE_PARSEDIR Parse a directory for package details.
%   %TODO: Write help text
%          ('<path>') def ready filled in using files under path
%          ('<path>',<package>) given def appended using files under path
%
%          the idea is that this function fills in as much details as it can
%          based on the naming convention of package_<modulename>.* and
%          <moduletype>_<modulename>.* files without ever trying to call those
%          functions
%
%          the difference to api_core_defpackage is that the output is not
%          guaranteed to be a valid package definition structure but only
%          contains the found details
%
%   See also API_CORE_PARSECONTENTS, API_CORE_ISPACKAGE, API_CORE_DEFPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,2);
api_core_checkarg(dirpath,'PATH','str');
if ~exist(dirpath,'dir') error('API_CORE_PARSEDIR:invalidInput','Path must point to an existing directory.'); end;
if exist('def','var')&&api_core_checkarg(def,'BASE','struct') out=def; else out=struct([]); end;

d=[dir(fullfile(dirpath,'*.m'));dir(fullfile(dirpath,'*.p'));dir(fullfile(dirpath,'*.mex'));dir(fullfile(dirpath,'template_*.pipe'))];
fns=regexp({d(:).name},'^(package|module|wrap|visualize|template|wizard|api)_(.+)\.(m|p|mex|pipe)$','tokens');
if ~isempty(fns) fns=vertcat(fns{:}); end;
if ~isempty(fns) fns=vertcat(fns{:}); end;
if ~isempty(fns)
  i=find(strcmp(fns(:,1),'package'));
  if numel(i)==1
    out(1).version.container='framework';
    out(1).version.name=fns{i,2};
    out(1).path=dirpath;
    out(1).entry=str2func(['package_' out(1).version.name]);
    out(1).name=fns{i,2};
    fns(i,:)=[];
    for i=1:size(fns,1)
      fnsc=[fns{i,1} '_' fns{i,2}];
      if strcmp(fns{i,1},'template')
        if ~isfield(out,'templates') out(1).templates={}; end;
        if isempty(out(1).templates)||(~any(strcmp(fnsc,out(1).templates))) out(1).templates{end+1}=fnsc; end;
      elseif strcmp(fns{i,1},'api')
        if ~isfield(out,'api') out(1).api={}; end;
        if isempty(out(1).api)||(~any(strcmp(fnsc,out(1).api))) out(1).api{end+1}=fnsc; end;
      elseif any(strcmp(fns{i,1},{'module' 'wrap' 'visualize' 'wizard'}))
        if ~isfield(out,'modules')
          out(1).modules=api_core_defmodule;
          out(1).modules(1)=[];
          ind=[];
        elseif ~isempty(out(1).modules) ind=cellfun(@(f)isequal(f,str2func(fnsc)),{out(1).modules.entry});
        else ind=[];
        end;
        mn=regexp(fns{i,2},'^(.+)_([^_]+)$','tokens');
        if isempty(mn) mn={out(1).version.name,fns{i,2}}; else mn=mn{1}; end;
        if isempty(ind)||(~any(ind)) out(1).modules(end+1)=api_core_defmodule(fns{i,1},str2func(fnsc),api_core_defversion(mn{:}),mn{2},mn{1});
        else
          out(1).modules(ind).type=fns{i,1};
          out(1).modules(ind).version.container=mn{1};
          out(1).modules(ind).version.name=mn{2};
          out(1).modules(ind).name=mn{2};
          out(1).modules(ind).package=mn{1};
        end;
      end;
    end;
  end;
end;
