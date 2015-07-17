function out=package_ica(varargin)
%PACKAGE_ICA Entry point for ICA package.
%   %TODO: Write help text
%          (<definition>,'definition') customize given package def struct and it
%          is possible that the given definition is empty
%          (<definition>,'initialize') initialize package
%          (<definition>,'uninitialize') uninitialize package
%
%          package entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also API_CORE_DEFPACKAGE, API_CORE_DEFMODULE, PACKAGE_CORE.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

[out,mode]=package_core(varargin{:});

if strcmp(mode,'initialize')
  if ~api_core_checksubpackage('fpica','fastica','FastICA') api_core_warning(api_core_l10n('sprintf','Some modules may fail since cannot locate the FastICA package!')); end;
end;
