function out=arabica_version(mode)
%ARABICA_VERSION Print or output version details.
%   %TODO: Write help text
%          () all details
%          ('all') all details
%          ('framework') details only of framework
%
%   NOTE: This function automatically performs initialization if necessary.
%
%   See also ARABICA.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

arabica_init;

api_core_checknarg(0,1,0,1);
if exist('mode','var') mode=api_core_checkopt(mode,'MODE','framework','all'); else mode='all'; end;

ver=api_core_persistent('get','arabica');
if strcmp(mode,'all')
  ver.library=api_core_library('list');
  ver.progress=api_core_persistent('get','progress');
else ver=rmfield(ver,'initlog');
end;
%TODO: Maybe in the future get further details like available versions online

if nargout==0
  fprintf('\nArabica: %i.%i\n',ver.definition.version.major,ver.definition.version.minor);
  fprintf('\n%s\n',ver.definition.description);
  api_core_l10n('fprintf','\nUsing these configuration files:\n');
  if isempty(ver.config.arabica.configfiles) api_core_l10n('fprintf','  <none>\n');
  else fprintf('  %s\n',ver.config.arabica.configfiles{:});
  end;
  api_core_l10n('fprintf','\nSearching for packages under these directories:\n');
  fprintf('  %s\n',ver.config.arabica.packagepaths{:});
  if strcmp(mode,'all')
    ver.packages=api_core_persistent('get','packages');
    if ~isempty(ver.packages)
      api_core_l10n('fprintf','\nCurrently initialized packages include:\n');
      for i=1:length(ver.packages)
        fprintf('  %s: %i.%i\n',ver.packages(i).version.name,ver.packages(i).version.major,ver.packages(i).version.minor);
        %TODO: Maybe in the future more details like description, requires and suggests
      end;
    end;
    %TODO: Print details of ver.library
    %TODO: Print details of ver.progress
    if isfield(ver,'initlog')&&(~isempty(ver.initlog))
      api_core_l10n('fprintf','\nErrors occured during initialization include:\n');
      %TODO: Maybe in the future pretty-print ver.initlog
    end;
  end;
  fprintf('\n');
else out=ver;
end;
