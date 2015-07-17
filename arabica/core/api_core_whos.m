function out=api_core_whos(unknown,name)
%API_CORE_VARIABLE_WHOS Wrapper for Matlab's builtin whos.
%   This is needed to circumvent the stupidity in Matlab's whos, i.e. it cannot
%   report on nested structs or cell arrays.
%
%   API_CORE_WHOS(VAR) prints details of the variable VAR just like the builtin
%   function does. Note: Unlike in the builtin function VAR is the real
%   variable, not its name.
%
%   API_CORE_WHOS(VAR,NAME) uses the given name
%
%   See also WHOS, WHO.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,2);
stupid=unknown;
if ~isempty(inputname(1))
  try st=evalin('caller',['whos(''' inputname(1) ''');']); catch st=whos('unknown'); end;
else st=whos('unknown');
end;
if exist('name','var')&&api_core_checkarg(name,'NAME','str') st.name=name; end;
if nargout>0 out=st;
else
  api_core_l10n('fprintf','  Name                        Size       Bytes  Class       Attributes\n\n');
  ts=[sprintf('%i',st(1).size(1)) sprintf('x%i',st(1).size(2:end))];
  tal={'global' 'sparse' 'complex' 'persistent'};
  tal=tal([st.global st.sparse st.complex st.persistent]);
  if isempty(tal) ta='';
  else
    ta=tal{1};
    if length(tal)>1 ta=[ta sprintf(', %s',tal{2:end})]; end;
  end;
  fprintf('  %-20s  %10s  %10i  %-10s  %s\n\n',st(1).name,ts,st(1).bytes,st(1).class,ta);
end;
