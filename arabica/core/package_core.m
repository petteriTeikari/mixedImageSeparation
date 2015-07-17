function [out,mode]=package_core(varargin)
%PACKAGE_CORE Entry point for Core API package.
%   %TODO: Write help text
%          () same as ('definition')
%          ('definition') same as ([],'definition')
%          (<definition>,'definition') customize given package def struct while
%          it is possible that the given definition is empty and output the
%          fully filled in definition that must validate through
%          api_core_checkpackage
%          (<definition>,'initialize') initialize package and output bool for
%          success
%          (<definition>,'uninitialize') uninitialize package and output bool
%          for success
%
%          the idea is to serve as a default implementation meaning that any
%          valid package conforming to conventions can forward all calls
%          directly to this function
%          the first output is varied according to the calling '<mode>'
%          the second output is the validated calling '<mode>'
%
%          package entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also API_CORE_DEFPACKAGE, API_CORE_CHECKPACKAGE, API_CORE_DEFMODULE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,2,0,2);
if nargin==0
  def=[];
  mode='definition';
elseif nargin==1
  def=[];
  mode=api_core_checkopt(varargin{1},'MODE','definition');
  varargin(1)=[];
elseif nargin>1
  def=varargin{1};
  mode=varargin{2};
  if ~isempty(def) api_core_checkarg(def,'DEFINITION','scalar struct'); end;
  mode=api_core_checkopt(mode,'MODE','definition','initialize','uninitialize');
  varargin(1:2)=[];
end;
caller=api_core_caller;

if strcmp(mode,'definition')
  api_core_checknarg(0,2);
  if isempty(def) def=api_core_defpackage; end;
  if isfield(def,'version')&&(~isempty(def.version))
    if isfield(def.version,'container')&&(~isempty(def.version.container))&&(~strcmp(def.version.container,'framework')) error('PACKAGE_CORE:invalidInput','Invalid package definition structure.'); end;
    if isempty(strfind(caller{1},filesep))&&isfield(def.version,'name')&&(~isempty(def.version.name))&&(~strcmp(caller{1},def.version.name)) error('PACKAGE_CORE:invalidInput','Definition structure of another package.'); end;
  end;
  out=def;
else
  api_core_checknarg(2,2);
  if ~api_core_checkpackage(def) error('PACKAGE_CORE:invalidInput','Invalid package definition structure.'); end;
  if ~strcmp(def.version.container,'framework') error('PACKAGE_CORE:invalidInput','Invalid package definition structure.'); end;
  if ~strcmp(caller{1},def.version.name) error('PACKAGE_CORE:invalidInput','Definition structure of another package.'); end;
  if strcmp(mode,'initialize') out=true;
  elseif strcmp(mode,'uninitialize') out=true;
  end;
end;
