function [out,args,mode]=module_core(varargin)
%MODULE_CORE Entry point for a any module.
%   %TODO: Write help text
%
%          For all modules:
%
%          %TODO: definition
%          () same as ('definition')
%          ('definition') same as ([],'definition')
%          (<definition>,'definition') customize given package def struct while
%          it is possible that the given definition is empty and output the
%          fully filled in definition that must validate through
%          api_core_checkmodule
%
%          %TODO: validate
%          (<definition>,'validate',...) validate the given parameters just
%          like LONI Pipeline would, where the parameters can be any
%          combination of one or many strings and actual values as matlab
%          variables
%          %TODO: config
%
%          Additionally for wrap:
%          %TODO: evaluate
%
%          Additionally for visualize:
%          %TODO: evaluate
%
%          Additionally for wizard:
%          %TODO:
%
%          the idea is to serve as a default implementation meaning that any
%          valid module conforming to conventions can forward all calls
%          directly to this function
%          the first output is varied according to the calling '<mode>'
%          the second output is the current calling '<mode>'
%          the fourth output is all remaining arguments
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also API_CORE_DEFMODULE, API_CORE_CHECKMODULE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

persistent validmodes;
if isempty(validmodes)
  validmodes.module={'definition' 'validate' 'config' 'evaluate'};
  validmodes.wrap={};
  validmodes.visualize={};
  validmodes.wizard={};
  fn=fieldnames(validmodes);
  validmodes.all=struct2cell(validmodes);
  validmodes.all=unique(horzcat(validmodes.all{:}));
  for i=1:length(fn) validmodes.(fn{i})=unique(horzcat(validmodes.module,validmodes.(fn{i}))); end;
end;

api_core_checknarg(1,3,0,Inf);
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
  mode=api_core_checkopt(mode,'MODE',validmodes.all);
  varargin(1:2)=[];
end;
caller=api_core_caller;

args=varargin;
if strcmp(mode,'definition')
  api_core_checknarg(0,2);
  if isempty(def) def=api_core_defmodule; end;
  if isfield(def,'version')&&(~isempty(def.version))&&isempty(strfind(caller{1},filesep))
    if isfield(def.version,'container')&&(~isempty(def.version.container))&&(~strcmp(caller{1},def.version.container)) error('MODULE_CORE:invalidInput','Definition structure of another module.'); end;
    if isfield(def.version,'name')&&(~isempty(def.version.name))&&(~isempty(caller{2}))&&(~strcmp(caller{2},def.version.name)) error('MODULE_CORE:invalidInput','Definition structure of another module.'); end;
  end;
  %TODO: If we are called as {'core' 'core'} create the current base version and description
  if isfield(def,'type')&&(~isempty(def.type))
    type=api_core_checkopt(def.type,'DEFINITION.type','module','wrap','visualize','wizard');
    if isempty(def.description) def.description=api_core_l10n([upper(type(1)) type(2:end) ' module.']); end;
  end;
  out=def;
else
  api_core_checknarg(2,Inf);
  if ~api_core_checkmodule(def) error('MODULE_CORE:invalidInput','Invalid module definition structure.'); end;
  if ~all(strcmp(caller,{def.version.container def.version.name})) error('MODULE_CORE:invalidInput','Definition structure of another module.'); end;
  type=api_core_checkopt(def.type,'DEFINITION.type','module','wrap','visualize','wizard');
  api_core_checkopt(mode,'MODE',validmodes.(type));
  if strcmp(mode,'validate')
    [out,args,valid]=api_core_parsecli(def.parameters,args{:});
    if ~valid out=false; end;
  elseif strcmp(mode,'config')
    out=true;
    %TODO: Default implementation for config
  elseif strcmp(mode,'evaluate')
    if (numel(args)==1)&&isstruct(args{1})
      if ~api_core_checkparameter(def.parameters,args{1}) error('MODULE_CORE:invalidInput','Invalid parameter definition structure.'); end;
      args=args{1};
      out=true;
    else
      [out,args,valid]=api_core_parsecli(def.parameters,args{:});
      if ~valid out=false; end;
    end;
    api_core_random(2009);
  end;
  %TODO: Maybe in the future api_core_checknarg for each type.mode case
  if strcmp(type,'module')
    %TODO: Default extensions for modules
  elseif strcmp(type,'wrap')
    %TODO: Default extensions for wraps
  elseif strcmp(type,'visualize')
    %TODO: Default extensions for visualizers
  elseif strcmp(type,'wizard');
    %TODO: Default extensions for wizards
  end;
end;
