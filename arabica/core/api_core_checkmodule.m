function out=api_core_checkmodule(mtest)
%API_CORE_CHECKMODULE Check module definition structure(s).
%   %TODO: Write help text
%          (mtest) if valid module definition
%          output is bool for validity test
%
%   See also API_CORE_DEFMODULE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,1);
api_core_checkarg(mtest,'TEST','struct');
res=(numel(fieldnames(mtest))==18)&&all(strcmp(sort(fieldnames(mtest)),sort({'type';'entry';'version';'name';'package';'packageversion';'date';'description';'icon';'position';'rotation';'tags';'uri';'citations';'authors';'exeauthors';'exeversion';'parameters'})));
%TODO: Check validity of each field in mtest(:)

if nargout>0 out=res;
else
  if all(res) api_core_l10n('fprintf','Valid module definition(s).\n\n');
  else
    api_core_l10n('fprintf','Not valid module definition(s).\n\n');
    if exist('err','var') fprintf('  %s\n',err); end;
  end;
end;
