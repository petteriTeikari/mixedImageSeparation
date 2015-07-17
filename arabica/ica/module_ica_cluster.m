function [out,args]=module_ica_cluster(varargin)
%MODULE_ICA_PCA Perform Principal Component Analysis.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_ICA_ICA, API_CORE_DEFMODULE, MODULE_CORE.

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
    %TODO: Maybe in the future include some metadata in temp.xxx
    %TODO: More checking and security here
    i=2;
    if (i<numel(args))&&api_core_checkparameter(args(i),'var')
      vn=regexp(args(i).value,'^\s*(?<name>\S+)\s*=\s*(?<dim>\d+)\s*$','names');
      if numel(vn)==1
        dim=str2double(vn.dim);
        vn=vn.name;
      else vn=args(i).value;
      end;
      i=i+1;
    else vn='';
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'th')
      th=args(i).value;
      i=i+1;
    else th=0.85;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'path')
      p=args(i).value;
      i=i+1;
    else p=4;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'rank')
      r=args(i).value;
      i=i+1;
    else r='';
    end;
    if isempty(vn)
      fn=args(1).value{1};
      try vn=whos('-file',fn);
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn),err);
      end;
      if isempty(vn) api_core_error(api_core_l10n('sprintf','Cannot find variables in file "%s"!',fn));
      else
        for j=numel(vn):-1:1
          if ~any(strcmp(vn(j).class,{'double' 'logical' 'single' 'int8' 'uint8' 'int16' 'uint16' 'int32' 'uint32' 'int64' 'uint64'})) vn(j)=[];
          elseif (numel(vn(j).size)~=2)||(vn(j).size(1)>=vn(j).size(2)) vn(j)=[];
          end;
        end;
        if numel(vn)==1 vn=vn.name;
        elseif any(strcmpi('X',{vn(:).name}))
          vn={vn(strcmpi('X',{vn(:).name})).name};
          if numel(vn)==1 vn=vn{1};
          else
            vn=vn{strcmp('X',vn)};
            if isempty(vn) vn='x'; end;
          end;
        else api_core_error(api_core_l10n('sprintf','Cannot find a suitable variable in file "%s"!',fn));
        end;
      end;
    end;
    fn=args(1).value;
    for i=1:numel(fn)
      try tempin=load(fn{i},vn);
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn{i}),err);
      end;
      if exist('temp','var')
        if ~exist('dim','var')
          if ndims(tempin.(vn))==2 dim=find(size(tempin.(vn))>1,1); else dim=[]; end;
          if isempty(dim)
            [nil,dim]=sort(size(tempin.(vn)));
            dim=dim(1);
          end;
        end;
        temp.X=cat(dim,temp.X,tempin.(vn));
      else temp.X=tempin.(vn);
      end;
      clear tempin;
    end;
    [temp.R,temp.block]=api_ica_similarity(temp.X,'variance','correlation');
    temp.L=api_ica_linkage(temp.R,'inversescore',th,p);
    [temp.cluster,temp.rank]=api_ica_quickcluster(temp.L,temp.R,temp.block);
    if isempty(r) temp.rank=api_ica_rank(temp.cluster,temp.R,1);
    else temp.rank=api_ica_rank(temp.cluster,api_ica_similarity(temp.X,'variance',r),1);
    end;
    try save(args(end).value,'-struct','temp','R','block','L','cluster','rank');
    catch err
      api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',args(end).value),err);
    end;
    out=true;
  end;
end;
