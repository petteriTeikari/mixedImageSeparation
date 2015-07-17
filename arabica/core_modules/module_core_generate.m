function [out,args]=module_core_generate(varargin)
%MODULE_CORE_GENERATE Generator for various test signals.
%   %TODO: Write help text
%          (<definition>,'definition') customize given module def struct and it
%          is possible that the given definition is empty
%
%          module entry point always does exactly as its told to do hence the
%          responsibility to ask only on correct times lies with the caller
%
%   See also MODULE_CORE_MIXTURE, API_CORE_DEFMODULE, MODULE_CORE.

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
    temp.X=[];
    %TODO: More checking and security here
    samples=args(1).value;
    i=2;
    while (i<numel(args))&&api_core_checkparameter(args(i),'signals')
      dim=args(i).value;
      x=zeros(dim,samples);
      i=i+1;
      if (i<numel(args))&&api_core_checkparameter(args(i),'type')
        t=args(i).value;
        i=i+1;
      else t='random';
      end;
      if (i<numel(args))&&api_core_checkparameter(args(i),'rate')
        f=args(i).value;
        i=i+1;
      else f=0;
      end;
      if (i<numel(args))&&api_core_checkparameter(args(i),'phase')
        p=2*pi*args(i).value;
        i=i+1;
      else p=0;
      end;
      seed=api_core_random(args(end).value);
      api_core_random(seed);
      if strcmp(t,'random')
        tt={'sinusoid' 'sawtooth' 'square'};
        if exist('randi','builtin') t=tt(randi(numel(tt),1,dim)); else t=tt(fix(1+numel(tt).*rand(1,dim))); end;
      elseif strcmp(t,'noise')
        tt={'uniform' 'gaussian' 'impulse'};
        if exist('randi','builtin') t=tt(randi(numel(tt),1,dim)); else t=tt(fix(1+numel(tt).*rand(1,dim))); end;
      else t=cellstr(t);
      end;
      if f==0 f=20+180.*rand(1,dim); end;
      if p==0 p=2*pi.*rand(1,dim); end;
      for j=0:(dim-1)
        api_core_random(seed+j+1);
        tt=t{1+mod(j,numel(t))};
        tf=f(1+mod(j,numel(f)));
        tp=p(1+mod(j,numel(p)));
        if strcmp(tt,'sinusoid')
          x(j+1,:)=sin(tp+linspace(0,2*pi*samples/tf,samples));
        elseif strcmp(tt,'sawtooth')
          x(j+1,:)=sawtooth(tp+linspace(0,2*pi*samples/tf,samples));
        elseif strcmp(tt,'square')
          x(j+1,:)=square(tp+linspace(0,2*pi*samples/tf,samples));
        elseif strcmp(tt,'uniform') x(j+1,:)=2.*rand(1,samples)-1;
        elseif strcmp(tt,'gaussian') x(j+1,:)=randn(1,samples);
        elseif strcmp(tt,'impulse')
          %TODO: This is not a very stable way to normalize
          x(j+1,:)=(2*(rand(1,samples)<.5)-1).*log(rand(1,samples));
          x(j+1,:)=2*(x(j+1,:)-min(x(j+1,:)))./(max(x(j+1,:))-min(x(j+1,:)))-1;
        end;
      end;
      if (i<numel(args))&&api_core_checkparameter(args(i),'power')
        x=x.^args(i).value;
        i=i+1;
      end;
      if (i<numel(args))&&api_core_checkparameter(args(i),'scale')
        x=x.*args(i).value;
        i=i+1;
      end;
      if (i<numel(args))&&api_core_checkparameter(args(i),'shift')
        x=x+args(i).value;
        i=i+1;
      end;
      temp.X=[temp.X;x];
      seed=seed+1000;
    end;
    if (i<=numel(args))&&api_core_checkparameter(args(i),'out')
      try save(args(i).value,'-struct','temp');
      catch err
        api_core_error(api_core_l10n('sprintf','Cannot save file "%s"!',args(i).value),err);
      end;
    end;
    out=true;
  end;
end;
