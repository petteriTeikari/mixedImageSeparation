function out=api_core_init(mode,varargin)
%API_CORE_INIT Initialize everything.
%   %TODO: Write help text
%          () init core
%          ('initialize') init core
%          ('reinitialize') uninit and init all packages
%          ('uninitialize') uninit all packages
%          ('<mode>','<path>'...) do mode for listed packages
%          ('<mode>',<@entry>...) do mode for listed packages
%          ('reinitialize','<name>'...) uninit and init for listed packages
%          ('uninitialize','<name>'...) uninit for listed packages
%
%   See also API_CORE_DEFPACKAGE, API_CORE_DEFMODULE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);
if exist('mode','var') mode=api_core_checkopt(mode,'MODE','initialize','reinitialize','uninitialize'); else mode='initialize'; end;
corepath=fileparts(which('package_core'));
if isempty(corepath) corepath=fileparts(mfilename('fullpath')); end;
if nargin>1 list=varargin;
elseif any(strcmp(mode,{'reinitialize' 'uninitialize'})) list={'*'};
else list={corepath};
end;

api_core_persistent('lock');
pkgs=api_core_persistent('get','packages');
if isempty(pkgs)
  pkgs=[];
  pkgsv=api_core_defversion;
  pkgsv(1)=[];
  pkgsn={};
  pkgse={};
  pkgsp={};
else
  pkgsv=[pkgs.version];
  pkgsn={pkgsv.name};
  pkgse={pkgs.entry};
  pkgsp={pkgs.path};
end;

%TODO: Maybe in the future support any wildcard patterns
i=find(strcmp('*',list));
if ~isempty(i)
  list(i)=[];
  list=horzcat(list,pkgsn);
end;

res=true;
coreinit=true;
listi=zeros(1,numel(list));
for i=1:numel(list)
  ll=list{i};
  li=[];
  if isa(ll,'function_handle')
    if coreinit coreinit=~isequal(ll,@package_core); end;
    li=find(cellfun(@(f)isequal(f,ll),pkgse),1);
  elseif ~isempty(strfind(ll,filesep))
    if coreinit coreinit=~strcmp(ll,corepath); end;
    li=find(strcmp(ll,pkgsp),1);
  else
    if coreinit coreinit=~strcmp(ll,'core'); end;
    li=find(strcmp(ll,pkgsn),1);
  end;
  if ~isempty(li) listi(i)=li; end;
end;
if coreinit&&strcmp(mode,'initialize')
  list=horzcat({corepath},list);
  listi=[0 listi];
end;

api_core_progress('sub',api_core_l10n([upper(mode(1)) mode(2:end) '...']));
try
  if any(strcmp(mode,{'reinitialize' 'uninitialize'}))
    listc=0;
    listi(listi==0)=[];
    listi=unique(listi);
    api_core_progress('run',api_core_l10n('Checking package dependencies...'));
    j=setdiff(1:numel(pkgs),listi);
    i=1;
    while i<=numel(j)
      if ~isempty(intersect(pkgsn(listi),{pkgs(j(i)).requires(:).name}))
        if strcmp(mode,'reinitialize')
          listi=union(listi,j(i));
          j=setdiff(j,j(i));
          i=1;
        else
          res=false;
          api_core_error(api_core_l10n('sprintf','Cannot uninitialize packages since "%s" requires them!',pkgsn{j(i)}));
        end;
      else i=i+1;
      end;
    end;
    api_core_progress('sub',api_core_l10n('Uninitializing packages...'));
    listi=sort(listi);
    deflist=pkgs(listi);
    rlist=cell(size(deflist));
    if numel(deflist)>1 pl=numel(deflist); else pl=Inf; end;
    for i=numel(deflist):-1:1
      err=[];
      api_core_progress('run',1+numel(deflist)-i,pl,api_core_l10n('sprintf','Uninitializing package "%s".',deflist(i).version.name));
      api_core_progress('sub');
      try st=deflist(i).entry(deflist(i),'uninitialize');
      catch err
        if ~api_core_error api_core_debug(err); end;
        st=false;
      end;
      res=res&&st;
      api_core_complete('complete');
      if st
        listc=listc+1;
        api_core_progress('run',api_core_l10n('sprintf','Uninitialized package "%s".',deflist(i).version.name));
      else api_core_warning(api_core_l10n('sprintf','Cannot gracefully uninitialize package "%s"!',deflist(i).version.name),err);
      end;
      pkgs(listi(i))=[];
      api_core_persistent('set','packages',pkgs);
      if isempty(deflist(i).path) rlist{i}=deflist(i).entry;
      else
        rlist{i}=deflist(i).path;
        if ~strcmp(deflist(i).path,corepath)
          ws=warning('off','MATLAB:rmpath:DirNotFound');
          rmpath(deflist(i).path);
          warning(ws);
        end;
      end;
    end;
    if api_core_error api_core_error(api_core_l10n('Cannot uninitialize packages!')); end;
    api_core_complete('complete',api_core_l10n('Uninitialized packages.'));
    list=rlist;
    listi=[];
  end;
  
  if any(strcmp(mode,{'initialize' 'reinitialize'}))
    listc=0;
    list(listi>0)=[];
    api_core_progress('sub',api_core_l10n('Finding package definitions...'));
    deflist=api_core_defpackage;
    deflist(1)=[];
    for i=1:numel(list)
      err=[];
      errname=list{i};
      %TODO: Maybe in the future also check if asked to initialize the same package many times
      def=api_core_defpackage;
      if isa(list{i},'function_handle')
        def.entry=list{i};
        errname=func2str(list{i});
      elseif exist(list{i},'dir')
        def=api_core_parsedir(list{i},def);
        if exist(fullfile(list{i},'Contents.m'),'file') def=api_core_parsecontents(api_core_l10n('file',fullfile(list{i},'Contents.m')),def); end;
        if isfield(def,'path')&&(~isempty(def.path))
          pipes=dir(fullfile(def.path,'*.pipe'));
          for j=1:numel(pipes)
            %TODO: Maybe in the future handle different languages in the pipeline file
            piped=api_core_parsepipeline(fullfile(def.path,pipes(j).name),api_core_defmodule);
            if (~isempty(piped))&&isfield(piped,'version')&&isfield(piped.version,'name')&&(~isempty(piped.version.name))
              if isfield(piped.version,'container')&&isempty(piped.version.container) piped.version.container=def.version.name; end;
              if ~isfield(def,'modules')
                def.modules=api_core_defmodule;
                def.modules(1)=[];
                ind=[];
              elseif ~isempty(def.modules) ind=cellfun(@(f)isequal(f,piped.entry),{def.modules.entry});
              else ind=[];
              end;
              if isempty(ind)||(~any(ind)) def.modules(end+1)=piped; else def.modules(ind)=piped; end;
            end;
          end;
        end;
      end;
      if isfield(def,'entry')
        if isfield(def,'path')&&(~isempty(def.path))&&exist(fullfile(def.path),'dir')
          ws=warning('off','MATLAB:dispatcher:pathWarning');
          addpath(list{i},'-end');
          warning(ws);
        end;
        api_core_progress('sub');
        st=true;
        try def=def.entry(def,'definition');
        catch err
          if ~api_core_error api_core_debug(err); end;
          st=false;
        end;
        res=res&&st;
        api_core_complete('complete');
        if st
          api_core_progress('run',api_core_l10n('sprintf','Found definition for package "%s".',def.version.name));
          contlist=api_core_defmodule;
          contlist(1)=[];
          for j=1:numel(def.modules)
            conterr=[];
            conterrname=api_core_l10n('<none>');
            st=false;
            if ~isempty(def.modules(j).entry)
              conterrname=func2str(def.modules(j).entry);
              api_core_progress('sub');
              try
                def.modules(j)=def.modules(j).entry(def.modules(j),'definition');
                st=api_core_checkmodule(def.modules(j));
              catch err
                if ~api_core_error api_core_debug(err); end;
                st=false;
              end;
              res=res&&st;
              api_core_complete('complete');
            end;
            if st
              contlist(end+1)=def.modules(j);
              api_core_progress('run',api_core_l10n('sprintf','Found definition for %s "%s/%s".',contlist(end).type,contlist(end).version.container,contlist(end).version.name));
            else
              if isfield(def.modules(j),'type')&&(~isempty(def.modules(j).type)) conttype=def.modules(j).type; else conttype='module'; end;
              if isfield(def.modules(j),'version')&&isfield(def.modules(j).version,'name')&&(~isempty(def.modules(j).version.name)) conterrname=def.modules(j).version.name; end;
              if isfield(def.modules(j),'version')&&isfield(def.modules(j).version,'container')&&(~isempty(def.modules(j).version.container)) contpkgname=def.modules(j).version.container; else contpkgname=def.version.name; end;
              api_core_warning(api_core_l10n('sprintf','Not a valid definition for %s "%s/%s"!',conttype,contpkgname,conterrname),conterr);
              err=conterr;
              res=false;
            end;
          end;
          def.modules=contlist;
          if api_core_checkpackage(def)
            deflist(end+1)=def;
            errname=def.version.name;
            if ~isempty(err)
              api_core_warning(api_core_l10n('sprintf','Cannot completely define package "%s"!',errname));
              res=false;
            end;
          end;
        else
          if isfield(def,'version')&&isfield(def.version,'name')&&(~isempty(def.version.name)) errname=def.version.name; end;
          api_core_warning(api_core_l10n('sprintf','Not a valid definition for package "%s"!',errname),err);
          res=false;
        end;
      end;
    end;
    if api_core_error api_core_error(api_core_l10n('Cannot find definitions!')); end;
    api_core_complete('complete',api_core_l10n('Definitions found.'));
    api_core_progress('sub',api_core_l10n('Checking package dependencies...'));
    %TODO: Maybe in the future find the optimal dependency order of both pkgs and deflist
    for i=numel(deflist):-1:1
      dn=deflist(i:end).version;
      if ~isempty(intersect({dn(:).name},{deflist(i).requires(:).name}))
        deflist=horzcat(deflist(1:(i-1)),deflist((i+1):end),deflist(i));
      end;
    end;
    listi=[];
    for i=1:numel(deflist)
      if isempty(pkgs) rf=true;
      else [rf,err]=api_core_checkpackage([pkgs deflist(listi)],deflist(i));
      end;
      if rf listi=[listi i];
      else api_core_warning(api_core_l10n('sprintf','Requirements for package "%s" cannot be fulfilled!',deflist(i).version.name),err);
      end;
    end;
    deflist=deflist(listi);
    if api_core_error api_core_error(api_core_l10n('Cannot check dependencies!')); end;
    api_core_complete('complete',api_core_l10n('Dependencies checked.'));
    api_core_progress('sub',api_core_l10n('Initializing packages...'));
    if numel(deflist)>1 pl=numel(deflist); else pl=Inf; end;
    for i=1:numel(deflist)
      err=[];
      api_core_progress('run',i,pl,api_core_l10n('sprintf','Initializing package "%s".',deflist(i).version.name));
      if isempty(pkgs) pkgs=deflist(i); else pkgs(end+1)=deflist(i); end;
      api_core_persistent('set','packages',pkgs);
      api_core_progress('sub');
      try st=deflist(i).entry(deflist(i),'initialize');
      catch err
        if ~api_core_error api_core_debug(err); end;
        st=false;
      end;
      res=res&&st;
      api_core_complete('complete');
      if st
        listc=listc+1;
        api_core_progress('run',api_core_l10n('sprintf','Initialized package "%s".',deflist(i).version.name));
      else
        pkgs(end)=[];
        api_core_persistent('set','packages',pkgs);
        api_core_warning(api_core_l10n('sprintf','Cannot successfully initialize package "%s"!',deflist(i).version.name),err);
        res=false;
      end;
    end;
    if api_core_error api_core_error(api_core_l10n('Cannot initialize packages!')); end;
    api_core_complete('complete',api_core_l10n('Initialized packages.'));
  end;
catch err
  api_core_error(err);
end;
api_core_complete('complete',api_core_l10n([upper(mode(1)) mode(2:end) ' completed.']));

if nargout>0 out=res;
else
  if strcmp(mode,'initialize') api_core_l10n('fprintf','Successfully initialized %i packages.\n\n',listc);
  elseif strcmp(mode,'reinitialize') api_core_l10n('fprintf','Successfully reinitialized %i packages.\n\n',listc);
  elseif strcmp(mode,'uninitialize') api_core_l10n('fprintf','Successfully uninitialized %i packages.\n\n',listc);
  end;
end;
