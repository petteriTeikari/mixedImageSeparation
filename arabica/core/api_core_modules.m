function [outm,outp]=api_core_modules(varargin)
%API_CORE_MODULES Get definitions of initialized modules.
%   %TODO: Write help text
%          () return all modules
%          ('<filter>',value,...) return modules that match the one or
%          many filters, valid value depends on the filter
%
%          supported filters are:
%          'type',value = match one 'value' or many {'value'...} types of
%          modules, where valid values are 'module','wrap','visualize' and
%          'wizard'
%          'package',value = match only modules in the named package
%          'value' or packages {'value'...}
%          'name',value = match only modules with the given name 'value' or
%          names {'value'...}
%          'tag',value = match only modules with the tag 'value' or one of
%          the tags {'value'...}
%
%          different filter,value pairs are combined with and operator,
%          whereas many values in one filter are combined with or, giving
%          a very natural usage
%
%          [MODULES, PACKAGES]= outputs also the packages that the returned
%          modules belong to
%
%
%   See also API_CORE_DEFMODULE, API_CORE_DEFPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,2,0,Inf);
filter=struct('type',{},'value',{});
if isempty(varargin)
  filter(1).type='type';
  filter(1).value={'module' 'wrap' 'visualize' 'wizard'};
else
  while ~isempty(varargin)
    filter(end+1).type=api_core_checkopt(varargin{1},'FILTER','type','package','name','tag');
    if length(varargin)<2 error('API_CORE_MODULES:invalidInput',sprintf('Filter "%s" must have an associated value pair.',ftype)); end;
    api_core_checkarg(varargin{2},'VALUE','str');
    if ischar(varargin{2}) filter(end).value={varargin{2}}; else filter(end).value=varargin{2}(:).'; end;
    varargin(1:2)=[];
  end;
end;

%TODO: Maybe in the future optimize with an answer cache of recent or frequent filters

mods=api_core_defmodule;
mods(1)=[];
api_core_persistent('lock');
pkgs=api_core_persistent('get','packages');
if isempty(pkgs)
  pkgs=api_core_defpackage;
  pkgs(1)=[];
  modsi=[];
else
  %pkgsn=horzcat(pkgs(:).version);
  %pkgsn={pkgsn(:).name};
  mods=horzcat(pkgs(:).modules);
  modfs={mods.entry};
  modsi=[];
  for i=1:numel(pkgs) modsi=[modsi repmat(i,1,numel(pkgs(i).modules))]; end;
  corei=cellfun(@(f)isequal(f,@module_core),modfs);
  mods(corei)=[];
  modsi(corei)=[];
end;

for i=1:numel(filter)
  for j=numel(mods):-1:1
    fm=false;
    %TODO: Maybe in the future allow wildcards or regexps in filters
    if strcmp(filter(i).type,'type')
      if ~any(strcmpi(mods(j).type,filter(i).value)) fm=true; end;
    elseif strcmp(filter(i).type,'package')
      if ~any(strcmpi(mods(j).version.container,filter(i).value)) fm=true; end;
    elseif strcmp(filter(i).type,'name')
      if ~any(strcmpi(mods(j).version.name,filter(i).value)) fm=true; end;
    elseif strcmp(filter(i).type,'tag')
      [nil,mi]=intersect(lower(mods(j).tags),lower(filter(i).value));
      if isempty(mi) fm=true; end;
    end;
    if fm
      mods(j)=[];
      modsi(j)=[];
    end;
  end;
end;

if nargout>0
  outm=mods;
  if nargout>1
    if isempty(mods) i=[]; else i=unique(modsi); end;
    outp=pkgs(i);
  end;
else
  fprintf('Matched %i modules:\n\n',numel(mods));
  for i=1:length(mods)
    fprintf('  %s/%s\n',mods(i).version.container,mods(i).version.name);
  end;
  if ~isempty(mods) fprintf('\n'); end;
end;
