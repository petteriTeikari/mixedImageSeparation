function out=arabica_init(handler)
%ARABICA_INIT Initialize Arabica framework.
%   ARABICA_INIT Initializes the Arabica framework with all installed
%   packages and modules. The framework remains persistent in memory after
%   this. Interactive progress is shown on the command-line.
%
%   ARABICA_INIT(HANDLER) uses the given progress handler definition
%   instead of the default. HANDLER can be any build-in name or a structure
%   accepted by API_CORE_PROGRESS.
%
%   SUCCESS=ARABICA_INIT(...) returns a logical value indicating wheather
%   the initialization was successful or not.
%
%   NOTE: All Arabica functions meant to be called by a human automatically
%   perform initialization, there should never be a need to explicitly call
%   ARABICA_INIT.
%
%   See also ARABICA, ARABICA_CONFIGLOAD, API_CORE_PROGRESS.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

try
  if api_core_persistent('status')&&(~isempty(api_core_persistent('get','arabica.initialized')))
    out=true;
    return;
  end;
catch err
  if exist(which('api_core_persistent'),'file') rethrow(err); end;
end;

conf=arabica_configload;

dirs={};
temp=conf.arabica.packagepaths;
while ~isempty(temp)
  dirs{end+1}=temp{1};
  d=dir(temp{1});
  dd={d([d.isdir]).name};
  dd(strmatch('.',dd))=[];
  if isempty(dd) temp(1)=[];
  else temp=horzcat(temp(2:end),strcat(fullfile(temp{1},filesep,''),dd));
  end;
end;

corepath=fileparts(which('package_core'));
if isempty(corepath) corepath=fileparts(which('api_core_init')); end;
if isempty(corepath)
  for i=1:length(dirs)
    if exist(fullfile(dirs{i},'api_core_init.m'),'file')
      corepath=dirs{i};
      break;
    end;
  end;
  if isempty(corepath)
    d='';
    if desktop('-inuse') d=uigetdir('','Select the directory of the Core API package'); end;
    if ischar(d)&&exist(fullfile(d,'api_core_init.m'),'file') corepath=d;
    else
      error('ARABICA:invalidInstall','Cannot initialize Arabica framework since the API package (core) cannot be found.');
      %TODO: Maybe in the future better error messages and help
    end;
  end;
  addpath(corepath,'-end');
end;

pkgs={};
for i=1:length(dirs)
  if api_core_ispackage(dirs{i}) pkgs{end+1}=dirs{i}; end;
end;

pid=api_core_progress('arabica','new');
if ~exist('handler','var') handler='cli'; end;
api_core_progress('addhandler',handler);
api_core_persistent('set','arabica.config',conf);
try
  tinit=api_core_init('initialize',pkgs{:});
  pathname=fileparts(mfilename('fullpath'));
  def=api_core_parsecontents(api_core_l10n('file',fullfile(pathname,'Contents.m')),api_core_defpackage);
  def.entry=@arabica_init;
  api_core_persistent('set','arabica.definition',def);
  pkgs=api_core_persistent('get','packages');
  if isempty(pkgs) [tdef,ldef]=deal(false,[]);
  else [tdef,ldef]=api_core_checkpackage(pkgs,def);
  end;
catch err
  api_core_error(err);
  [tdef,ldef]=deal(false,[]);
end;
if tdef
  api_core_persistent('set','arabica.initialized',true);
  api_core_persistent('set','arabica.initlog',[]);
  if isfield(conf,'core')&&isfield(conf.core,'libraries')
    for i=1:numel(conf.core.libraries) lib=api_core_library('add',conf.core.libraries(i)); end;
  end;
else
  if ~isempty(ldef)
    %TODO: Maybe in the future better error messages and help based on ldef
    api_core_error(api_core_l10n('Cannot initialize Arabica framework due to version mismatches!'));
  else api_core_error(api_core_l10n('Cannot initialize Arabica framework!'));
  end;
end;
if (~tdef)||(~tinit) api_core_persistent('set','arabica.initlog',api_core_progress(pid,'log')); end;
api_core_progress('complete');
api_core_progress(pid,'destroy');
if nargout>0 out=tdef; end;
