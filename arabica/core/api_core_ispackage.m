function out=api_core_ispackage(name)
%API_CORE_ISPACKAGE Check if a valid package.
%   %TODO: Write help text
%          ('<path>') check if the dir contains a valid package
%          ('<name>') check the name from already initialized packages
%
%   Returns true if a valid package and false otherwise.
%
%   See also API_CORE_DEFPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,1);
api_core_checkarg(name,'NAME','str');

%TODO: Maybe in the future optimize with an answer cache of recent or frequent directories

res=false;
if exist(name,'dir')
  t=api_core_parsedir(name);
  if isfield(t,'entry') res=true;
  else t=api_core_parsecontents(api_core_l10n('file',fullfile(name,'Contents.m')));
  end;
  if isfield(t,'entry') res=true; end;
elseif isempty(strfind(name,filesep))
  %TODO: Find package name from already initialized packages
  error('API_CORE_ISPACKAGE:unimplemented','Unimplemented case.');
else error('API_CORE_ISPACKAGE:invalidInput','The given PATH must point to an existing directory.');
end;
if nargout>0 out=res;
else
  if exist(name,'dir')
    if res api_core_l10n('fprintf','The directory "%s" contains a valid package.\n',name);
    else api_core_l10n('fprintf','The directory "%s" does not contain a valid package.\n',name);
    end;
  elseif ~strfind(name,filesep)
    if res api_core_l10n('fprintf','The initialized packages include "%s".\n',name);
    else api_core_l10n('fprintf','The initialized packages do not include "%s".\n',name);
    end;
  end;
end;
