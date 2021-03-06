function out=api_core_store(mode,varargin)
%API_CORE_STORE Manipulate or query the runtime persistent store.
%   %TODO: Write help text
%          () call api_core_persistent('get','store.<package>')
%          ('who') call api_core_persistent('who','store.<package>')
%          ('who',<path>...) call api_core_persistent('who','store.<package>',<path>...)
%          ('get',<path>...) call api_core_persistent('get','store.<package>',<path>...)
%          ('set',<path>...,<value>) call api_core_persistent('set','store.<package>',<path>...,<value>)
%
%          works just like api_core_persistent except automatically adds the
%          package and potential module name as the first part of the path
%
%   See also API_CORE_CONFIG, API_CORE_PERSISTENT.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);
if exist('mode','var') mode=api_core_checkopt(mode,'MODE','who','get','set'); else mode='get'; end;
api_core_persistent('lock');

caller=api_core_caller;
res=api_core_persistent(mode,'store',caller{:},varargin{:});
if nargout>0 out=res; end;
