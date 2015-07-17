function [out,args]=module_core_mixture(varargin)
%MODULE_CORE_MIXTURE Perform a linear mixing of data matrices.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_CORE_GENERATE, API_CORE_DEFMODULE, MODULE_CORE.

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
    if (i<numel(args))&&api_core_checkparameter(args(i),'mixing')
      m=args(i).value;
      i=i+1;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'dim')
      dim=args(i).value;
      i=i+1;
    else dim=NaN;
    end;
    if (i<numel(args))&&api_core_checkparameter(args(i),'noise')
      an=args(i).value;
      i=i+1;
    else an=0;
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'out')
      fnx=args(i).value;
      i=i+1;
    else fnx='';
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'orig')
      fns=args(i).value;
      i=i+1;
    else fns='';
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'outa')
      fna=args(i).value;
      i=i+1;
    else fna='';
    end;
    fn=args(1).value;
    fnv=cell(1,numel(fn));
    s=0;
    for i=1:numel(fn)
      try vn=whos('-file',fn{i});
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn{i}),err);
      end;
      if isempty(vn) api_core_error(api_core_l10n('sprintf','Cannot find variables in file "%s"!',fn{i}));
      else
        for j=numel(vn):-1:1
          if ~any(strcmp(vn(j).class,{'double' 'logical' 'single' 'int8' 'uint8' 'int16' 'uint16' 'int32' 'uint32' 'int64' 'uint64'})) vn(j)=[];
          elseif (i>1)&&((numel(vn(j).size)>2)||(vn(j).size(2)~=s)) vn(j)=[];
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
      s=vn(k).size(2);
    end;
    temp.X=[];
    for i=1:numel(fn)
      try tempin=load(fn{i},fnv{i});
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot load file "%s"!',fn{i}),err);
      end;
      temp.X=[temp.X;tempin.(fnv{i})];
      clear tempin;
    end;
    if ~isempty(fns)
      tempout.S=temp.X;
      try save(fns,'-struct','tempout');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fns),err);
      end;
      clear tempout;
    end;
    if isnan(dim) dim=size(temp.X,1); end;
    seed=api_core_random(fnx);
    api_core_random(seed);
    if strcmp(m,'permute')
      %TODO: temp.A=;
    elseif strcmp(m,'permute-n')
      %TODO: temp.A=;
    elseif strcmp(m,'permute-p')
      %TODO: temp.A=;
    elseif strcmp(m,'uniform') temp.A=2*rand(dim,size(temp.X,1))-1;
    elseif strcmp(m,'uniform-n') temp.A=rand(dim,size(temp.X,1));
    elseif strcmp(m,'uniform-p') temp.A=1-rand(dim,size(temp.X,1));
    end;
    if ~isempty(fna)
      try save(fna,'-struct','temp','A');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fna),err);
      end;
    end;
    temp.X=temp.A*temp.X;
    if an>0
      for i=1:dim
        api_core_random(seed+i);
        temp.X(i,:)=temp.X(i,:)+an.*randn(1,size(temp.X,2));
      end;
    end;
    if ~isempty(fnx)
      try save(fnx,'-struct','temp','X');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',fnx),err);
      end;
    end;
    out=true;
  end;
end;
