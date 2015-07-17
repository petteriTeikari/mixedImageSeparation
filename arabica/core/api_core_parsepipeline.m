function out=api_core_parsepipeline(filepath,def)
%API_CORE_PARSEPIPELINE Parse a LONI Pipeline module XML file.
%   %TODO: Write help text
%          ('<path>') def ready filled in using file contents
%          ('<path>',<def>) given def appended using file contents
%
%          the XML file is parsed to identify details needed to define and
%          execute a single module, not to fully describe a module nor a
%          complete pipeline
%
%          differences to LONI's Pipeline XML schema:
%
%          the pipeline location URI formats supported by Arabica are:
%          arabica://<type>/<package>/<module>
%          arabica://<type>/<package>/<module>/<@function-name>
%          arabica://<type>/<package>/<module>/<@();inline-function>
%          arabica://<type>/<package>/<module>/<path-to-m|p|mex-file>
%          where <type> is one of 'module','wrap','visualize' or 'wizard'
%
%          a new element in arabica namespace is defined to make reoccuring
%          streams of parameters easily creatable, it must appear inside
%          the <dependencies> element only once: 
%          <arabica:recurrence xmlns:arabica cardinality="" base="" />
%
%          the difference to api_core_defmodule is that the output is not
%          guaranteed to be a valid module definition structure but only
%          contains or is appended with the found details
%
%   See also API_CORE_PARSEDIR, API_CORE_ISMODULE, API_CORE_DEFMODULE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,1,2);
api_core_checkarg(filepath,'FILE','str');
if ~exist(filepath,'file') error('API_CORE_PARSEPIPELINE:invalidInput','Path must point to an existing file.'); end;
if exist('def','var')&&api_core_checkarg(def,'BASE','struct') out=def; else out=struct([]); end;

temp={};
fid=fopen(filepath,'r','native','UTF-8');
if fid~=-1
  temp=fread(fid,Inf,'*char').';
  fclose(fid);
end;
[filepath,filename]=fileparts(filepath);
if ~isempty(temp)
  t=regexp(temp,'^<\?xml\s+version="(?<xmlver>[^"]*)"\s+encoding="(?<xmlenc>[^"]*)"\s*\?>\s*<pipeline\s+version="(?<pipever>[^"]*)"\s*>(?<pipeline>.*)</pipeline\s*>\s*$','names');
  if (~isempty(t))&&(numel(regexp(temp,'<moduleGroup(?:\s+\w+="[^"]*")*?\s*>.*?</moduleGroup\s*>'))==1)||(numel(regexp(temp,'<(?<type>module|dataModule|viewerModule)(?:\s+\w+="[^"]*")*?\s*>.*?</\k<type>\s*>'))==1)
    %TODO: Maybe in the future check that versions and encoding are correct
    %TODO: Maybe in the future support different languages in the xml if pipeline will support it
    temp=t.pipeline;
    t=regexp(temp,'<(?<type>module|dataModule|viewerModule)(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</\k<type>\s*>','names');
    if numel(t)==1
      t.attr=regexp(t.attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
      t.attr=cell2struct({t.attr(:).value},{t.attr(:).name},2);
      t.args=regexp(t.elem,'<(?<type>input|output)(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</\k<type>\s*>','names');
      for i=1:numel(t.args)
        t.args(i).attr=regexp(t.args(i).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
        t.args(i).attr=cell2struct({t.args(i).attr(:).value},{t.args(i).attr(:).name},2);
        t.args(i).format=regexp(t.args(i).elem,'<(?<type>format)(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</\k<type>\s*>','names');
        if isempty(t.args(i).format) t.args(i).format=regexp(t.args(i).elem,'<(?<type>format)(?<attr>\s+\w+="[^"]*")+\s*/>','names'); end;
        if numel(t.args(i).format)==1
          t.args(i).format.attr=regexp(t.args(i).format.attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
          t.args(i).format.attr=cell2struct({t.args(i).format.attr(:).value},{t.args(i).format.attr(:).name},2);
          if isfield(t.args(i).format,'elem')
            t.args(i).format.enum=regexp(t.args(i).format.elem,'<enumeration(?:\s+\w+="[^"]*")*\s*>(.*?)</enumeration\s*>','tokens');
            if ~isempty(t.args(i).format.enum) t.args(i).format.enum=horzcat(t.args(i).format.enum{:}); end;
            t.args(i).format.files=regexp(t.args(i).format.elem,'<(?<type>fileTypes)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
            if numel(t.args(i).format.files)==1
              t.args(i).format.files=regexp(t.args(i).format.files.elem,'<filetype(?<attr>\s+\w+="[^"]*")+\s*/>|<filetype(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</filetype\s*>','names');
              for j=1:numel(t.args(i).format.files)
                t.args(i).format.files(j).attr=regexp(t.args(i).format.files(j).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
                t.args(i).format.files(j).attr=cell2struct({t.args(i).format.files(j).attr(:).value},{t.args(i).format.files(j).attr(:).name},2);
                if ~isempty(t.args(i).format.files(j).elem)
                  t.args(i).format.files(j).need=regexp(t.args(i).format.files(j).elem,'<need(?:\s+\w+="[^"]*")*\s*>(.*?)</need\s*>','tokens');
                  if ~isempty(t.args(i).format.files(j).need) t.args(i).format.files(j).need=horzcat(t.args(i).format.files(j).need{:}); end;
                end;
              end;
            end;
            t.args(i).format.trans=regexp(t.args(i).format.elem,'<transform(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</transform\s*>','names');
            for j=1:numel(t.args(i).format.trans)
              t.args(i).format.trans(j).attr=regexp(t.args(i).format.trans(j).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
              t.args(i).format.trans(j).attr=cell2struct({t.args(i).format.trans(j).attr(:).value},{t.args(i).format.trans(j).attr(:).name},2);
            end;
          end;
        end;
        t.args(i).depend=regexp(t.args(i).elem,'<(?<type>dependencies)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
        if ~isempty(t.args(i).depend)
          t.args(i).dependent=regexp([t.args(i).depend(:).elem],'<dependent(?:\s+\w+="[^"]*")*\s*>(.*?)</dependent\s*>','tokens');
          if ~isempty(t.args(i).dependent) t.args(i).dependent=horzcat(t.args(i).dependent{:}); end;
          t.args(i).dependson=regexp([t.args(i).depend(:).elem],'<dependsOn(?:\s+\w+="[^"]*")*\s*>(.*?)</dependsOn\s*>','tokens');
          if ~isempty(t.args(i).dependson) t.args(i).dependson=horzcat(t.args(i).dependson{:}); end;
          t.args(i).recurrence=regexp([t.args(i).depend(:).elem],'<arabica:recurrence\s+xmlns:arabica(?<attr>\s+\w+="[^"]*")+\s*/>','names');
          if numel(t.args(i).recurrence)==1
            t.args(i).recurrence=regexp(t.args(i).recurrence.attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
            t.args(i).recurrence=cell2struct({t.args(i).recurrence(:).value},{t.args(i).recurrence(:).name},2);
          end;
        end;
        t.args(i).value=regexp(t.args(i).elem,'<(?<type>values)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
        if ~isempty(t.args(i).value)
          t.args(i).value=regexp([t.args(i).value(:).elem],'<value(?:\s+\w+="[^"]*")*\s*>(.*?)</value\s*>','tokens');
          if ~isempty(t.args(i).value) t.args(i).value=horzcat(t.args(i).value{:}); end;
        end;
      end;
      t.authors=regexp(t.elem,'<(?<type>authors)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
      if ~isempty(t.authors)
        t.authors=regexp([t.authors(:).elem],'<author(?<attr>\s+\w+="[^"]*")+\s*/>|<author(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</author\s*>','names');
        for i=1:numel(t.authors)
          t.authors(i).attr=regexp(t.authors(i).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
          t.authors(i).attr=cell2struct({t.authors(i).attr(:).value},{t.authors(i).attr(:).name},2);
        end;
      end;
      t.exeauthors=regexp(t.elem,'<(?<type>executableAuthors)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
      if ~isempty(t.exeauthors)
        t.exeauthors=regexp([t.exeauthors(:).elem],'<author(?<attr>\s+\w+="[^"]*")+\s*/>|<author(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</author\s*>','names');
        for i=1:numel(t.exeauthors)
          t.exeauthors(i).attr=regexp(t.exeauthors(i).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
          t.exeauthors(i).attr=cell2struct({t.exeauthors(i).attr(:).value},{t.exeauthors(i).attr(:).name},2);
        end;
      end;
      t.citations=regexp(t.elem,'<(?<type>citations)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
      if ~isempty(t.citations)
        t.citations=regexp([t.citations(:).elem],'<citation(?:\s+\w+="[^"]*")*\s*>(.*?)</citation\s*>','tokens');
        if ~isempty(t.citations) t.citations=horzcat(t.citations{:}); end;
      end;
      t.tags=regexp(t.elem,'<tag(?:\s+\w+="[^"]*")*\s*>(.*?)</tag\s*>','tokens');
      if ~isempty(t.tags) t.tags=horzcat(t.tags{:}); end;
      t.uri=regexp(t.elem,'<uri(?:\s+\w+="[^"]*")*\s*>(.*?)</uri\s*>','tokens');
      if ~isempty(t.uri) t.uri=char(t.uri{1}); end;
      %TODO: METADATA - DATE
      t.metadata=regexp(t.elem,'<(?<type>metadata)(?<attr>\s+\w+="[^"]*")*\s*>(?<elem>.*?)</\k<type>\s*>','names');
      if ~isempty(t.metadata)
        t.metadata=regexp([t.metadata(:).elem],'<data(?<attr>\s+\w+="[^"]*")+\s*/>|<data(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</data\s*>','names');
        for i=1:numel(t.metadata)
          t.metadata(i).attr=regexp(t.metadata(i).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
          t.metadata(i).attr=cell2struct({t.metadata(i).attr(:).value},{t.metadata(i).attr(:).name},2);
        end;
      end;
      %TODO: Maybe in the future decode UTF-8 XML strings
      tt=struct([]);
      if isfield(t.attr,'location')&&(~isempty(t.attr.location)) tt=regexp(t.attr.location,'^arabica://(?<type>module|wrap|visualize|wizard)/(?<package>[^/]+)/(?<name>[^/]+)(?:/|)(?<fun>.+?|)$','names'); end;
      if ~isempty(tt) out(1).type=tt.type;
      else
        tt(1).package='';
        tt.name='';
        if isfield(t.attr,'package')&&(~isempty(t.attr.package)) tt.package=lower(strrep(strrep(strrep(t.attr.package,'/','_'),'\','_'),' ','')); end;
        if isfield(t.attr,'id')&&(~isempty(t.attr.id))
          tt.name=regexp(t.attr.id,'(.+?)(?:_\d+|$)+','tokens');
          if ~isempty(tt.name) tt.name=tt.name{1}; else tt.name=''; end;
        elseif isfield(t.attr,'name')&&(~isempty(t.attr.name)) tt.name=lower(strrep(strrep(strrep(t.attr.name,'/','_'),'\','_'),' ',''));
        end;
      end;
      if ~isempty(tt.fun)
        if strcmp(tt.fun(1:2),'@(') out(1).entry=str2func(tt.fun);
        elseif tt.fun(1)=='@' out(1).entry=str2func(tt.fun(2:end));
        elseif exist(fullfile(tt.fun),'file')
          [fp{1:4}]=fileparts(tt.fun);
          if any(strcmp(fp{3},{'.m' '.p' '.mex'}))
            ws=warning('off','MATLAB:dispatcher:pathWarning');
            addpath(fp{1},'-end');
            warning(ws);
            out(1).entry=str2func([fp{2}]);
          end;
        end;
      elseif exist(fullfile(filepath,[filename '.m']),'file')||exist(fullfile(filepath,[filename '.p']),'file')||exist(fullfile(filepath,[filename '.mex']),'file') out(1).entry=str2func(filename);
      end;
      if isfield(t.attr,'name')&&(~isempty(t.attr.name)) out(1).name=t.attr.name; end;
      if isfield(t.attr,'package')&&(~isempty(t.attr.package)) out(1).package=t.attr.package; end;
      tt.version='';
      if isfield(t.attr,'executableVersion')&&(~isempty(t.attr.executableVersion))
        out(1).exeversion=t.attr.executableVersion;
        tt.version=t.attr.executableVersion;
      end;
      if isfield(t.attr,'version')&&(~isempty(t.attr.version))
        out(1).packageversion=t.attr.version;
        if isempty(tt.version) tt.version=t.attr.version; end;
      end;
      tt.version=regexp(tt.version,'(?<major>\d+).(?<minor>\d+)','names');
      if ~isempty(tt.version) out(1).version=api_core_defversion(tt.package,tt.name,str2double(tt.version.major),str2double(tt.version.minor));
      elseif (~isempty(tt.package))||(~isempty(tt.name)) out(1).version=api_core_defversion(tt.package,tt.name);
      end;
      if isfield(t.attr,'description')&&(~isempty(t.attr.description)) out(1).description=t.attr.description; end;
      %TODO: Maybe in the future support icon base64 decoding
      if isfield(t.attr,'icon')&&(~isempty(t.attr.icon)) out(1).icon=strrep(t.attr.icon,'&#xA;',sprintf('\n')); end;
      if isfield(t.attr,'posX')&&(~isempty(t.attr.posX)) out(1).position(1)=str2double(t.attr.posX); end;
      if isfield(t.attr,'posY')&&(~isempty(t.attr.posY)) out(1).position(2)=str2double(t.attr.posY); end;
      if isfield(t.attr,'rotation')&&(~isempty(t.attr.rotation)) out(1).rotation=logical(str2double(t.attr.rotation)); end;
      for i=1:numel(t.metadata)
        if isfield(t.metadata(i).attr,'key')&&strcmp(t.metadata(i).attr.key,'__creationDateKey')&&isfield(t.metadata(i).attr,'value')&&(~isempty(t.metadata(i).attr.value))
          out(1).date=t.metadata(i).attr.value;
          break;
        end;
      end;
      if ~isempty(t.tags) out(1).tags=t.tags; end;
      if ~isempty(t.uri) out(1).uri=t.uri; end;
      if ~isempty(t.citations) out(1).citations=t.citations; end;
      if ~isempty(t.authors) out(1).authors=cell(0,3); end;
      for i=1:numel(t.authors)
        tt={'' '' ''};
        if isfield(t.authors(i).attr,'fullName')&&(~isempty(t.authors(i).attr.fullName)) tt{1}=t.authors(i).attr.fullName; end;
        if isfield(t.authors(i).attr,'email')&&(~isempty(t.authors(i).attr.email)) tt{2}=t.authors(i).attr.email; end;
        if isfield(t.authors(i).attr,'website')&&(~isempty(t.authors(i).attr.website)) tt{3}=t.authors(i).attr.website; end;
        out(1).authors(end+1,:)=tt;
      end;
      if ~isempty(t.exeauthors) out(1).exeauthors=cell(0,3); end;
      for i=1:numel(t.exeauthors)
        tt={'' '' ''};
        if isfield(t.exeauthors(i).attr,'fullName')&&(~isempty(t.exeauthors(i).attr.fullName)) tt{1}=t.exeauthors(i).attr.fullName; end;
        if isfield(t.exeauthors(i).attr,'email')&&(~isempty(t.exeauthors(i).attr.email)) tt{2}=t.exeauthors(i).attr.email; end;
        if isfield(t.exeauthors(i).attr,'website')&&(~isempty(t.exeauthors(i).attr.website)) tt{3}=t.exeauthors(i).attr.website; end;
        out(1).exeauthors(end+1,:)=tt;
      end;
      if isfield(t,'args')&&(~isempty(t.args))
        aord=repmat(Inf,1,numel(t.args));
        for i=1:numel(t.args)
          tt=api_core_defparameter;
          tt.type=t.args(i).type;
          if isfield(t.args(i).attr,'name')&&(~isempty(t.args(i).attr.name)) tt.name=t.args(i).attr.name; end;
          if isfield(t.args(i).attr,'description')&&(~isempty(t.args(i).attr.description)) tt.description=t.args(i).attr.description; end;
          if isfield(t.args(i).attr,'switch')&&(~isempty(t.args(i).attr.switch)) tt.switch=t.args(i).attr.switch; end;
          if isfield(t.args(i).attr,'switchSpaced')&&strcmpi(t.args(i).attr.switchSpaced,'true') tt.switch=[tt.switch ' ']; end;
          if isfield(t.args(i).attr,'required')&&strcmpi(t.args(i).attr.required,'true') tt.required=true; end;
          if isfield(t.args(i),'dependson')&&(~isempty(t.args(i).dependson)) tt.depend=t.args(i).dependson; end;
          if isfield(t.args(i),'format')&&(~isempty(t.args(i).format))
            if isfield(t.args(i).format.attr,'type')&&(~isempty(t.args(i).format.attr.type)) tt.format=lower(t.args(i).format.attr.type); end;
            if isfield(t.args(i).format.attr,'cardinality')&&(~isempty(t.args(i).format.attr.cardinality)) tt.cardinality=str2double(t.args(i).format.attr.cardinality); end;
            if isfield(t.args(i).format.attr,'cardinalityBase')&&(~isempty(t.args(i).format.attr.cardinalityBase)) tt.cardinalitybase=t.args(i).format.attr.cardinalityBase; end;
            if isfield(t.args(i).format,'enum')&&(~isempty(t.args(i).format.enum)) tt.enumeration=t.args(i).format.enum; end;
            if isfield(t.args(i).format,'files')&&(~isempty(t.args(i).format.files))
              for j=1:numel(t.args(i).format.files)
                tt.filetype(j)=api_core_deffiletype;
                if isfield(t.args(i).format.files(j).attr,'name')&&(~isempty(t.args(i).format.files(j).attr.name)) tt.filetype(j).name=t.args(i).format.files(j).attr.name; end;
                if isfield(t.args(i).format.files(j).attr,'description')&&(~isempty(t.args(i).format.files(j).attr.description)) tt.filetype(j).description=t.args(i).format.files(j).attr.description; end;
                if isfield(t.args(i).format.files(j).attr,'extension')&&(~isempty(t.args(i).format.files(j).attr.extension)) tt.filetype(j).extension=t.args(i).format.files(j).attr.extension; end;
                if isfield(t.args(i).format.files(j),'need')&&(~isempty(t.args(i).format.files(j).need)) tt.filetype(j).need=t.args(i).format.files(j).need; end;
              end;
            end;
            if isfield(t.args(i).format,'trans')&&(~isempty(t.args(i).format.trans))
              tord=repmat(Inf,1,numel(t.args(i).format.trans));
              for j=1:numel(t.args(i).format.trans)
                if isfield(t.args(i).format.trans(j).attr,'operation')&&(~isempty(t.args(i).format.trans(j).attr.operation))
                  tt.transform(j,:)={t.args(i).format.trans(j).attr.operation t.args(i).format.trans(j).elem};
                  if isfield(t.args(i).format.trans(j).attr,'order')&&(~isempty(t.args(i).format.trans(j).attr.order)) tord(j)=str2double(t.args(i).format.trans(j).attr.order); end;
                else
                  tt.transform(j,:)={'' ''};
                  tord(j)=NaN;
                end;
              end;
              [nil,j]=sort(tord);
              tt.transform=tt.transform(j,:);
            end;
            if isfield(t.args(i).format.attr,'base')&&(~isempty(t.args(i).format.attr.base)) tt.transformbase=t.args(i).format.attr.base; end;
          end;
          if isfield(t.args(i).attr,'order')&&(~isempty(t.args(i).attr.order)) aord(i)=str2double(t.args(i).attr.order); end;
          if isfield(t.args(i),'recurrence')&&(~isempty(t.args(i).recurrence))
            if isfield(t.args(i).recurrence,'cardinality')&&(~isempty(t.args(i).recurrence.cardinality)) tt.recurrence=str2double(t.args(i).recurrence.cardinality); end;
            if isfield(t.args(i).recurrence,'base')&&(~isempty(t.args(i).recurrence.base)) tt.recurrencebase=t.args(i).recurrence.base; end;
          end;
          out(1).parameters(i)=tt;
        end;
        [nil,i]=sort(aord);
        out(1).parameters=out(1).parameters(i);
        for i=1:numel(out(1).parameters)
          if ischar(out(1).parameters(i).cardinalitybase) out(1).parameters(i).cardinalitybase=find(strcmp(out(1).parameters(i).cardinalitybase,{out(1).parameters(:).name}),1); end;
          if isempty(out(1).parameters(i).depend) out(1).parameters(i).depend=[];
          else
            [nil,j,k]=intersect({out(1).parameters(:).name},out(1).parameters(i).depend);
            out(1).parameters(i).depend=j(k);
          end;
          if ischar(out(1).parameters(i).transformbase) out(1).parameters(i).transformbase=find(strcmp(out(1).parameters(i).transformbase,{out(1).parameters(:).name}),1); end;
          if ischar(out(1).parameters(i).recurrencebase) out(1).parameters(i).recurrencebase=find(strcmp(out(1).parameters(i).recurrencebase,{out(1).parameters(:).name}),1); end;
        end;
      end;
    end;
  end;
end;
