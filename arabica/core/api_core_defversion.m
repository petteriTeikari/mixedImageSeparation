function out=api_core_defversion(cont,name,major,minor)
%API_CORE_DEFVERSION Create a version definition structure.
%   %TODO: Write help text
%          () empty def that needs to be filled in
%          ('<container>') def upto container
%          ('<container>','<name>') def upto name
%          ('<container>','<name>',major) def upto major
%          ('<container>','<name>',major,minor) full def
%
%          conventions for valid versions
%          ('framework','<package>') version def for a package
%          ('<package>','<module>') version def for a module
%
%   See also API_CORE_CHECKVERSION, API_CORE_DEFPACKAGE, API_CORE_DEFMODULE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,4);

out.container='';
out.name='';
out.major=0;
out.minor=0;
if exist('cont','var')&&api_core_checkarg(cont,'CONTAINER','str') out.container=char(cont); end;
if exist('name','var')&&api_core_checkarg(name,'NAME','str') out.name=char(name); end;
if exist('major','var')&&api_core_checkarg(major,'MAJOR','integer') out.major=major; end;
if exist('major','var')&&api_core_checkarg(minor,'MINOR','integer') out.minor=minor; end;
