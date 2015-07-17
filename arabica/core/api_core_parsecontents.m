function out=api_core_parsecontents(filepath,def)
%API_CORE_PARSECONTENTS Parse an extended Matlab Contents.m file.
%   %TODO: Write help text
%          ('<path>') def ready filled in using file contents
%          ('<path>',<def>) given def appended using file contents
%
%          the Contents.m file is parsed to identify lines following Matlab and
%          package convention to fill in more details
%
%          the difference to api_core_defpackage is that the output is not
%          guaranteed to be a valid package definition structure but only
%          contains or is appended with the found details
%
%   See also API_CORE_PARSEDIR, API_CORE_ISPACKAGE, API_CORE_DEFPACKAGE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,2);
api_core_checkarg(filepath,'FILE','str');
if ~exist(filepath,'file') error('API_CORE_PARSECONTENTS:invalidInput','Path must point to an existing file.'); end;
if exist('def','var')&&api_core_checkarg(def,'BASE','struct') out=def; else out=struct([]); end;

temp={};
fid=fopen(filepath,'r');
if fid~=-1
  temp=textscan(fid,'%s','Delimiter','');
  fclose(fid);
end;
if ~isempty(temp)
  temp=temp{1};
  i=find(~(strmatch('%',temp)),1);
  if ~isempty(i) temp(i:end)=[]; end;
  if ~isempty(temp)
    temp=regexprep(temp,'^% ?','');
    hend=find(strcmp(strtrim(temp),''),1);
    if isempty(hend)
      hend=length(temp);
      cstart=1;
    else
      hend=max(1,hend-1);
      cstart=min(length(temp),hend+1);
    end;
    t=regexp(temp{1},'^\s*(?<description>.+\S)\s*\(\s*\w+\s*\)\s*$','names');
    if numel(t)==1 out(1).description=t.description; else out(1).description=strtrim(temp{1}); end;
    out(1).name=out(1).description;
    t=regexp(temp{1},'^.+\(\s*(?<name>\w+)\s*\)\s*$','names');
    if numel(t)==1
      out(1).version.container='framework';
      out(1).version.name=lower(t.name);
      out(1).path=fileparts(filepath);
    end;
    t=regexp(temp{2},'^Version\s+(?<major>\d+)\.(?<minor>\d+)(\s*$|\s+)(?<date>\S+)\s*$','names');
    if numel(t)==1
      out(1).version.major=str2double(t.major);
      out(1).version.minor=str2double(t.minor);
    end;
    t=regexp(temp(3:hend),'^Requires\s+((\s*\S+)*)\s*$','tokens');
    t=vertcat(t{:});
    if isempty(t) t={''}; elseif iscell(t{1}) t=vertcat(t{:}); end;
    tt=regexp(t,'(^|,)\s*(?<name>\w+)\s+(?<major>\d+)\.(?<minor>\d+)\s*(,|$)','names');
    tt=horzcat(tt{:});
    if ~isempty(tt)
      out(1).requires=api_core_defversion;
      out(1).requires(1)=[];
    end;
    for i=1:length(tt)
      out(1).requires(end+1)=api_core_defversion('framework',lower(tt(i).name),str2double(tt(i).major),str2double(tt(i).minor));
    end;
    t=regexp(temp(3:hend),'^Suggests\s+((\s*\S+)*)\s*$','tokens');
    t=vertcat(t{:});
    if isempty(t) t={''}; elseif iscell(t{1}) t=vertcat(t{:}); end;
    tt=regexp(t,',?\s*(?<name>\w+)\s+(?<major>\d+)\.(?<minor>\d+)\s*,?','names');
    tt=horzcat(tt{:});
    if (~isempty(tt))&&(~isfield(out(1),'suggests'))
      out(1).suggests=api_core_defversion;
      out(1).suggests(1)=[];
    end;
    for i=1:length(tt)
      out(1).suggests(end+1)=api_core_defversion('framework',lower(tt(i).name),str2double(tt(i).major),str2double(tt(i).minor));
    end;
    tt=regexp(t,',?\s*(?<name>\w+)\s*,?','names');
    tt=horzcat(tt{:});
    if (~isempty(tt))&&(~isfield(out(1),'suggests'))
      out(1).suggests=api_core_defversion;
      out(1).suggests(1)=[];
    end;
    for i=1:length(tt)
      out(1).suggests(end+1)=api_core_defversion('framework',lower(tt(i).name));
    end;
    t=regexp(temp(3:hend),'^HomeUrl\s+(.+)$','tokens');
    t=vertcat(t{:});
    if (~isempty(t))&&iscell(t{1}) t=vertcat(t{:}); end;
    if ~isempty(t) out(1).homeurl=char(t); end;
    t=regexp(temp(3:hend),'^UpdateUrl\s+(.+)$','tokens');
    t=vertcat(t{:});
    if (~isempty(t))&&iscell(t{1}) t=vertcat(t{:}); end;
    if ~isempty(t) out(1).updateurl=char(t); end;
    cend=find(cellfun(@numel,regexp(temp(cstart:end),'^\s*\w+\s*-')),1);
    if isempty(cend)
      cend=length(temp);
    else
      cend=cend+cstart-1;
      cend2=find(strcmp(strtrim(temp(cstart:cend)),''),1,'last');
      if isempty(cend2) cend=cend-2; else cend=cend2+cstart-2; end;
    end;
    if cend>=cstart
      t=temp(cstart:cend);
      i=find(cellfun(@numel,regexp(t,'\S+')));
      t=t(i(1):i(end));
      tt=regexp(t,'(^\s*)\S+','tokens');
      tt=vertcat(tt{:});
      if isempty(tt) tt={''};
      elseif iscell(tt{1}) tt=vertcat(tt{:});
      end;
      l=Inf;
      if isempty(tt) l=0;
      elseif ischar(tt) tt={tt}; end;
      for i=1:length(tt) l=min(l,length(tt{i})); end;
      for i=1:length(t)
        if length(t{i})>(1+l) t{i}=t{i}((1+l):end); end;
      end;
      if ~isempty(t)
        out(1).description=t{1};
        if length(t)>1 out(1).description=[out(1).description sprintf('\n%s',t{2:end})]; end;
      end;
    else cend=max(cstart,cend);
    end;
    if cend<length(temp)
      t=strtrim(temp((cend+1):end));
      cpart=[1;find(strcmp(t,''));length(t)];
      for i=1:(length(cpart)-1)
        tt=regexp(t(cpart(i):cpart(i+1)),'^\s*(?<name>\w+)\s*-\s*(?<description>.*)','names');
        tt=horzcat(tt{:});
        if ~isempty(tt)
          for j=1:length(tt)
            fns={};
            mname=regexp(tt(j).name,'^(package|module|wrap|visualize|template|wizard|api)_(.+)','tokens');
            mname=vertcat(mname{:});
            if numel(mname)==2
              fns={mname{1} mname{2} [mname{1} '_' mname{2}] tt(j).description};
            else
              mname=regexpi(tt(j).description,'(?:entry|function).*(package|module|wrap|visualize|template|wizard|api)|(package|module|wrap|visualize|template|wizard|api).*(?:entry|function)','tokens');
              mname=vertcat(mname{:});
              if numel(mname)==1
                fns={lower(mname{1}) tt(j).name tt(j).name tt(j).description};
              else
                mname=regexpi(t(cpart(i):cpart(i+1)),'(?:entry|function).*(package|module|wrap|visualize|template|wizard|api)|(package|module|wrap|visualize|template|wizard|api).*(?:entry|function)','tokens');
                mname=vertcat(mname{:});
                mname=vertcat(mname{:});
                if ~isempty(mname)
                  fns={lower(mname{1}) tt(j).name tt(j).name tt(j).description};
                end;
              end;
            end;
            if ~isempty(fns)
              if strcmp(fns{1},'package')
                out(1).entry=str2func(fns{3});
                out(1).path=fileparts(filepath);
              else
                if strcmp(fns{1},'template')
                  if ~isfield(out,'templates') out(1).templates={}; end;
                  if isempty(out(1).templates)||(~any(strcmp(fns{3},out(1).templates))) out(1).templates{end+1}=fns{3}; end;
                elseif strcmp(fns{1},'api')
                  if ~isfield(out,'api') out(1).api={}; end;
                  if isempty(out(1).api)||(~any(strcmp(fns{3},out(1).api))) out(1).api{end+1}=fns{3}; end;
                elseif any(strcmp(fns{1},{'module' 'wrap' 'visualize' 'wizard'}))
                  if ~isfield(out,'modules')
                    out(1).modules=api_core_defmodule;
                    out(1).modules(1)=[];
                    ind=[];
                  elseif ~isempty(out(1).modules) ind=cellfun(@(f)isequal(f,str2func(fns{3})),{out(1).modules.entry});
                  else ind=[];
                  end;
                  mn=regexp(fns{2},'^(.+)_([^_]+)$','tokens');
                  if isempty(mn) mn={out(1).version.name,fns{2}}; else mn=mn{1}; end;
                  if isempty(ind)||(~any(ind)) out(1).modules(end+1)=api_core_defmodule(fns{1},str2func(fns{3}),api_core_defversion(mn{:}),mn{2},mn{1},[out(1).version.major '.' out(1).version.minor],fns{4});
                  else
                    out(1).modules(ind).type=fns{1};
                    out(1).modules(ind).version.container=mn{1};
                    out(1).modules(ind).version.name=mn{2};
                    out(1).modules(ind).name=mn{2};
                    out(1).modules(ind).package=mn{1};
                    out(1).modules(ind).packageversion=[out(1).version.major '.' out(1).version.minor];
                    out(1).modules(ind).description=fns{4};
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;
