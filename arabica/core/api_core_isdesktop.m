function out=api_core_isdesktop
%API_CORE_ISDESKTOP Check if it is possible to use graphical user interfaces.
%   Returns true if possible and false otherwise.
%
%   See also DESKTOP, USEJAVA, JAVACHK.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

try
  %TODO: Maybe in the future we can be even more clever.
  out=usejava('jvm')&&desktop('-inuse');
  if (~out)&&usejava('jvm')
    r=get(0);
    out=(r.ScreenDepth>0)&&any(r.ScreenSize>1);
  end;
catch err
  out=false;
end;
