function [out,args,valid]=api_core_parsecli(params,varargin)
%API_CORE_PARSECLI Parse and check validity of command-line arguments.
%   %TODO: Write help text
%          (parameters,...) parse and check all arguments
%          [out,args,valid] outputs
%
%   See also API_CORE_CHECKPARAMETER.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,3,1,Inf);
for i=1:numel(params)
  if ~api_core_checkparameter(params(i)) error('API_CORE_PARSECLI:invalidInput','Input argument PARAMETERS must be valid parameter definitions.'); end;
end;

out=api_core_defparameter;
out.value={};
out(1)=[];
args=varargin;

%TODO: Maybe in the future support a single string that is split with whitespaces like a real command-line

rc=zeros(1,numel(params));
r=0;
i=1;
while (i<=numel(params))&&(~isempty(args))
  t=args{1};
  if (ischar(t)&&(size(t,1)==1))||(iscellstr(t)&&(numel(t)==1))
    t=char(t);
    if params(i).switch(end)==' ' m=strcmp(params(i).switch(1:end-1),t); else m=strcmp(params(i).switch,t(1:length(params(i).switch))); end;
    if m
      if params(i).switch(end)==' ' args(1)=[]; else args=horzcat({t((length(params(i).switch)+1):end)},args{2:end}); end;
      tp=params(i);
      tp.value={};
      out(end+1)=tp;
      if ~isnan(params(i).cardinalitybase)
        k=find(strcmp(params(params(i).cardinalitybase).name,{out(:).name}),1,'last');
        if isempty(k) api_core_error(api_core_l10n('sprintf','Missing cardinality base for %s!',params(i).name)); end;
        out(end).cardinalitybase=k;
      end;
      if ~isnan(params(i).transformbase)
        k=find(strcmp(params(params(i).transformbase).name,{out(:).name}),1,'last');
        if isempty(k) api_core_error(api_core_l10n('sprintf','Missing transform base for %s!',params(i).name)); end;
        out(end).transformbase=k;
      end;
      for k=1:numel(params(i).depend)
        l=find(strcmp(params(params(i).depend(k)).name,{out(:).name}),1,'last');
        if isempty(l) api_core_error(api_core_l10n('sprintf','Missing dependency for %s!',params(i).name)); end;
        out(end).depend(k)=l;
      end;
      out(end).recurrence=0;
      out(end).recurrencebase=NaN;
      if out(end).cardinality~=0
        if out(end).cardinality==-2
          j=out(end).cardinalitybase;
          if ischar(out(j).value) vc=size(out(j).value,1); else vc=numel(out(j).value); end;
        elseif out(end).cardinality==-1 vc=Inf;
        else vc=out(end).cardinality;
        end;
        j=0;
        while (j<vc)&&(~isempty(args))
          v=args{1};
          if isstruct(v) error('API_CORE_PARSECLI:invalidInput','Input argument ARGUMENTS must be numeric, string arrays or cell arrays.'); end;
          if ischar(v)
            v=regexp(v,'^''?(.*?)''?$','tokens');
            if ~isempty(v) v=horzcat(v{:}); end;
          end;
          if iscellstr(v)&&(numel(v)==1)
            if isinf(vc)
              vm=false;
              for k=(i+1):numel(params)
                if params(k).switch(end)==' ' vm=strcmp(params(k).switch(1:end-1),v{1}); else vm=strcmp(params(k).switch,v{1}(1:length(params(k).switch))); end;
                if vm||params(k).required break; end;
              end;
              if (~vm)&&(params(i).recurrence~=0)
                vr=params(i).recurrencebase;
                if params(vr).switch(end)==' ' vm=strcmp(params(vr).switch(1:end-1),v{1}); else vm=strcmp(params(vr).switch,v{1}(1:length(params(vr).switch))); end;
              end;
              if vm break; end;
            end;
          end;
          vm=false;
          if isempty(params(i).format)||strcmp(params(i).format,'string')
            vm=iscellstr(v);
            if vm
              out(end).value=horzcat(out(end).value,v);
              j=j+numel(v);
            else api_core_error(api_core_l10n('sprintf','Illegal value for String %s!',params(i).name),v);
            end;
          elseif strcmp(params(i).format,'file')
            vm=iscellstr(v)&&api_core_checkfiletype(params(i).filetype,v);
            if vm
              out(end).value=horzcat(out(end).value,v);
              j=j+numel(v);
            else api_core_error(api_core_l10n('sprintf','Illegal value for File %s!',params(i).name),v);
            end;
          elseif strcmp(params(i).format,'directory')
            vm=iscellstr(v);
            if vm
              for k=1:numel(v)
                %TODO: Maybe in the future check that the directory paths are atleast syntactically valid
                if exist(fullfile(v{k}),'file')
                  if ~exist(fullfile(v{k}),'dir')
                    vm=false;
                    break;
                  end;
                end;
              end;
            end;
            if vm
              out(end).value=horzcat(out(end).value,v);
              j=j+numel(v);
            else api_core_error(api_core_l10n('sprintf','Illegal value for Directory %s!',params(i).name),v);
            end;
          elseif strcmp(params(i).format,'number')
            vm=isnumeric(v);
            if ~vm
              %TODO: Maybe in the future more careful checks and security here
              vm=true;
              try v=str2num(char(v)); catch vm=false; end;
            end;
            if vm
              if isempty(out(end).value) out(end).value=v(:).';
              else out(end).value=[out(end).value v(:).'];
              end;
              j=j+numel(v);
            else api_core_error(api_core_l10n('sprintf','Illegal value for Number %s!',params(i).name),v);
            end;
          elseif strcmp(params(i).format,'enumerated')
            vm=iscellstr(v)&&(numel(v)==1);
            if vm
              k=strcmp(params(i).enumeration,v{1});
              vm=(sum(k)==1);
            end;
            if vm
              out(end).value=params(i).enumeration{k};
              j=j+1;
            else api_core_error(api_core_l10n('sprintf','Illegal value for Enumeration %s!',params(i).name),v);
            end;
          end;
          args(1)=[];
        end;
        if j>vc api_core_error(api_core_l10n('sprintf','Too many values (%i) for parameter %s that needs %i!',j,params(i).name,vc)); end;
        if (out(end).cardinality==1)&&(iscell(out(end).value)) out(end).value=out(end).value{1};
        elseif ((out(end).cardinality<0)||(out(end).cardinality>1))&&(~iscell(out(end).value)) out(end).value={out(end).value};
        end
      end;
    elseif r>0
      if params(r).switch(end)==' ' m=strcmp(params(r).switch(1:end-1),t); else m=strcmp(params(r).switch,t(1:length(params(r).switch))); end;
      if m
        if params(i).recurrence==-2
          %TODO: Is N recurrence even possible and what to do here
          error('Unimplemented recurrence with N!'); %DEBUG
        end;
        rc(i)=rc(i)+1;
        if (params(i).recurrence>0)&&(rc(i)>params(i).recurrence) api_core_error(api_core_l10n('sprintf','Parameter %s reoccurring too many times!',params(i).name),t); end;
        rc(r:(i-1))=0;
        i=r;
        r=0;
        continue;
      end;
    end;
    if (~m)&&params(i).required api_core_error(api_core_l10n('sprintf','Required %s parameter %s missing!',params(i).type,params(i).name),t); end;
    if params(i).recurrence~=0 r=params(i).recurrencebase; end;
  else api_core_error(api_core_l10n('sprintf','Invalid command-line switch!'),t);
  end;
  i=i+1;
end;
valid=isstruct(out);
