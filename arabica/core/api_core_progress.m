function [out,baseat,headat]=api_core_progress(varargin)
%API_CORE_PROGRESS Manipulate or query the progress stack.
%   %TODO: Write help text
%          () output the id of the currently default stack in the form '<name>'
%          ('<mode>',...) operate on the currently default stack
%          ('<id>','<mode>',...) operate on the stack with the given id where a
%          valid id has the form '<name>' meaning always the head or
%          '<name>:<level>' meaning the specified level
%          ('<id>','current') make the stack with the given id currently default
%          and output the the new current id
%
%          query modes that do not alter the currently default stack:
%          ('<id>') output same as ('<id>','state')
%          ('<id>','state') output or print the state of the head
%          ('<id>','head') output or print a snapshot of the head
%          ('<id>','log') output or print a snapshot of the stack
%
%          handler setup modes that do not alter the currently default stack:
%          ('<id>','addhandler',<handler>) add a new handler at the level of the
%          head and output the new name including any changes made to resolve
%          name clashes with existing handlers <handler> can be a handler
%          structure or @func handle or builtin names 'cli','log' or 'pipe'
%          ('<id>','addhandler',<handler>,<name>,<level>,<verb>,<args>) same as
%          above with additional customization details
%          ('<id>','rmhandler','<name>') remove the given handler
%
%          create and destroy modes that update the currently default stack:
%          ('<id>','new',...) create a new stack with given id and output the
%          new id including the level
%          ('<id>','sub',...) create a new sub stack level under the current
%          head or create a new stack and output the new id including the
%          new level
%          ('<id>','destroy') destroy the whole stack
%
%          active state modes that update the currently default stack:
%          ('<id>','run',...) update running state of the head
%          ('<id>','warning',...) insert warning message at the head
%          ('<id>','debug',...) insert debug message at the head
%
%          terminal state modes that update the currently default stack:
%          ('<id>','complete',...) terminate the running state of the head
%          normally
%          ('<id>','cancel',...) terminate the running state of the head without
%          reaching the end normally
%          ('<id>','error',...) terminate the running state of the head due to
%          an unrecoverable error
%
%          all the ('<id>','<mode>',...) functions above optionally accept:
%          (...,<curstep>,...) update current step value
%          (...,<curstep>,<totalstep>,...) update current and total step values
%          (...,'<message>',...) update the message
%          (...,<data>,...) update data
%          as long as they are in the order of 0-2 numbers followed by 0-1 str
%          and everything 0-N after that is consider data
%          note: if the first <data> is also str you must explicitly specify ''
%          for '<message>'
%
%          active states: new, sub, run, warning, debug
%          terminal states: complete, cancel, error
%          when querying the word ' (idle)' is appended to an active state that
%          has clearly been idle for a while
%
%          the idea is that a new message is only allowed if the current head
%          does not have sub levels or all sub levels are in a terminal state
%          also destroying is only allowed if the whole stack is in a terminal
%          state
%
%   See also API_CORE_WARNING, API_CORE_DEBUG, API_CORE_ERROR,
%   API_CORE_PERSISTENT, API_CORE_DURATION, CLOCK, CPUTIME, ETIME.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

atnow.clock=clock;
atnow.cpu=cputime;

persistent lastid;
if isempty(lastid)
  if ~mislocked mlock; end;
  lastid='';
end;

api_core_checknarg(0,3,0,Inf);
if ~isempty(varargin)
  [mode,lerr,lid]=api_core_checkopt(varargin{1},'MODE','current','state','head','log','addhandler','rmhandler','new','sub','destroy','run','warning','debug','complete','cancel','error');
  if isempty(lid) varargin(1)=[];
  else
    id=varargin{1};
    varargin(1)=[];
    if isempty(varargin) mode='state';
    else
      mode=api_core_checkopt(varargin{1},'MODE','current','state','head','log','addhandler','rmhandler','new','sub','destroy','run','warning','debug','complete','cancel','error');
      varargin(1)=[];
    end;
  end;
end;
if exist('id','var')
  api_core_checkarg(id,'ID','str');
  [id,idl]=strtok(id,':');
  if isempty(idl) idl=NaN;
  else
    idl=2*str2double(idl(2:end));
    if (idl<0)||(rem(idl,2)>0) error('API_CORE_PROGRESS:invalidInput','Invalid progress stack level.'); end;
  end;
else
  id=lastid;
  idl=NaN;
end;
caller=api_core_caller;

pg=api_core_persistent('get','progress');
if (nargin==0)||strcmp(mode,'current')
  if isempty(pg) res='';
  else
    if isempty(id)||isfield(pg,id) lastid=id;
    else error('API_CORE_PROGRESS:invalidInput','Invalid progress stack id.');
    end;
    res=lastid;
  end;
elseif isempty(id)&&(~any(strcmp(mode,{'new' 'sub'}))) error('API_CORE_PROGRESS:invalidInput','Invalid progress stack id.');
elseif strcmp(mode,'destroy')
  res=false;
  if (~isempty(pg))&&isfield(pg,id)
    sub=api_core_persistent('get','progress',id,pg.(id).head);
    if isempty(sub)||(~strcmp(sub.state,'sub'))||isempty(sub.sub) error('API_CORE_PROGRESS:invalidState','Invalid progress stack.'); end;
    head=sub.sub(end);
    if ~any(strcmp(head.state,{'complete' 'cancel' 'error'}))
      if all(strcmp(caller,{'core' ''})) warning('API_CORE_PROGRESS:invalidState','Destroying a non terminated stack.');
      else error('API_CORE_PROGRESS:invalidState','Cannot destroy a non terminated stack.');
      end;
    end;
    api_core_progress_call(pg.(id).handler,'remove',mode,id);
    api_core_persistent('clear','progress',id);
    if strcmp(lastid,id) lastid=''; end,
    res=true;
  end;
else
  cur=api_core_persistent('get','progress',id);
  if ~strcmp(mode,'new')
    if isfield(cur,'head')
      if isnan(idl) idl=length(cur.head);
      elseif idl>length(cur.head) error('API_CORE_PROGRESS:invalidInput','Invalid progress stack level.');
      end;
      realsub=api_core_persistent('get','progress',id,cur.head);
      if isempty(realsub)||(~strcmp(realsub.state,'sub'))||isempty(realsub.sub) error('API_CORE_PROGRESS:invalidState','Invalid progress stack.'); end;
      sub=api_core_persistent('get','progress',id,cur.head(1:idl));
      if isempty(sub)||(~strcmp(sub.state,'sub'))||isempty(sub.sub) error('API_CORE_PROGRESS:invalidState','Invalid progress stack.'); end;
      realhead=realsub.sub(end);
    elseif ~strcmp(mode,'sub') error('API_CORE_PROGRESS:invalidInput','Invalid progress stack id.');
    end;
  end;
  if any(strcmp(mode,{'state' 'head' 'log'}))
    res='error';
    resb=sub.sub(1).at;
    resh=realhead.at;
    if ~any(strcmp(realhead.state,{'complete' 'cancel' 'error'}))
      idle=api_core_duration(resh,atnow);
      %TODO: Maybe in the future make the threshold or whole decision better
      if idle.cpu<0.9 
          sub = subsasgn(sub,horzcat(cur.head((idl+1):end),struct('type',{'.' '()' '.'},'subs',{'sub' {length(realsub.sub)} 'state'})),[realhead.state ' (idle)']); 
      end;
    end;
    if strcmp(mode,'state') res=sub.sub(end).state;
    elseif strcmp(mode,'head') res=sub.sub(end);
    elseif strcmp(mode,'log') res=sub.sub;
    end;
  elseif any(strcmp(mode,{'addhandler' 'rmhandler'}))
    res=false;
    if strcmp(mode,'addhandler')
      handler.name='handler1';
      handler.func='';
      handler.args={};
      handler.verbosity={'sub' 'run' 'warning' 'complete' 'cancel' 'error'};
      handler.level=idl/2;
      if ~isempty(varargin)
        vm=api_core_checkarg(varargin{1},{'HANDLER' 'scalar struct';'FUNC' 'str';'FUNC' 'function'});
        if vm==1
          if (~(numel(fieldnames(varargin{1}))==5))||(~all(strcmp(sort(fieldnames(varargin{1})),sort({'name';'func';'args';'verbosity';'level'})))) error('API_CORE_PROGRESS:invalidInput','Not a valid handler structure.'); end;
          handler.name=varargin{1}.name;
          handler.func=varargin{1}.func;
          handler.args=varargin{1}.args;
          handler.verbosity=varargin{1}.verbosity;
          handler.level=varargin{1}.level;
        elseif vm==2
          vm=api_core_checkopt(varargin{1},'FUNC','cli','log','pipe','debug');
          handler.name=[vm '1'];
          if strcmp(vm,'cli') handler.func=@api_core_progress_cli;
          elseif strcmp(vm,'log') handler.func=@api_core_progress_log;
          elseif strcmp(vm,'pipe') handler.func=@api_core_progress_pipe;
          elseif strcmp(vm,'debug')
            handler.func=@api_core_progress_cli;
            handler.verbosity={'sub' 'run' 'warning' 'debug' 'complete' 'cancel' 'error'};
            handler.args={'keep'};
          end;
        else handler.func=varargin{1};
        end;
        varargin(1)=[];
        if ~isempty(varargin)
          vm=api_core_checkarg(varargin{1},{'NAME' 'str';'LEVEL' 'integer nonnegative'});
          if vm==1
            if ~isempty(varargin{1}) handler.name=varargin{1}; end;
            varargin(1)=[];
          end;
        end;
        if ~isempty(varargin)
          vm=api_core_checkarg(varargin{1},{'LEVEL' 'integer nonnegative';'VERBOSITY' 'str'});
          if vm==1
            if ~isempty(varargin{1}) handler.level=varargin{1}; end;
            varargin(1)=[];
          end;
        end;
        if ~isempty(varargin)
          api_core_checkarg(varargin{1},'VERBOSITY','str');
          for i=1:length(varargin{1}) api_core_checkopt(varargin{1}(i),'VERBOSITY','sub','run','warning','debug','complete','cancel','error'); end;
          if ~isempty(varargin{1}) handler.verbosity=varargin{1}; end;
          varargin(1)=[];
        end;
        if length(varargin)>1 handler.args=varargin;
        elseif length(varargin)==1 handler.args=varargin{1};
        end;
      end;
      while any(strcmp(handler.name,{cur.handler.name}))
        [handler.name,n]=strtok(handler.name,'1234567890');
        if isnan(str2double(n)) handler.name=[handler.name n '1'];
        else handler.name=sprintf('%s%i',handler.name,str2double(n)+1);
        end;
      end;
      cur.handler(end+1)=handler;
      api_core_persistent('set','progress',id,'handler',cur.handler);
      api_core_progress_call(handler,'add',mode,id);
      res=handler.name;
    else
      i=find(strcmp(name,{cur.handler.name}));
      if numel(i)==1
        handler=cur.handler(i);
        cur.handler(i)=[];
        api_core_persistent('set','progress',id,'handler',cur.handler);
        api_core_progress_call(handler,'remove',mode,id);
        res=true;
      elseif numel(i)>1 error('API_CORE_PROGRESS:invalidState','Invalid progress stack.');
      end;
    end;
  else
    if (~strcmp(mode,'new'))&&exist('sub','var')
      head=sub.sub(end);
      if any(strcmp(head.state,{'complete' 'cancel' 'error'})) error('API_CORE_PROGRESS:invalidState','Progress stack already terminated.');
      elseif (idl<length(cur.head))&&(~any(strcmp(realhead.state,{'complete' 'cancel' 'error'})))
        if all(strcmp(caller,{'core' ''})) warning('API_CORE_PROGRESS:invalidState','Continuing despite a non terminated sub stack.');
        else error('API_CORE_PROGRESS:invalidState','Cannot continue before terminating sub stack.');
        end;
      elseif strcmp(mode,'run')&&(~all(strcmp(caller,{sub.sub(1).caller.package sub.sub(1).caller.module})))
        %TODO: Maybe in the future think if this is always what we want
        if all(strcmp(caller,{'core' ''})) warning('API_CORE_PROGRESS:invalidState','Continuing a stack belonging to someone else.');
        else error('API_CORE_PROGRESS:invalidState','Cannot continue a stack belonging to someone else.');
        end;
      end;
      oldhead=horzcat(cur.head(1:idl),struct('type',{'.' '()'},'subs',{'sub' {length(sub.sub)}}));
      newhead=oldhead;
      newhead(end).subs{1}=newhead(end).subs{1}+1;
    end;
    new.state=mode;
    new.at.clock=atnow.clock;
    new.at.cpu=atnow.cpu;
    new.caller.package=caller{1};
    new.caller.module=caller{2};
    new.step.total=Inf;
    new.step.current=0;
    new.message='';
    new.data=[];
    new.sub=[];
    if strcmp(mode,'sub')
      newsub=new;
      newsub.state='new';
    end;
    if any(strcmp(mode,{'run' 'sub'}))&&exist('head','var')
      new.step=head.step;
      new.message=head.message;
    end;
    if ~isempty(varargin)
      vm=api_core_checkarg(varargin{1},{'MESSAGE' 'str';'CURSTEP' 'real nonnegative'});
      if vm==1
        new.message=varargin{1};
        varargin(1)=[];
      elseif vm==2
        new.step.current=varargin{1};
        varargin(1)=[];
        if ~isempty(varargin)
          vm=api_core_checkarg(varargin{1},{'MESSAGE' 'str';'TOTALSTEP' 'real nonnegative'});
          if vm==1
            new.message=varargin{1};
            varargin(1)=[];
          elseif vm==2
            new.step.total=varargin{1};
            varargin(1)=[];
            if (~isempty(varargin))&&(ischar(varargin{1})||iscellstr(varargin{1}))
              new.message=varargin{1};
              varargin(1)=[];
            end;
          end;
        end;
      end;
      if numel(varargin)>1 new.data=varargin;
      elseif numel(varargin)==1 new.data=varargin{1};
      end;
    end;
    cidl=idl;
    if any(strcmp(mode,{'new' 'sub'}))
      if strcmp(mode,'new')||~isfield(cur,'head')
        cur(1).handler=struct('name',{},'func',{},'args',{},'verbosity',{},'level',{});
        cur(1).head=struct('type',{},'subs',{});
        cur(1).state='sub';
        cur(1).sub=new;
        if isempty(id) id='progress1'; end;
        if ~isempty(pg)
          while isfield(pg,id)
            [id,n]=strtok(id,'1234567890');
            if isnan(str2double(n)) id=[id n '1'];
            else id=sprintf('%s%i',id,str2double(n)+1);
            end;
          end;
        end;
        api_core_persistent('set','progress',id,cur);
        newhead=struct('type',{'.' '()'},'subs',{'sub' {1}});
        idl=0;
        cidl=0;
      end;
      if strcmp(mode,'sub')
        new.sub=newsub;
        api_core_persistent('set','progress',id,newhead,new);
        api_core_persistent('set','progress',id,'head',newhead);
        idl=length(newhead);
      end;
      base=new;
    elseif any(strcmp(mode,{'run' 'warning' 'debug' 'complete' 'cancel' 'error'}))
      if strcmp(mode,'run')&&strcmp(mode,head.state)&&isequal(new.caller,head.caller)&&(new.step.total==head.step.total)&&(new.step.current>=head.step.current)&&isequal(new.data,head.data) newhead=oldhead; end;
      api_core_persistent('set','progress',id,newhead,new);
      if any(strcmp(mode,{'complete' 'cancel' 'error'}))
        api_core_persistent('set','progress',id,'head',newhead(1:(end-4)));
        idl=max(0,length(newhead)-4);
      end;
      base=sub.sub(1);
    end;
    res=sprintf('%s:%i',id,idl/2);
    resb=base.at;
    resh=new.at;
    lastid=id;
    api_core_progress_call(cur.handler,'update',mode,id,cidl/2,new,cur);
  end;
end;

if nargout>0
  out=res;
  if exist('resb','var') baseat=resb; else baseat=[]; end;
  if exist('resh','var') headat=resh; else headat=[]; end;
else
  if nargin==0
    api_core_l10n('fprintf','Currently default progress stack is "%s".\n',lastid);
  elseif strcmp(mode,'state')
    %TODO: Maybe in the future show duration, time left and steps if applicable
    api_core_l10n('fprintf','Progress stack "%s" level %i started at %<datetime> in state "%s" since %<datetime>.\n\n',id,idl/2,resb.clock,res,resh.clock);
  elseif strcmp(mode,'head')
    api_core_l10n('fprintf','Progress stack "%s" level %i head:\n',id,idl/2);
    fprintf('    state: %s\n',res.state);
    api_core_l10n('fprintf','       at: %<datetime>\n',res.at.clock);
    fprintf('   caller: %s %s\n',res.caller.package,res.caller.module);
    if isinf(res.step.total) fprintf('  %i',res.step.current);
    else
      if res.step.total>1 fprintf('     step: %i/%i\n',res.step.current,res.step.total);
      elseif res.step.total>0 fprintf('     step: %3.1f%%\n',100*res.step.current/res.step.total);
      end;
    end;
    if ~isempty(res.message) fprintf('  message: %s\n',res.message); end;
    if ~isempty(res.data)
      sd=size(res.data);
      fprintf('     data: %i',sd(1));
      fprintf('x%i',sd(2:end));
      fprintf(' %s\n',class(res.data));
    end;
    if ~isempty(res.sub) fprintf('      sub: %i\n',length(res.sub)); end;
    fprintf('\n');
  elseif strcmp(mode,'log')
    api_core_l10n('fprintf','Progress stack "%s" level %i log:\n',id,idl/2);
    list={'  ' res};
    while ~isempty(list)
      lh=list{1};
      res=list{2};
      list(1:2)=[];
      for i=1:length(res)
        if ~isempty(res(i).sub)
          list={[lh ' '] res(i).sub lh res((i+1):end) list{:}};
          break;
        else
          api_core_l10n('fprintf','%s%s  %<datetime>  %s %s',lh,res(i).state,res(i).at,res(i).caller.package,res(i).caller.module);
          if isinf(res(i).step.total) fprintf('  %i',res(i).step.current);
          else
            if res(i).step.total>1 fprintf('  %i/%i',res(i).step.current,res(i).step.total);
            elseif res(i).step.total>0 fprintf('  %3.1f%%',100*res(i).step.current/res(i).step.total);
            end;
          end;
          if ~isempty(res(i).message) fprintf('  "%s"',res(i).message); end;
          fprintf('\n');
        end;
      end;
    end;
    fprintf('\n');
  end;
end;


function api_core_progress_call(func,cmd,mode,id,level,entry,cur)
%API_CORE_PROGRESS_CALL Call progress handlers.
%   %TODO: Write help text
%
%   See also API_CORE_PROGRESS_CLI, API_CORE_PROGRESS_LOG

if ~exist('entry','var') entry=struct([]); end;
if ~exist('cur','var') cur=struct([]); end;
for i=1:length(func)
  if exist('level','var') cl=level; else cl=func(i).level; end;
  if (cl>=func(i).level)&&(any(strcmp(mode,{'addhandler' 'rmhandler' 'destroy'}))||any(strcmp(mode,func(i).verbosity)))
    if isempty(cur) base=struct([]);
    else
      sub=api_core_persistent('get','progress',id,cur.head(1:(2*func(i).level)));
      base=sub.sub(1);
    end;
    if isempty(func(i).args) args={};
    elseif iscell(func(i).args) args=func(i).args;
    else args={func(i).args};
    end;
    %try func.func(cmd,mode,id,cl-func(i).level,entry,base,args{:}); catch end;
    func.func(cmd,mode,id,cl-func(i).level,entry,base,args{:}); %DEBUG
  end;
end;


function api_core_progress_cli(cmd,mode,id,level,entry,base,cls)
%API_CORE_PROGRESS_CLI Pretty-print messages to command-line.
%   %TODO: Write help text
%          input is 'keep' or 'clear' (default)
%
%   See also API_CORE_PROGRESS_CALL, API_CORE_PROGRESS_LOG,
%   API_CORE_PROGRESS_PIPE.

persistent lastmsg;
if isempty(lastmsg) lastmsg={}; end;

if strcmp(cmd,'add')
  %TODO: Maybe in the future support many overlapping adds
  lastmsg={};
elseif strcmp(cmd,'update')
  if ~exist('cls','var') cls='clear'; end;
  %if isempty(lastmsg) ul=1; else ul=level+2; end;
  msg='';
  if strcmp(mode,'debug') msg='Debug: ';
  elseif strcmp(mode,'warning') msg='Warning: ';
  elseif strcmp(mode,'cancel') msg='Cancel: ';
  elseif strcmp(mode,'error') msg='Error: ';
  end;
  if (entry.step.current>0)&&(entry.step.total>0)
    if isinf(entry.step.total) msg=[msg sprintf('%i ',entry.step.current)];
    else
      if entry.step.total>1 msg=[msg sprintf('%i/%i ',entry.step.current,entry.step.total)];
      else msg=[msg sprintf('%3.1f%% ',100*entry.step.current/entry.step.total)];
      end;
    end;
  end;
  msg=[repmat(' ',1,level) msg entry.message];
  if any(strcmp(mode,{'debug' 'warning' 'error'}))&&(~isempty(entry.data))
    st=entry.data;
    if iscell(st)&&(~isempty(st)) st=st{1}; end;
    if (~isempty(st))&&(isa(st,'MException')||(isstruct(st)&&isfield(st,'stack')))&&(~isempty(st.stack))
      if isstruct(st.stack)&&isfield(st.stack,'name')&&isfield(st.stack,'line')
        msg=[msg sprintf(' (<a href="matlab: opentoline(''%s'',%i,1)">%s at %i</a>)',st.stack(1).file,st.stack(1).line,st.stack(1).name,st.stack(1).line)];
      end;
    end;
  end;
  if ~isempty(msg) msg=[msg sprintf('\n')]; end;
  %TODO: Maybe in the future time left, etc...
  dur=[repmat(' ',1,level) api_core_l10n('sprintf','At: %<datetime>  Elapsed: %<duration>',entry.at,api_core_duration(base.at,entry.at))];
  if strcmp(cls,'keep')
    sr=sprintf(repmat('\b',1,numel(lastmsg)));
    if (level<=1)&&any(strcmp(mode,{'complete' 'cancel' 'error'}))
      dur=[dur sprintf('\n\n')];
      lastmsg='';
    else lastmsg=dur;
    end;
  else
    if isempty(lastmsg) lastmsg={}; end;
    l=0;
    for i=(level+1):(numel(lastmsg)-1) l=l+numel(lastmsg{i}); end;
    if ~isempty(lastmsg) l=l+numel(lastmsg{end}); end;
    sr=sprintf(repmat('\b',1,l));
    if (level<=1)&&any(strcmp(mode,{'complete' 'cancel' 'error'}))
      dur=[dur sprintf('\n\n')];
      lastmsg={};
    else
      if numel(lastmsg)>(level+2) lastmsg{(level+3):end}=[]; end;
      if any(strcmp(mode,{'debug' 'warning' 'error'})) lastmsg=horzcat(cell(1,level+1),dur);
      else lastmsg=horzcat(lastmsg(1:min(level,numel(lastmsg))),cell(1,max(0,level-numel(lastmsg))),msg,dur);
      end;
    end;
  end;
  if any(strcmp(mode,{'debug' 'warning' 'error'}))
    fprintf('%s',sr);
    fprintf(2,'%s',msg);
    fprintf('%s',dur);
  else fprintf('%s',[sr msg dur]);
  end;
elseif strcmp(cmd,'remove')
  %TODO: Maybe in the future support many overlapping removes
  lastmsg={};
end;


function api_core_progress_log(cmd,mode,id,level,entry,base,fn)
%API_CORE_PROGRESS_CLI Pretty-print messages to a log file.
%   %TODO: Write help text
%          input is log file name or '' which defaults to pwd/id.log
%
%   See also API_CORE_PROGRESS_CALL, API_CORE_PROGRESS_CLI,
%   API_CORE_PROGRESS_PIPE.

if strcmp(cmd,'add')
  %TODO: Maybe in the future cache fids
elseif strcmp(cmd,'update')
  if ~(exist('fn','var')) fn=fullfile(pwd,[id '.log']); end;
  fid=fopen(fn,'a');
  if fid~=-1
    msg='';
    if strcmp(mode,'debug') msg='Debug: ';
    elseif strcmp(mode,'warning') msg='Warning: ';
    elseif strcmp(mode,'cancel') msg='Cancel: ';
    elseif strcmp(mode,'error') msg='Error: ';
    end;
    if (entry.step.current>0)&&(entry.step.total>0)
      if isinf(entry.step.total) msg=[msg sprintf('%i ',entry.step.current)];
      else
        if entry.step.total>1 msg=[msg sprintf('%i/%i ',entry.step.current,entry.step.total)];
        else msg=[msg sprintf('%3.1f%% ',100*entry.step.current/entry.step.total)];
        end;
      end;
    end;
    if (~isempty(msg))||(~isempty(entry.message))||any(strcmp(mode,{'debug' 'warning' 'cancel' 'error'}))
      msg=[repmat(' ',1,level) msg entry.message];
      if any(strcmp(mode,{'debug' 'warning' 'error'}))&&(~isempty(entry.data))
        st=entry.data;
        if iscell(st)&&(~isempty(st)) st=st{1}; end;
        if (~isempty(st))&&(isa(st,'MException')||(isstruct(st)&&isfield(st,'stack')))&&(~isempty(st.stack))
          if isstruct(st.stack)&&isfield(st.stack,'name')&&isfield(st.stack,'line')
            msg=[msg sprintf(' (%s at %i)',st.stack(1).name,st.stack(1).line)];
          end;
        end;
      end;
      %TODO: Maybe in the future time left, etc...
      msg=[msg api_core_l10n('sprintf','  At: %<datetime>  Elapsed: %<duration>',entry.at,api_core_duration(base.at,entry.at))];
      fprintf(fid,'%s\n',msg);
    end;
    fclose(fid);
  end;
elseif strcmp(cmd,'remove')
  %TODO: Maybe in the future cache fids
end;


function api_core_progress_pipe(cmd,mode,id,level,entry,base)
%API_CORE_PROGRESS_PIPE Pretty-print messages to standard output.
%   %TODO: Write help text
%
%   See also API_CORE_PROGRESS_CALL, API_CORE_PROGRESS_CLI,
%   API_CORE_PROGRESS_LOG.

persistent lastmsg;
if isempty(lastmsg) lastmsg=''; end;

if strcmp(cmd,'add')
  %TODO: Maybe in the future support many overlapping adds
  lastmsg='';
elseif strcmp(cmd,'update')
  msg='';
  if strcmp(mode,'debug') msg='Debug: ';
  elseif strcmp(mode,'warning') msg='Warning: ';
  elseif strcmp(mode,'cancel') msg='Cancel: ';
  elseif strcmp(mode,'error') msg='Error: ';
  end;
  if (entry.step.current>0)&&(entry.step.total>0)
    if isinf(entry.step.total) msg=[msg sprintf('%i ',entry.step.current)];
    else
      if entry.step.total>1 msg=[msg sprintf('%i/%i ',entry.step.current,entry.step.total)];
      else msg=[msg sprintf('%3.1f%% ',100*entry.step.current/entry.step.total)];
      end;
    end;
  end;
  if (~isempty(msg))||(~isempty(entry.message))
    msg=[repmat(' ',1,level) msg entry.message];
    if any(strcmp(mode,{'debug' 'warning' 'error'}))&&(~isempty(entry.data))
      st=entry.data;
      if iscell(st)&&(~isempty(st)) st=st{1}; end;
      if (~isempty(st))&&(isa(st,'MException')||(isstruct(st)&&isfield(st,'stack')))&&(~isempty(st.stack))
        if isstruct(st.stack)&&isfield(st.stack,'name')&&isfield(st.stack,'line')
          msg=[msg sprintf(' (%s at %i)',st.stack(1).name,st.stack(1).line)];
        end;
      end;
    end;
    if isempty(lastmsg)||(~strcmp(msg,lastmsg))||any(strcmp(mode,{'debug' 'warning' 'cancel' 'error'}))
      lastmsg=msg;
      %TODO: Maybe in the future time left, etc...
      msg=[msg api_core_l10n('sprintf','  At: %<datetime>  Elapsed: %<duration>',entry.at,api_core_duration(base.at,entry.at))];
      if (level<=1)&&any(strcmp(mode,{'complete' 'cancel' 'error'})) msg=[msg sprintf('\n')]; end;
      fprintf('%s\n',msg);
      if any(strcmp(mode,{'debug' 'warning' 'cancel' 'error'})) fprintf(2,'%s\n',msg); end;
    end;
  end;
elseif strcmp(cmd,'remove')
  %TODO: Maybe in the future support many overlapping removes
  lastmsg='';
end;
