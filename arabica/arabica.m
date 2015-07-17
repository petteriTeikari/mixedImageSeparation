function arabica
%ARABICA Launch Arabica Toolbox.
%   ARABICA launches the Arabica framework in either desktop or
%   command-line mode depending on wheather the Matlab desktop is open or
%   not. 
%
%   NOTE: This function automatically performs initialization if necessary.
%
%   See also ARABICA_VERSION.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

if usejava('jvm')&&desktop('-inuse')
  %TODO: Launch main user interface which calls arabica_init with its progress handler
  arabica_init('cli'); %DEBUG
else
  arabica_init;
  api_core_l10n('fprintf','Arabica is initialized and running in command-line mode.\n\n');
end;
