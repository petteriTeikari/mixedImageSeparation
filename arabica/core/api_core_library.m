function out=api_core_library(mode,varargin)
%API_CORE_LIBRARY Handle LONI Pipeline XML definitions.
%   API_CORE_LIBRARY imports, generates and exports LONI Pipeline XML files
%   as strings or from and to personal and server library directories.
%   %TODO: Write help text
%          () list known libraries
%          ('list') list known libraries
%          ('add','<name>','<path>','<server>','<wrapper>',<funroll>)
%          define new library
%          ('remove','name') remove named library
%
%          ('export',lib) export all modules and templates to library
%          ('export',lib,<def>,...) export given package(s) or module(s) to
%          library
%          ('export',lib,'<filename>',...) export given pipeline file(s) to
%          library
%          ('export',lib,'<string>',...) export given pipeline text(s) to
%          library
%          ('export',lib,'<uri>',...) export given module(s) to library
%          FILES=API_CORE_LIBRARY('export',...) returns a cell list of
%          filenames created.
%
%          ('xml','<uri>') returns a string containing the definition of
%          the module specified by the given URI
%          ('xml','<uri>','<name>') also renames the module and related id
%          ('xml','<uri>','<name>',<i>) also uses the given instance index
%          in the id
%          ('xml','<uri>','<name>',<i>,[<posx> <posy>]) also uses the given
%          position
%          ('xml','<uri>','<name>',<i>,[<posx> <posy>],<rot>) also uses the
%          given rotation
%          the magic URIs 'begin' and 'end' return a modulegroup start and
%          end
%          the magic URIs 'header' and 'footer' return valid start and end
%          for a .pipe file
%
%          differences to LONI's Pipeline XML schema:
%
%          the pipeline location URI formats supported by Arabica are:
%          arabica://[<server>/]<type>/<package>/<module>
%          arabica://[<server>/]<type>/<package>/<module>/<@function-name>
%          arabica://[<server>/]<type>/<package>/<module>/<@();inline-function>
%          arabica://[<server>/]<type>/<package>/<module>/<path-to-m|p|mex-file>
%          where <type> is one of 'module','wrap','visualize' or 'wizard'
%
%          a new element in arabica namespace is defined to make reoccuring
%          streams of parameters easily creatable, it must appear inside
%          the <dependencies> element only once, e.g.:
%          <arabica:recurrence xmlns:arabica cardinality="" base="" />
%
%   See also API_CORE_PARSEPIPELINE, API_CORE_DEFMODULE.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,Inf);
if ~exist('mode','var') mode='list'; end;
mode=api_core_checkopt(mode,'MODE','list','add','remove','import','export','xml');
api_core_persistent('lock');
libs=api_core_persistent('get','libraries');
if isempty(libs) libs=struct('name',{},'server',{},'path',{},'wrapper',{},'funroll',{}); end;
if strcmp(mode,'list')
  api_core_checknarg(0,1,0,1);
  res=libs;
elseif strcmp(mode,'add')
  api_core_checknarg(0,1,2,6);
  m=api_core_checkarg(varargin{1},{'LIBRARY' 'scalar struct';'NAME' 'str'});
  if m==1
    %TODO: Maybe in the future more type safe
    i=find(strcmp(varargin{1}.name,{libs(:).name}),1);
    if isempty(i) i=numel(libs)+1; end;
    libs(i)=varargin{1};
  else
    api_core_checknarg(0,1,3,6);
    api_core_checkarg(varargin{2},'PATH','str');
    i=find(strcmp(varargin{1},{libs(:).name}),1);
    if isempty(i) i=numel(libs)+1; end;
    libs(i).name=char(varargin{1});
    if ~isempty(varargin{2}) libs(i).path=char(varargin{2}); end;
    if nargin>3
      api_core_checkarg(varargin{3},'SERVER','str');
      libs(i).server=varargin{3};
    end;
    if nargin>4
      api_core_checkarg(varargin{4},'WRAPPER','str');
      libs(i).wrapper=varargin{4};
    end;
    if nargin>5
      api_core_checkarg(varargin{5},'FUNROLL','scalar integer positive');
      libs(i).funroll=varargin{5};
    end;
  end;
  %TODO: Maybe in the future check that the path is syntactically valid (does not have to exist)
  %TODO: Maybe in the future check that server name is valid
  if isempty(libs(i).server) libs(i).server='localhost'; end;
  %TODO: Maybe in the future check that wrapper filename is syntactically valid (does not have to exist)
  if isempty(libs(i).wrapper)
    if ispc libs(i).wrapper=fullfile(fileparts(which('arabica_wrapper')),'arabica_wrapper.bat');
    else libs(i).wrapper=fullfile(fileparts(which('arabica_wrapper')),'arabica_wrapper.sh');
    end;
  end;
  if isempty(libs(i).funroll) libs(i).funroll=4; end;
  res=libs(i);
  api_core_persistent('set','libraries',libs);
elseif strcmp(mode,'remove')
  api_core_checknarg(0,1,2,2);
  api_core_checkarg(varargin{1},'NAME','str');
  i=find(strcmp(varargin{1},{libs(:).name}),1);
  res=libs(i);
  libs=libs(setdiff(1:numel(libs),i));
  api_core_persistent('set','libraries',libs);
elseif strcmp(mode,'import')
  api_core_checknarg(0,1,2,Inf);
  lib=[];
  res={};
  m=api_core_checkarg(varargin{1},{'LIBRARY' 'scalar struct';'NAME' 'str'});
  if m==1 lib=varargin{1};
  else lib=libs(find(strcmp(varargin{1},{libs(:).name}),1));
  end;
  varargin(1)=[];
  if ~isempty(lib)
    %TODO: Design and implement importing
  end;
elseif strcmp(mode,'export')
  api_core_checknarg(0,1,2,Inf);
  res={};
  m=api_core_checkarg(varargin{1},{'LIBRARY' 'scalar struct';'NAME' 'str'});
  if m==1 lib=varargin{1};
  else lib=libs(find(strcmp(varargin{1},{libs(:).name}),1));
  end;
  varargin(1)=[];
  if isempty(varargin)
    [mods,pkgs]=api_core_modules;
    varargin=num2cell(pkgs);
  end;
  list={};
  while ~isempty(varargin)
    if isstruct(varargin{1})
      if api_core_checkpackage(varargin{1})
        for i=1:numel(varargin{1})
          for j=1:numel(varargin{1}(i).templates)
            if exist(fullfile(varargin{1}(i).path,[varargin{1}(i).templates{j} '.pipe']),'file')
              list=horzcat(list,fullfile(varargin{1}(i).path,[varargin{1}(i).templates{j} '.pipe']));
            elseif exist(fullfile(varargin{1}(i).path,varargin{1}(i).templates{j}),'file')
              list=horzcat(list,fullfile(varargin{1}(i).path,varargin{1}(i).templates{j}));
            elseif exist(fullfile(varargin{1}(i).templates{j}),'file')
              list=horzcat(list,fullfile(varargin{1}(i).templates{j}));
            end;
          end;
          varargin=horzcat(varargin(1),num2cell(varargin{1}(i).modules),varargin(2:end));
        end;
      elseif api_core_checkmodule(varargin{1}) list=horzcat(list,num2cell(varargin{1}));
      else error('API_CORE_LIBRARY:invalidInput','DEFINITION must be a valid package or module definition structure.');
      end;
    elseif ischar(varargin{1})||iscellstr(varargin{1})
      temp=cellstr(varargin{1});
      for i=1:numel(temp)
        %TODO: Maybe in the future check both files and strings better already here
        if ((length(temp{i})>10)&&strcmp(temp{i}(1:10),'arabica://'))||((length(temp{i})>5)&&strcmp(temp{i}(1:5),'<?xml'))||exist(temp{i},'file') list{end+1}=temp{i};
        else error('API_CORE_LIBRARY:invalidInput','STRING must be a valid filename or URI or contain valid LONI Pipeline XML.');
        end;
      end;
    end;
    varargin(1)=[];
  end;
  %TODO: Maybe in the future prune out duplicates in list
  if isfield(lib,'path')&&isfield(lib,'wrapper')&&(~isempty(lib.path))&&(~isempty(lib.wrapper))
    while ~exist(lib.path,'dir')
      [temp{1:4}]=fileparts(lib.path);
      while ~exist(temp{1},'dir') [temp{1:4}]=fileparts(temp{1}); end;
      mkdir(fullfile(temp{1},[temp{2:4}]));
    end;
    for i=1:numel(list)
      group='';
      type='';
      pkg='';
      mod='';
      if isstruct(list{i})||((length(list{i})>10)&&strcmp(list{i}(1:10),'arabica://'))
        if isstruct(list{i})
          type=list{i}.type;
          pkg=list{i}.version.container;
          mod=list{i}.version.name;
          uri=sprintf('arabica://%s/%s/%s/%s',lib.server,type,pkg,mod);
        else
          tt=regexp(list{i},'^arabica://(?<server>[^/]+|)(?:/|)(?<type>module|wrap|visualize|wizard)/(?<package>[^/]+)/(?<name>[^/]+)(?:/|)(?<fun>.+?|)$','names');
          if isempty(tt) error('API_CORE_LIBRARY:invalidInput','URI must be a valid Arabica URI.'); end;
          type=tt.type;
          pkg=tt.package;
          mod=tt.name;
          if isempty(tt.server) tt.server=lib.server; end;
          uri=sprintf('arabica://%s/%s/%s/%s',tt.server,type,pkg,mod);
        end;
        temp={};
        temp{end+1}=api_core_library('xml','header');
        temp{end+1}=api_core_library('xml','begin');
        temp{end+1}=api_core_library('xml',uri);
        temp{end+1}=api_core_library('xml','end');
        temp{end+1}=api_core_library('xml','footer');
        temp=horzcat(temp{:});
      elseif (length(list{i})>5)&&strcmp(list{i}(1:5),'<?xml') temp=list{i};
      elseif exist(list{i},'file')
        [fn{1:4}]=fileparts(list{i});
        fid=fopen(fullfile(list{i}),'r','native','UTF-8');
        if fid~=-1
          temp=fread(fid,Inf,'*char').';
          fclose(fid);
        end;
        t=regexp(temp,'^<\?xml\s+version="(?<xmlver>[^"]*)"\s+encoding="(?<xmlenc>[^"]*)"\s*\?>\s*<pipeline\s+version="(?<pipever>[^"]*)"\s*>.*</pipeline\s*>\s*$','names');
        %TODO: Maybe in the future check that versions and encoding are correct
        %TODO: Maybe in the future support different languages in the xml if pipeline will support it
        if ~isempty(t)
          if (numel(regexp(temp,'<moduleGroup(?:\s+\w+="[^"]*")*?\s*>.*?</moduleGroup\s*>'))>1)||(numel(regexp(temp,'<(?<type>module|dataModule|viewerModule)(?:\s+\w+="[^"]*")*?\s*>.*?</\k<type>\s*>'))>1)
            t=regexp(temp,'<moduleGroup(?:\s+\w+="[^"]*")*?\s+name="([^"]*)"(?:\s+\w+="[^"]*")*?\s*>.*</moduleGroup\s*>','tokens');
            %TODO: Maybe in the future really check which group is highest in hierarchy
            group=t{1}{1};
          end;
          oldids=regexp(temp,'<connections>(.*?)</connections>','tokens');
          if ~isempty(oldids) oldids=horzcat(oldids{:}); end;
          if ~isempty(oldids) oldids=horzcat(oldids{:}); end;
          oldids=regexp(oldids,'<connection(?:\s+\w+="[^"]*")*?\s+(?:source|sink)="(?<id1>[^"]*)"(?:\s+\w+="[^"]*")*?\s+(?:source|sink)="(?<id2>[^"]*)"(?:\s+\w+="[^"]*")*?\s*/>','names');
          oldids=struct2cell(oldids);
          oldids=unique(oldids(:));
          newids=oldids;
          [tmod,tsplit]=regexp(temp,'[ \t\v]*<(?<type>module|dataModule|viewerModule)(?:\s+\w+="[^"]*")*?\s+location="arabica://[^"]*"(?:\s+\w+="[^"]*")*?\s*>.*?</\k<type>\s*>[ \t\v]*[\f\n\r]*','match','split');
          temp=tsplit(1);
          for j=1:numel(tmod)
            t=regexp(tmod{j},'<(?<type>module|dataModule|viewerModule)(\s+\w+="[^"]*")+\s*>.*?</\k<type>\s*>','tokens');
            t=regexp(t{1}{2},'(?<name>name|id|location|posX|posY|rotation)="(?<value>[^"]*)"','names');
            t=cell2struct({t(:).value},{t(:).name},2);
            tt=regexp(t.location,'^arabica://(?<server>[^/]+|)(?:/|)(?<type>module|wrap|visualize|wizard)/(?<package>[^/]+)/(?<name>[^/]+)(?:/|)(?<fun>.+?|)$','names');
            if isempty(tt.server) tt.server=lib.server; end;
            uri=sprintf('arabica://%s/%s/%s/%s',tt.server,tt.type,tt.package,tt.name);
            if isempty(group)
              type=tt.type;
              pkg=tt.package;
              mod=tt.name;
            end;
            name='';
            id=0;
            pos=[0 0];
            rot=false;
            fr=1;
            if isfield(t,'name') name=t.name; end;
            if isfield(t,'id')
              id=regexp(t.id,'.*_(\d+)$','tokens');
              if isempty(id) id=0; else id=str2double(id{1}{1}); end;
            end;
            if isfield(t,'posX') pos(1)=str2double(t.posX); end;
            if isfield(t,'posY') pos(2)=str2double(t.posY); end;
            if isfield(t,'rotation')&&strcmp(t.rotation,'1') rot=true; end;
            %TODO: Extract parameter enables and values and match with oldids
            params=regexp(tmod{j},'<(?<type>input|output)(?<attr>\s+\w+="[^"]*")+\s*/>|<(?<type>input|output)(?<attr>\s+\w+="[^"]*")+\s*>(?<elem>.*?)</\k<type>\s*>','names');
            %TODO: Set fr to minimum possible based on oldids
            tmod{j}=api_core_library('xml',uri,name,id,pos,rot,fr);
            %TODO: Input parameter enables and values and rename oldids
            for k=1:numel(params)
              params(k).attr=regexp(params(k).attr,'(?<name>\w+)="(?<value>[^"]*)"','names');
              params(k).attr=cell2struct({params(k).attr(:).value},{params(k).attr(:).name},2);
              if isfield(params(k).attr,'enabled')
                tmod{j}=regexprep(tmod{j},'(?<start><(?:input|output)(?:\s+\w+="[^"]*")*?\s+id="(??@params(k).attr.id)"(?:\s+\w+="[^"]*")*?\s+enabled=")[^"]*(?<end>"(?:\s+\w+="[^"]*")*?\s*>)','$<start>${params(k).attr.enabled}$<end>');
              end;
              if ~isempty(params(k).elem)
                tmod{j}=regexprep(tmod{j},'(?<start><(?:input|output)(?:\s+\w+="[^"]*")*?\s+id="(??@params(k).attr.id)"(?:\s+\w+="[^"]*")*?\s*>.*?)\s*(?:\<values\s*>.*?<values\s*/>|)\s*(?<end></(?:input|output)\s*>)','$<start>${params(k).elem}$<end>');
              end;
            end;
            temp{end+1}=tmod{j};
            temp{end+1}=tsplit{j+1};
          end;
          temp=horzcat(temp{:});
          %TODO: Maybe in the future deal with the possibility that old and new ids overlap
          for j=1:numel(oldids)
            temp=regexprep(temp,'(?<start><(?:input|output)(?:\s+\w+="[^"]*")*?\s+id="(??@oldids{j})"(?:\s+\w+="[^"]*")*?\s+enabled=")[^"]*(?<end>"(?:\s+\w+="[^"]*")*?\s*>)','$<start>true$<end>');
            if ~strcmp(oldids{j},newids{j}) temp=regexprep(temp,'(?<start><connections>.*?<connection(?:\s+\w+="[^"]*")*?\s+(?:source|sink)=")(??@oldids{j})(?<end>"(?:\s+\w+="[^"]*")*?\s*/>.*?</connections>)','$<start>${newids{j}}$<end>'); end;
          end;
        end;
      end;
      if ischar(list{i})&&exist(list{i},'file') fn={lib.path fn{2} '.pipe' ''};
      elseif ~isempty(group) fn={lib.path group '.pipe' ''};
      elseif ~isempty(mod) fn={lib.path sprintf('%s_%s_%s',type,pkg,mod) '.pipe' ''};
      else fn={};
      end;
      if ~isempty(fn)
        fid=fopen(fullfile(fn{1},[fn{2:3}]),'w','native','UTF-8');
        if fid~=-1
          fprintf(fid,'%s',temp);
          fclose(fid);
        end;
        res{end+1}=fullfile(fn{1},[fn{2:3}]);
      end;
    end;
  end;
elseif strcmp(mode,'xml')
  api_core_checknarg(0,1,2,7);
  api_core_checkarg(varargin{1},'URI','str');
  uri=varargin{1};
  varargin(1)=[];
  res='';
  if any(strcmp(uri,{'header' 'footer' 'end'}))
    api_core_checknarg(0,1,2,2);
    if strcmp(uri,'header') res=sprintf('<?xml version="1.0" encoding="UTF-8"?>\n<pipeline version=".1">\n');
    elseif strcmp(uri,'footer') res=sprintf('</pipeline>\n');
    elseif strcmp(uri,'end') res=sprintf('        </moduleGroup>\n');
    end;
  else
    name='';
    id=0;
    pos=[0 0];
    rot=false;
    fr=1;
    if ~isempty(varargin)
      api_core_checkarg(varargin{1},'NAME','str');
      name=varargin{1};
      varargin(1)=[];
    end;
    if ~isempty(varargin)
      api_core_checkarg(varargin{1},'ID','scalar integer nonnegative');
      id=varargin{1};
      varargin(1)=[];
    end;
    if ~isempty(varargin)
      api_core_checkarg(varargin{1},'POSITION','integer 1x2');
      pos=varargin{1};
      varargin(1)=[];
    end;
    if ~isempty(varargin)
      api_core_checkarg(varargin{1},'ROTATION','scalar logical');
      rot=varargin{1};
      varargin(1)=[];
    end;
    if ~isempty(varargin)
      api_core_checkarg(varargin{1},'FUNROLL','scalar integer positive');
      fr=varargin{1};
      varargin(1)=[];
    end;
    if strcmp(uri,'begin')
      if isempty(name) name='Untitled'; end;
      id=sprintf('%s_%i',strrep(name,' ',''),id);
      res=sprintf('        <moduleGroup name="%s" description="" id="%s" posX="%i" posY="%i" rotation="%i">\n',name,id,pos(1),pos(2),rot);
    else
      t=regexp(uri,'^arabica://(?<server>[^/]+|)(?:/|)(?<type>module|wrap|visualize|wizard)/(?<package>[^/]+)/(?<name>[^/]+)(?:/|)(?<fun>.+?|)$','names');
      if isempty(t) error('API_CORE_LIBRARY:invalidURI',api_core_l10n('sprintf','String %s is not a valid Arabica URI!',uri)); end;
      mod=api_core_modules('type',t.type,'package',t.package,'name',t.name);
      if isempty(mod) error('API_CORE_LIBRARY:unknownModule',api_core_l10n('sprintf','Required %s "%s/%s" is not among the initialized modules!',t.type,t.package,t.name)); end;
      if isempty(t.server) t.server='localhost'; end;
      lib=libs(find(strcmp(t.server,{libs(:).server}),1));
      if isempty(lib) error('API_CORE_LIBRARY:unknownServer',api_core_l10n('sprintf','Unknown server "%s"!.',t.server)); end;
      modtype='module';
      %TODO: Maybe in the future LONI Pipeline can deal with the next line since it is valid definition just coded wrong in the Pipeline client
      %if strcmp(mod.type,'visualize') modtype='viewerModule'; end;
      if isempty(name) name=mod.name; end;
      idname=strrep(name,' ','');
      idtype=[upper(mod.type(1)) mod.type(2:end)];
      if isempty(mod.icon) icon='';
      elseif isnumeric(mod.icon)
        %TODO: Maybe in the future support icon base64 encoding
        icon='';
      else icon=strrep(mod.icon,sprintf('\n'),'&#xA;');
      end;
      %TODO: Maybe in the future encode UTF-8 XML strings
      temp={};
      temp{end+1}=sprintf('                <%s name="%s" description="%s" location="pipeline://%s/%s" id="%s" package="%s" version="%s" icon="%s" posX="%i" posY="%i" rotation="%i" executableVersion="%s">\n',modtype,name,mod.description,lib.server,lib.wrapper,sprintf('%s_%i',idname,id),mod.package,mod.packageversion,icon,pos(1),pos(2),rot,mod.exeversion);
      if ~isempty(mod.authors)
        temp{end+1}=sprintf('                        <authors>\n');
        for j=1:size(mod.authors,1) temp{end+1}=sprintf('                                <author fullName="%s" email="%s" website="%s" />\n',mod.authors{j,:}); end;
        temp{end+1}=sprintf('                        </authors>\n');
      end;
      if ~isempty(mod.exeauthors)
        temp{end+1}=sprintf('                        <executableAuthors>\n');
        for j=1:size(mod.exeauthors,1) temp{end+1}=sprintf('                                <author fullName="%s" email="%s" website="%s" />\n',mod.exeauthors{j,:}); end;
        temp{end+1}=sprintf('                        </executableAuthors>\n');
      end;
      if ~isempty(mod.citations)
        temp{end+1}=sprintf('                        <citations>\n');
        for j=1:numel(mod.citations) temp{end+1}=sprintf('                                <citation>%s</citation>\n',mod.citations{j}); end;
        temp{end+1}=sprintf('                        </citations>\n');
      end;
      for j=1:numel(mod.tags) temp{end+1}=sprintf('                        <tag>%s</tag>\n',mod.tags{j}); end;
      if ~isempty(mod.uri) temp{end+1}=sprintf('                        <uri>%s</uri>\n',mod.uri); end;
      %TODO: Maybe in the future include the time zone (in linux we could just use [status,str]=system('date'); but what about MS Windows)
      if isempty(mod.date) ds=datestr(now,'ddd mmm dd HH:MM:SS yyyy');
      elseif isnumeric(mod.date) ds=datestr(mod.date,'ddd mmm dd HH:MM:SS yyyy');
      else ds=mod.date;
      end;
      temp{end+1}=sprintf('                        <metadata>\n                                <data key="__creationDateKey" value="%s" />\n                        </metadata>\n',ds);
      temp{end+1}=sprintf('                        <input name="%s" description="Name of the Arabica module to execute.&#xA;NOTE: Automatically generated.&#xA;WARNING: Not meant to be touched!&#xA;ERROR: You are warned only once!" id="%s" enabled="true" required="true" predefined="true" order="-1" switch="-%s" switchSpaced="true">\n                                <format type="String" cardinality="1" />\n                                <values>\n                                        <value>%s/%s</value>\n                                </values>\n                        </input>\n',idtype,sprintf('%s.%s_%i',idname,idtype,id),mod.type,mod.version.container,mod.version.name);
      ord=0;
      ford=zeros(1,numel(mod.parameters));
      fcord=repmat(NaN,1,numel(mod.parameters));
      for j=1:numel(mod.parameters)
        k=find([mod.parameters(:).recurrencebase]==j,1,'last');
        if ~isempty(k) fcord(j:k)=1; end;
      end;
      j=1;
      while j<=numel(mod.parameters)
        pm=mod.parameters(j);
        if isnan(fcord(j)) pmn=pm.name; else pmn=sprintf('%s %i',pm.name,fcord(j)); end;
        if pm.required&&(isnan(fcord(j))||(fcord(j)==1)) pmr='true'; else pmr='false'; end;
        if isempty(pm.switch)||(pm.switch(end)==' ') pms='true'; else pms='false'; end;
        temp{end+1}=sprintf('                        <%s name="%s" description="%s" id="%s" enabled="%s" required="%s" order="%i" switch="%s" switchSpaced="%s">\n',pm.type,pmn,pm.description,sprintf('%s.%s_%i',idname,strrep(pmn,' ',''),id),pmr,pmr,ord,deblank(pm.switch),pms);
        if isempty(pm.format) pmf='String'; else pmf=[upper(pm.format(1)) pm.format(2:end)]; end;
        temp{end+1}=sprintf('                                <format type="%s" cardinality="%i"',pmf,pm.cardinality);
        if pm.cardinality==-2
          k=pm.cardinalitybase;
          if isnan(fcord(k)) pmb=mod.parameters(k).name; else pmb=sprintf('%s %i',mod.parameters(k).name,fcord(k)); end;
          temp{end+1}=sprintf(' cardinalityBase="%s"',pmb);
        end;
        if ~isnan(pm.transformbase)
          k=pm.transformbase;
          if isnan(fcord(k)) pmb=mod.parameters(k).name; else pmb=sprintf('%s %i',mod.parameters(k).name,fcord(k)); end;
          temp{end+1}=sprintf(' base="%s"',pmb);
        end;
        if (~isempty(pm.transform))||any(strcmp(pm.format,{'file' 'enumerated'})) pmfe=''; else pmfe=' /'; end;
        temp{end+1}=sprintf('%s>\n',pmfe);
        if strcmp(pm.format,'file')
          temp{end+1}=sprintf('                                        <fileTypes>\n');
          for k=1:numel(pm.filetype)
            temp{end+1}=sprintf('                                                <filetype name="%s" extension="%s" description="%s"',pm.filetype(k).name,pm.filetype(k).extension,pm.filetype(k).description);
            if isempty(pm.filetype(k).need) temp{end+1}=sprintf(' />\n'); else temp{end+1}=sprintf('>\n'); end;
            for l=1:numel(pm.filetype(k).need) temp{end+1}=sprintf('                                                        <need>%s</need>\n',pm.filetype(k).need{l}); end;
            if ~isempty(pm.filetype(k).need) temp{end+1}=sprintf('                                                </filetype>\n'); end;
          end;
          temp{end+1}=sprintf('                                        </fileTypes>\n');
        elseif strcmp(pm.format,'enumerated')
          for k=1:numel(pm.enumeration) temp{end+1}=sprintf('                                        <enumeration>%s</enumeration>\n',pm.enumeration{k}); end;
        end;
        for k=1:size(pm.transform,1) temp{end+1}=sprintf('                                        <transform order="%i" operation="%s">%s</transform>\n',k-1,[upper(pm.transform{k,1}(1)) pm.transform{k,1}(2:end)],pm.transform{k,2}); end;
        if isempty(pmfe) temp{end+1}=sprintf('                                </format>\n'); end;
        pmd=[];
        for k=1:numel(mod.parameters)
          if ismember(j,mod.parameters(k).depend) pmd(end+1)=k; end;
        end;
        if (~isempty(pm.depend))||(~isempty(pmd))
          temp{end+1}=sprintf('                                <dependencies>\n');
          for k=1:numel(pmd)
            if isnan(fcord(pmd(k))) pmb=mod.parameters(pmd(k)).name; else pmb=sprintf('%s %i',mod.parameters(pmd(k)).name,fcord(pmd(k))); end;
            temp{end+1}=sprintf('                                        <dependent>%s</dependent>\n',pmb);
          end;
          for k=1:numel(pm.depend)
            l=pm.depend(k);
            if isnan(fcord(l)) pmb=mod.parameters(l).name; else pmb=sprintf('%s %i',mod.parameters(l).name,fcord(l)); end;
            temp{end+1}=sprintf('                                        <dependsOn>%s</dependsOn>\n',pmb);
          end;
          temp{end+1}=sprintf('                                </dependencies>\n');
        end;
        temp{end+1}=sprintf('                        </%s>\n',pm.type);
        ord=ord+1;
        ford(j)=ford(j)+1;
        if ((pm.recurrence>=0)&&(ford(j)>=min(max(fr,lib.funroll),pm.recurrence)))||((pm.recurrence<0)&&(ford(j)>=max(fr,lib.funroll))) j=j+1;
        else
          k=pm.recurrencebase;
          ford(k:(j-1))=0;
          fcord(k:j)=fcord(k:j)+1;
          j=k;
        end;
      end;
      temp{end+1}=sprintf('                </%s>\n',modtype);
      res=horzcat(temp{:});
    end;
  end;
end;

if nargout>0 out=res;
elseif strcmp(mode,'list')
  api_core_l10n('fprintf','Known LONI Pipeline libraries:\n\n');
  for i=1:numel(res) fprintf('  %s = %s,  %s,  %s,  %i\n',libs(i).name,libs(i).server,libs(i).path,libs(i).wrapper,libs(i).funroll); end;
  if ~isempty(res) fprintf('\n'); end;
elseif any(strcmp(mode,{'add' 'remove'}))
  if isempty(res)
    if strcmp(mode,'add') api_core_l10n('fprintf','Cannot add library "%s".\n\n',varargin{1});
    else api_core_l10n('fprintf','Cannot remove library "%s".\n\n',varargin{1});
    end;
  else
    if strcmp(mode,'add') api_core_l10n('fprintf','Added library "%s" = %s,  %s,  %s,  %i\n\n',res.name,res.server,res.path,res.wrapper,res.funroll);
    else api_core_l10n('fprintf','Removed library "%s" = %s,  %s,  %s,  %i\n\n',res.name,res.server,res.path,res.wrapper,res.funroll);
    end;
  end;
elseif any(strcmp(mode,{'import' 'export'}))
  if isempty(res)
    if strcmp(mode,'import') api_core_l10n('fprintf','Cannot import modules.\n\n');
    else api_core_l10n('fprintf','Cannot export modules.\n\n');
    end;
  else
    if strcmp(mode,'import')
      api_core_l10n('fprintf','Imported following LONI Pipeline modules:\n\n');
      %TODO: Pretty-print modules
      if ~isempty(res) fprintf('\n'); end;
    else
      api_core_l10n('fprintf','Exported following LONI Pipeline files:\n\n');
      for i=1:numel(res) fprintf('  %s\n',res{i}); end;
      if ~isempty(res) fprintf('\n'); end;
    end;
  end;
end;
