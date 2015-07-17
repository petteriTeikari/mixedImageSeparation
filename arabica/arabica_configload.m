function out=arabica_configload
%ARABICA_CONFIGLOAD Load Arabica framework configuration.
%   ARABICA_CONFIGLOAD loads and displays the values found from
%   configuration files. 
%
%   CONF=ARABICA_CONFIG_LOAD loads and returns the values found from
%   configuration files in a structure.
%
%   The default configfiles are 'arabica.conf' in the same directory as
%   this function's m-file and '.arabica' in the user's home directory.
%   More configfiles can be included from those files if needed.
%   Additionally the '.pipeline' folder in the user's home directory is
%   searched automatically to detect LONI Pipeline's personal and server
%   libraries.
%
%   An example syntax for config files:
%
%   [framework arabica]
%   configfiles{}: '/etc/arabica.conf'
%   packagepaths{}: '/usr/share/arabica_packages'
%
%   [package <mypackage>]
%   <mylist>{}: <myappendedvalue>
%   <myname>: <myvalue>
%
%   NOTE: This function does not require initialization to be performed.
%
%   See also ARABICA, ARABICA_INIT.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

pathname=fileparts(mfilename('fullpath'));
conf.arabica.configfiles={};
fn=fullfile(pathname,'arabica.conf');
if exist(fn,'file') conf.arabica.configfiles{end+1}=fn; end;
fn='';
if ispc
  fn=winqueryreg('HKEY_CURRENT_USER','Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders','Local AppData');
  if isempty(fn) fn=winqueryreg('HKEY_CURRENT_USER','Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','Local AppData'); end;
  if ~isempty(fn) fn=fullfile(fn,'Arabica','arabica.conf'); end;
elseif ismac fn=fullfile(getenv('HOME'),'Library','Preferences','Arabica','arabica.conf');
elseif isunix fn=fullfile(getenv('HOME'),'.arabica');
end;
if exist(fn,'file') conf.arabica.configfiles{end+1}=fn; end;
%TODO: Maybe in the future define more default file locations
conf.arabica.packagepaths={pathname};
%TODO: Maybe in the future define more config defaults

i=1;
while i<=length(conf.arabica.configfiles)
  temp={};
  fid=fopen(conf.arabica.configfiles{i},'r');
  if fid~=-1
    temp=textscan(fid,'%s','Delimiter','');
    fclose(fid);
  end;
  pkg='';
  for l=1:length(temp)
    %TODO: Maybe in the future more type safe
    t=regexp(temp{l},'^\s*\[\s*(?<header>\w+)\s+(?<name>\w+)\s*\]\s*$','names');
    if ~isempty(t)
      if any(strcmp(t.header,{'framework' 'package'})) pkg=t.name; else pkg=''; end;
    end;
    t=regexp(temp{l},'^\s*(?<name>\w+)\s*{}\s*:\s*(?<value>\.+)\s*$','names');
    if (~isempty(t))&&(~isempty(pkg))
      if all(strcmp({pkg name},{'arabica' 'configfiles'}))
        conf.arabica.configfiles={conf.arabica.configfiles{1:i} t.value conf.arabica.configfiles{i+1:end}};
      else
        try
          tt=eval(['conf.' pkg '.' t.name ';']);
        catch err
          eval(['conf.' pkg '.' t.name '={};']);
        end;
        try
          eval(['conf.' pkg '.' t.name '{end+1}=' t.value ';']);
        catch err
        end;
      end;
    end;
    t=regexp(temp{l},'^\s*(?<name>\w+)\s*:\s*(?<value>\.+)\s*$','names');
    if (~isempty(t))&&(~isempty(pkg))
      try
        eval(['conf.' pkg '.' t.name '=' t.value ';']);
      catch err
      end;
    end;
  end;
  i=i+1;
end;
%TODO: Maybe in the future define more config syntax

if isfield(conf,'core')&&isfield(conf.core,'libraries')
  t=struct('name',{},'server',{},'path',{},'wrapper',{},'funroll',{});
  for i=1:numel(conf.core.libraries)
    %TODO: Maybe in the future more type save
    if isfield(conf.core.libraries{i},'name') t(i).name=conf.core.libraries{i}.name; end;
    if isfield(conf.core.libraries{i},'server') t(i).server=conf.core.libraries{i}.server; end;
    if isfield(conf.core.libraries{i},'path') t(i).path=conf.core.libraries{i}.path; end;
    if isfield(conf.core.libraries{i},'wrapper') t(i).wrapper=conf.core.libraries{i}.wrapper; end;
    if isfield(conf.core.libraries{i},'funroll') t(i).funroll=conf.core.libraries{i}.funroll; end;
  end;
  conf.core.libraries=t;
end;
fn='';
if ispc
  %TODO: Check that winqueryreg silently returns '' for missing keys or fix in MS Windows
  %TODO: Check that %USERPROFILE% is valid in paths in MS Windows
  fn=winqueryreg('HKEY_CURRENT_USER','Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders','Local AppData');
  if isempty(fn) fn=winqueryreg('HKEY_CURRENT_USER','Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','Local AppData'); end;
  if ~isempty(fn) fn=fullfile(fn,'LONI','Pipeline'); end;
elseif ismac fn=fullfile(getenv('HOME'),'Library','Preferences','Pipeline');
elseif isunix fn=fullfile(getenv('HOME'),'.pipeline');
end;
%TODO: Maybe in the future really use the HSQL databases
if exist(fn,'dir')
  t=struct('name',{'personal'},'server',{'localhost'},'path',{''},'wrapper',{''},'funroll',{[]});
  tt={};
  if exist(fullfile(fn,'preferences.xml'),'file')
    fid=fopen(fullfile(fn,'preferences.xml'),'r','native','UTF-8');
    if fid~=-1
      temp=fread(fid,Inf,'*char').';
      fclose(fid);
    else temp='';
    end;
    tt=regexp(temp,'<PersonalLibraryLocation(?:\s+\w+="[^"]*")*\s*>(.*?)</PersonalLibraryLocation\s*>','tokens');
  end;
  if isempty(tt)
    if ispc
      %TODO: Check that winqueryreg silently returns '' for missing keys or fix in MS Windows
      %TODO: Check that %USERPROFILE% is valid in paths in MS Windows
      tt=winqueryreg('HKEY_CURRENT_USER','Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders','Personal');
      if isempty(tt) tt=winqueryreg('HKEY_CURRENT_USER','Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','Personal'); end;
      if ~isempty(tt) tt=fullfile(tt,'Pipeline'); end;
    elseif ismac
      %TODO: How to get the same as xdg-user-dir in Mac OS-X
    elseif isunix 
      [st,tt]=system('xdg-user-dir DOCUMENTS');
      if st==0 tt=fullfile(tt,'Pipeline'); else tt=''; end;
    end;
    if isempty(tt) tt=fullfile(getenv('HOME'),'Documents','Pipeline'); end;
    if exist(tt,'dir') tt={{tt}}; else tt={}; end;
  end;
  if ~isempty(tt)
    t.path=fullfile(tt{1}{1},'arabica');
    if exist(t.path,'dir')
      tp=dir(fullfile(t.path));
      if isempty(tp) tp={};
      else
        tp=tp([tp(:).isdir]);
        tp={tp.name};
        tp(strmatch('.',tp))=[];
        tp=horzcat({t.path},cellfun(@(x)fullfile(t.path,x),tp,'UniformOutput',false));
      end;
      while ~isempty(tp)
        dd=dir(fullfile(tp{1}));
        dd=dd([dd(:).isdir]);
        dd={dd.name};
        dd(strmatch('.',dd))=[];
        tp=horzcat(tp(1),cellfun(@(x)fullfile(tp{1},x),dd,'UniformOutput',false),tp(2:end));
        dd=dir(fullfile(tp{1},'*.pipe'));
        for i=1:numel(dd)
          fid=fopen(fullfile(tp{1},dd(i).name),'r','native','UTF-8');
          if fid~=-1
            temp=fread(fid,Inf,'*char').';
            fclose(fid);
          else temp='';
          end;
          tt=regexp(temp,'\s+location="pipeline://(.+?)/(.+?/arabica_wrapper\..+?)"','tokens');
          if ~isempty(tt)
            k=strmatch('personal',{t(:).name});
            k=k(strcmp(tt{1}{1},{t(k).server}));
            if isempty(k)
              t=horzcat(t,struct('name',{['personal:' tt{1}{1}]},'server',{tt{1}{1}},'path',{tp{1}},'wrapper',{tt{1}{2}},'funroll',{[]}));
            else
              if isempty(t(k(1)).path) t(k(1)).path=tp{1}; end;
              if isempty(t(k(1)).wrapper) t(k(1)).wrapper=tt{1}{2}; end;
            end;
            break;
          end;
        end;
        tp(1)=[];
      end;
    end;
    if isfield(conf,'core')&&isfield(conf.core,'libraries')
      for i=1:numel(t)
        if ~any(strcmp(t(i).name,{conf.core.libraries(:).name})) conf.core.libraries=horzcat(t(i),conf.core.libraries);
        elseif ~any(strcmp([t(i).name ':' t(i).server],{conf.core.libraries(:).name}))
          t(i).name=[t(i).name ':' t(i).server];
          conf.core.libraries=horzcat(conf.core.libraries,t(i));
        else
          j=find(strcmp(t(i).name,{conf.core.libraries(:).name}),1);
          if isempty(j) j=find(strcmp([t(i).name ':' t(i).server],{conf.core.libraries(:).name}),1); end;
          if isempty(conf.core.libraries(j).wrapper) conf.core.libraries(j).wrapper=t(i).wrapper; end;
        end;
      end;
    else conf.core.libraries=t;
    end;
  end;
  if exist(fullfile(fn,'libraryCache'),'dir')
    d=dir(fullfile(fn,'libraryCache'));
    if ~isempty(d) d=d([d(:).isdir]); end;
    for i=1:numel(d)
      tt=regexp(d(i).name,'^(.*?)\d*$','tokens');
      if (~isempty(tt))&&(~any(strcmp(tt{1}{1},{'.' '..'})))
        t=struct('name',{['personal:' tt{1}{1}]},'server',{tt{1}{1}},'path',{''},'wrapper',{''},'funroll',{[]});
        dd=dir(fullfile(fn,'libraryCache',d(i).name,'*.pipe'));
        for j=1:numel(dd)
          fid=fopen(fullfile(fn,'libraryCache',d(i).name,dd(j).name),'r','native','UTF-8');
          if fid~=-1
            temp=fread(fid,Inf,'*char').';
            fclose(fid);
          else temp='';
          end;
          tt=regexp(temp,sprintf('\\s+location="pipeline://%s/(.+?/arabica_wrapper\\..+?)"',t.server),'tokens');
          if ~isempty(tt)
            t.wrapper=tt{1}{1};
            break;
          end;
        end;
        if isfield(conf,'core')&&isfield(conf.core,'libraries')
          j=find(strcmp(t.name,{conf.core.libraries(:).name}),1);
          if isempty(j) conf.core.libraries=horzcat(conf.core.libraries,t);
          elseif isempty(conf.core.libraries(j).wrapper) conf.core.libraries(j).wrapper=t.wrapper;
          end;
        else conf.core.libraries=t;
        end;
      end;
    end;
  end;
  d=dir(fn);
  if ~isempty(d) d=d([d(:).isdir]); end;
  for i=1:numel(d)
    if ~any(strcmp(d(i).name,{'.' '..'}))
      if exist(fullfile(fn,d(i).name,'preferences.xml'),'file')
        fid=fopen(fullfile(fn,d(i).name,'preferences.xml'),'r','native','UTF-8');
        if fid~=-1
          temp=fread(fid,Inf,'*char').';
          fclose(fid);
        else temp='';
        end;
        t=struct('name',{'server'},'server',{''},'path',{''},'wrapper',{''},'funroll',{[]});
        tt=regexp(temp,'<Hostname(?:\s+\w+="[^"]*")*\s*>(.*?)</Hostname\s*>','tokens');
        if ~isempty(tt) t.server=tt{1}{1}; end;
        tt=regexp(temp,'<ServerLibraryLocation(?:\s+\w+="[^"]*")*\s*>(.*?)</ServerLibraryLocation\s*>','tokens');
        if ~isempty(tt)
          t.path=fullfile(tt{1}{1},'arabica');
          if exist(t.path,'dir')
            dd=dir(fullfile(t.path,'*.pipe'));
            for j=1:numel(dd)
              fid=fopen(fullfile(t.path,dd(j).name),'r','native','UTF-8');
              if fid~=-1
                temp=fread(fid,Inf,'*char').';
                fclose(fid);
              else temp='';
              end;
              tt=regexp(temp,sprintf('\\s+location="pipeline://%s/(.+?/arabica_wrapper\\..+?)"',t.server),'tokens');
              if ~isempty(tt)
                t.wrapper=tt{1}{1};
                break;
              end;
            end;
          end;
          if isfield(conf,'core')&&isfield(conf.core,'libraries')
            if ~any(strcmp(t.name,{conf.core.libraries(:).name})) conf.core.libraries=horzcat(conf.core.libraries,t);
            elseif ~any(strcmp([t.name ':' t.server],{conf.core.libraries(:).name}))
              t.name=[t.name ':' t.server];
              conf.core.libraries=horzcat(conf.core.libraries,t);
            end;
          else conf.core.libraries=t;
          end;
        end;
      end;
    end;
  end;
end;
if isfield(conf,'core')&&isfield(conf.core,'libraries')
  for i=1:numel(conf.core.libraries)
    if isempty(conf.core.libraries(i).server)
      j=find(strcmp(conf.core.libraries(i).wrapper,{conf.core.libraries(:).wrapper}));
      j=j(~strcmp({conf.core.libraries(j).server},''));
      if ~isempty(j) conf.core.libraries(i).server=conf.core.libraries(j(1)).server;
      else conf.core.libraries(i).server='localhost';
      end;
    end;
    if isempty(conf.core.libraries(i).name) conf.core.libraries(i).name=['personal:' conf.core.libraries(i).server]; end;
    if isempty(conf.core.libraries(i).path)
      j=find(strcmp('personal',{conf.core.libraries(:).name}),1);
      if ~isempty(j)
        if strcmp(conf.core.libraries(i).server,'localhost') conf.core.libraries(i).path=conf.core.libraries(j).path;
        else conf.core.libraries(i).path=fullfile(conf.core.libraries(j).path,conf.core.libraries(i).server);
        end;
      end;
    end;
    if isempty(conf.core.libraries(i).wrapper)
      j=find(strcmp(conf.core.libraries(i).server,{conf.core.libraries(:).server}));
      j=j(~strcmp({conf.core.libraries(j).wrapper},''));
      if ~isempty(j) conf.core.libraries(i).wrapper=conf.core.libraries(j(1)).wrapper;
      elseif ispc conf.core.libraries(i).wrapper=fullfile(pathname,'arabica_wrapper.bat');
      else conf.core.libraries(i).wrapper=fullfile(pathname,'arabica_wrapper.sh');
      end;
    end;
    if isempty(conf.core.libraries(i).funroll) conf.core.libraries(i).funroll=4; end;
  end;
end;

if nargout>0 out=conf;
else
  %TODO: Pretty-print config details
end;
