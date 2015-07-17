function out=api_core_checkversion(vtest,varargin)
%API_CORE_CHECKVERSION Check or compare version structure(s).
%   %TODO: Write help text
%          (vtest) if valid version definition
%          (vtest,vref) compare all in vref
%          (vtest,vref,'<lod'>) compare upto detail lod
%          (vtest,'<rcont>') compare upto cont
%          (vtest,'<rcont,'<rname>') compare upto name
%          (vtest,'<rcont,'<rname>',<rmajor>) compare upto major
%          (vtest,'<rcont,'<rname>',<rmajor>,<rminor>) full compare
%          output is bool for validity test
%          output is bool for str and -1,0,1 for num compare
%
%   See also API_CORE_DEFVERSION.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,5);

api_core_checkarg(vtest,'TEST','scalar struct');
res=(numel(fieldnames(vtest))==4)&&all(strcmp(sort(fieldnames(vtest)),sort({'container';'name';'major';'minor'})));
if res [res,err]=api_core_checkarg(vtest.container,'TEST.container','str'); end;
res=logical(res);
if res [res,err]=api_core_checkarg(vtest.name,'TEST.name','str'); end;
res=logical(res);
if res [res,err]=api_core_checkarg(vtest.major,'TEST.major','integer'); end;
res=logical(res);
if res [res,err]=api_core_checkarg(vtest.minor,'TEST.minor','integer'); end;
res=logical(res);
if res res=(~isempty(vtest.container))&&(~isempty(vtest.name))&&((vtest.major+vtest.minor)>=0); end;

if nargin>1
  mode=api_core_checkarg(varargin{1},{'REFERENCE' 'scalar struct';'CONTAINER' 'str'});
  if mode==1
    if nargin==3 lod=api_core_checkopt(varargin{2},'LOD','container','name','major','minor'); else lod='minor'; end;
    vref=varargin{1};
    res=true;
    if res&&isfield(vref,'container')&&api_core_checkarg(vref.container,'REFERENCE.container','str') [res,err]=deal(strcmp(vtest.container,vref.container),'container'); end;
    if res&&isfield(vref,'name')&&api_core_checkarg(vref.name,'REFERENCE.name','str')&&any(strcmp(lod,{'name' 'major' 'minor'})) [res,err]=deal(strcmp(vtest.name,vref.name),'name'); end;
    if res&&isfield(vref,'major')&&api_core_checkarg(vref.major,'REFERENCE.major','integer')&&any(strcmp(lod,{'major' 'minor'})) [res,err]=deal(sign(vtest.major-vref.major),'major'); end;
    if ((islogical(res)&&res)||((~islogical(res))&&(res==0)))&&isfield(vref,'minor')&&api_core_checkarg(vref.minor,'REFERENCE.minor','integer')&&strcmp(lod,'minor') [res,err]=deal(sign(vtest.minor-vref.minor),'minor'); end;
  elseif mode==2
    res=true;
    if res&&api_core_checkarg(varargin{1},'CONTAINER','str') [res,err]=deal(strcmp(vtest.container,varargin{1}),'container'); end;
    if res&&(nargin>2)&&api_core_checkarg(varargin{2},'NAME','str') [res,err]=deal(strcmp(vtest.name,varargin{2}),'name'); end;
    if res&&(nargin>3)&&api_core_checkarg(varargin{3},'MAJOR','integer') [res,err]=deal(sign(vtest.major-varargin{3}),'major'); end;
    if ((islogical(res)&&res)||((~islogical(res))&&(res==0)))&&(nargin>4)&&api_core_checkarg(varargin{4},'MINOR','integer') [res,err]=deal(sign(vtest.minor-varargin{4}),'minor'); end;
  end;
end;

if nargout>0 out=res;
else
  if nargin>1
    if islogical(res)
      if res api_core_l10n('fprintf','Version definitions are identical.\n\n');
      else api_core_l10n('fprintf','Version definitions have different values for field %s.\n\n',err);
      end;
    else
      if res==0 api_core_l10n('fprintf','Version definitions are identical.\n\n');
      elseif res>0 api_core_l10n('fprintf','Version definition has bigger number for field %s.\n\n',err);
      else api_core_l10n('fprintf','Version definition has smaller number for field %s.\n\n',err);
      end;
    end;
  else
    if res api_core_l10n('fprintf','Valid version definition.\n\n');
    else
      api_core_l10n('fprintf','Not a valid version definition.\n');
      if exist('err','var') fprintf('  %s\n\n',err); else fprintf('\n'); end;
    end;
  end;
end;
