function out=api_core_caller(ref)
%API_CORE_CALLER Find the package and potential module name of the caller.
%   %TODO: Write help text
%          () return the calling function's package and potential module name
%          (<@function>) return the handled function's package and potential
%          module name
%          ('<function>') return the named function's package and potential
%          module name
%
%          outputs {'<package>' '<module>'} when caller is a module
%          outputs {'<package>' ''} when caller is a package
%          outputs {'core' ''} when the only valid caller in the stack is core
%          itself
%
%          this will first look initialized modules/packages
%          then if possible looks in the directory of the function
%          if found through the directory outputs full paths instead of names
%
%   See also API_CORE_ISPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,1);
if exist('ref','var')&&(~isempty(ref))
  mode=api_core_checkarg(ref,{'FUNC' 'function';'FUNC' 'str'});
  st=struct('file',{''},'name',{''},'line',{0});
  if mode==1 st.name=func2str(ref);
  elseif mode==2 st.name=ref;
  end;
  st.file=which(st.name);
  stfs={ref};
else
  mode=2;
  st=dbstack(1,'-completenames');
  stfs={st.name};
end;

%TODO: Maybe in the future optimize with an answer cache of recent or frequent callers stacks

[mods,pkgs]=api_core_modules;
if isempty(mods) modfs={};
else
  modfs={mods.entry};
  corei=cellfun(@(f)isequal(f,@module_core),modfs);
  if mode==2 modfs=cellfun(@func2str,modfs,'UniformOutput',false); end;
  mods(corei)=[];
  modfs(corei)=[];
end;
if isempty(pkgs) pkgfs={};
else
  pkgfs={pkgs.entry};
  corei=cellfun(@(f)isequal(f,@package_core),pkgfs);
  if mode==2 pkgfs=cellfun(@func2str,pkgfs,'UniformOutput',false); end;
  pkgs(corei)=[];
  pkgfs(corei)=[];
end;

if mode==1
  %TODO: Maybe in the future optimize all this looping
  m=[];
  for i=1:length(stfs)
    if ~isempty(modfs)
      m=mods(cellfun(@(f)isequal(f,stfs{i}),modfs));
      if ~isempty(m)
        out={m(1).version.container m(1).version.name};
        return;
      end;
    end;
    if ~isempty(pkgfs)
      m=pkgs(cellfun(@(f)isequal(f,stfs{i}),pkgfs));
      if ~isempty(m)
        out={m(1).version.name ''};
        return;
      end;
    end;
  end;
elseif mode==2
  [m,sti,modi]=intersect(stfs,modfs);
  if ~isempty(modi)
    out={mods(modi(1)).version.container mods(modi(1)).version.name};
    return;
  end;
  [m,sti,pkgi]=intersect(stfs,pkgfs);
  if ~isempty(pkgi)
    out={pkgs(pkgi(1)).version.name ''};
    return;
  end;
end;

corepath=fileparts(which('package_core'));
if isempty(corepath) corepath=fileparts(mfilename('fullpath')); end;
for i=1:length(st)
  pathname=fileparts(st(i).file);
  if (~strcmp(pathname,corepath))&&api_core_ispackage(pathname)
    out={pathname ''};
    return;
  end;
end;
out={'core' ''};
