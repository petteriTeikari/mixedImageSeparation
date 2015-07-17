function [out,args]=module_ica_combine(varargin)
%MODULE_ICA_COMBINE Combine multiple data matrices.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_ICA_UNCOMBINE, MODULE_ICA_ICA, MODULE_ICA_PCA,
%   API_CORE_DEFMODULE, MODULE_CORE.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

[out,args,mode]=module_core(varargin{:});

if strcmp(mode,'validate')
  %TODO: More checking and security here
elseif strcmp(mode,'config')
  %TODO: Default implementation for config
elseif strcmp(mode,'evaluate')
  if out
    out=false;
    %TODO: More checking and security here
    i=2;
    if (i<numel(args))&&api_core_checkparameter(args(i),'name')
      n=args(i).value;
      i=i+1;
    else n='none';
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'mode')
      m=args(i).value;
      i=i+1;
    else m='none';
    end;
    if strcmp(m,'symmetric') symm={'symmetric'}; else symm={}; end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'cat')
      if strcmp(args(i).value,'dimensions') c=1;
      elseif strcmp(args(i).value,'samples') c=2;
      end;
      i=i+1;
    else c=1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'dim')
      dim=args(i).value;
      i=i+1;
    else dim=Inf;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'var')
      pow=args(i).value;
      i=i+1;
    else pow=1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'meta')
      fnm=args(i).value;
      i=i+1;
    else fnm='';
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'out')
      fno=args(i).value;
      i=i+1;
    else fno='';
    end;
    tempout.combine=struct('name',n,'mode',m,'dimension',c,'sub',{{}},'cM',{{}},'ucM',{{}},'m',{{}});
    fn=args(1).value;
    fnv=cell(1,numel(fn));
    s=[];
    for i=1:numel(fn)
      try vn=whos('-file',fn{i});
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn{i}),err);
      end;
      if isempty(vn) api_core_error(api_core_l10n('sprintf','Cannot find variables in file "%s"!',fn{i}));
      else
        for j=numel(vn):-1:1
          if ~any(strcmp(vn(j).class,{'double' 'logical' 'single' 'int8' 'uint8' 'int16' 'uint16' 'int32' 'uint32' 'int64' 'uint64'})) vn(j)=[];
          elseif (i>1)&&(~isequal(s(setdiff(1:numel(s),c)),vn(j).size(setdiff(1:numel(vn(j).size),c)))) vn(j)=[];
          end;
        end;
        if numel(vn)==1 k=1;
        elseif any(strcmpi('X',{vn(:).name}))
          k=[find(strcmp('X',{vn(:).name})) find(strcmp('x',{vn(:).name}))];
          if numel(k)>1 k=k(1); end;
        else api_core_error(api_core_l10n('sprintf','Cannot find a suitable variable in file "%s"!',fn{i}));
        end;
      end;
      fnv{i}=vn(k).name;
      s=vn(k).size;
    end;
    if ~strcmp(m,'none')
      for i=1:numel(fn)
        try tempin=load(fn{i},fnv{i});
        catch err
          api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn{i}),err);
        end;
        if c==1 [tempin.(fnv{i}),temp(i).m]=api_ica_normalize(tempin.(fnv{i}),'mean');
        elseif c==2 [tempin.(fnv{i}),temp(i).m]=api_ica_normalize(tempin.(fnv{i}).','mean');
        end;
        [temp(i).d,temp(i).E]=api_ica_pca(tempin.(fnv{i}));
        clear tempin;
        sd=cumsum(temp(i).d);
        sd=sd./sd(end);
        dimpow=find(sd>=min(1,pow),1,'first');
        temp(i).dim=min(dim,dimpow);
      end;
    end;
    for i=1:numel(fn)
      try
        ws=warning('off','MATLAB:load:variableNotFound');
        tempin=load(fn{i},fnv{i},'combine');
        warning(ws);
      catch err
        warning(ws);
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn{i}),err);
      end;
      if ~strcmp(m,'none')
        if c==1 tempin.(fnv{i})=api_ica_normalize(tempin.(fnv{i}),'mean');
        elseif c==2 tempin.(fnv{i})=api_ica_normalize(tempin.(fnv{i}).','mean');
        end;
        [tempout.combine.cM{i},tempout.combine.ucM{i},tempin.(fnv{i})]=api_ica_whiten(temp(i).d,temp(i).E,tempin.(fnv{i}),temp(i).dim,symm{:});
        tempout.combine.m{i}=temp(i).m;
        if c==2 tempin.(fnv{i})=tempin.(fnv{i}).'; end;
      end;
      if i>1 tempout.X=cat(c,tempout.X,tempin.(fnv{i})); else tempout.X=tempin.(fnv{i}); end;
      if isfield(tempin,'combine') tempout.combine.sub{i}=tempin.combine; else tempout.combine.sub{i}=[]; end;
      clear tempin;
    end;
    if ~isempty(fnm)
      try save(fnm,'-struct','tempout','combine');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fnm),err);
      end;
    end;
    try save(fno,'-struct','tempout');
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fno),err);
    end;
    out=true;
  end;
end;
