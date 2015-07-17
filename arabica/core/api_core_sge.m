function out=api_core_sge(mode)
%API_CORE_SGE Returns information about Sun Grid Engine (SGE).
%   OUT = API_CORE_SGE returns a logical indicating wheather the code is
%   currently been executed under Sun Grid Engine.
%
%   OUT = API_CORE_SGE(MODE) returns the requested information about the
%   SGE environment or [] when not running under SGE. For MODE 'sge'
%   behaves like when called without MODE.
%
%   API_CORE_SGE(...) prints the information instead of returning it.
%
%   The following values for MODE are defined:
%
%   API_CORE_SGE('job') returns the following structure when inside SGE:
%     OUT.id         = JOB_ID
%     OUT.name       = JOB_NAME
%     OUT.queue      = QUEUE
%     OUT.parallel   = PE
%     OUT.hosts      = NHOSTS
%     OUT.queues     = NQUEUES
%     OUT.slots      = NSLOTS
%     OUT.restarted  = RESTARTED
%     OUT.checkpoint = SGE_CKPT_ENV
%
%   API_CORE_SGE('task') returns the following structure when inside SGE:
%     OUT.id    = SGE_TASK_ID
%     OUT.first = SGE_TASK_FIRST
%     OUT.step  = SGE_TASK_STEPSIZE
%     OUT.last  = SGE_TASK_LAST
%
%   API_CORE_SGE('node') returns the following structure when inside SGE:
%     OUT.host = HOSTNAME
%     OUT.arch = SGE_ARCH
%     OUT.tz   = TZ
%  
%   API_CORE_SGE('path') returns the following structure when inside SGE:
%     OUT.stdin      = SGE_STDIN_PATH
%     OUT.stdout     = SGE_STDOUT_PATH
%     OUT.stderr     = SGE_STDERR_PATH
%     OUT.temp       = TMPDIR
%     OUT.parallel   = PE_HOSTFILE
%     OUT.checkpoint = SGE_CKPT_DIR
%     OUT.sge        = SGE_BINARY_PATH
%     OUT.path       = PATH
%
%   API_CORE_SGE('user') returns the following structure when inside SGE:
%     OUT.login = USER
%     OUT.home  = HOME
%     OUT.shell = SHELL
%
%   Example:
%     JOB = API_CORE_SGE('job');
%
%   See also API_CORE_PARSECLI.

% Copyright © 2007-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,1);
if exist('mode','var') mode=api_core_checkopt(mode,'INFO','sge','job','task','node','path','user'); else mode='sge'; end;
res=strcmp(getenv('ENVIRONMENT'),'BATCH');

if res
  if ~strcmp(mode,'sge') res=[]; end;
  if strcmp(mode,'job')
    res.id=sscanf(getenv('JOB_ID'),'%d',1);
    res.name=getenv('JOB_NAME');
    res.queue=getenv('QUEUE');
    res.parallel=getenv('PE');
    res.hosts=sscanf(getenv('NHOSTS'),'%d',1);
    res.queues=sscanf(getenv('NQUEUES'),'%d',1);
    res.slots=sscanf(getenv('NSLOTS'),'%d',1);
    res.restarted=logical(sscanf(getenv('RESTARTED'),'%d',1));
    res.checkpoint=getenv('SGE_CKPT_ENV');
  elseif strcmp(mode,'task')
    res.id=sscanf(getenv('SGE_TASK_ID'),'%d',1);
    res.first=sscanf(getenv('SGE_TASK_FIRST'),'%d',1);
    res.step=sscanf(getenv('SGE_TASK_STEPSIZE'),'%d',1);
    res.last=sscanf(getenv('SGE_TASK_LAST'),'%d',1);
  elseif strcmp(mode,'node')
    res.host=getenv('HOSTNAME');
    res.arch=getenv('SGE_ARCH');
    res.tz=getenv('TZ');
  elseif strcmp(mode,'path')
    res.stdin=getenv('SGE_STDIN_PATH');
    res.stdout=getenv('SGE_STDOUT_PATH');
    res.stderr=getenv('SGE_STDERR_PATH');
    res.temp=getenv('TMPDIR');
    res.parallel=getenv('PE_HOSTFILE');
    res.checkpoint=getenv('SGE_CKPT_DIR');
    res.sge=getenv('SGE_BINARY_PATH');
    %TODO: Maybe in the future split path string into cellstr list
    res.path=getenv('PATH');
  elseif strcmp(mode,'user')
    res.login=getenv('USER');
    res.home =getenv('HOME');
    res.shell=getenv('SHELL');
  end;
elseif ~strcmp(mode,'sge') res=[];
end;

if nargout>0 out=res;
else
  if strcmp(mode,'sge')
    if res api_core_l10n('fprintf','Running under Sun Grid Engine.\n');
    else api_core_l10n('fprintf','Not running under Sun Grid Engine.\n');
    end;
  elseif strcmp(mode,'job')
    %TODO: Pretty-print values
  elseif strcmp(mode,'task')
    %TODO: Pretty-print values
  elseif strcmp(mode,'node')
    %TODO: Pretty-print values
  elseif strcmp(mode,'path')
    %TODO: Pretty-print values
  elseif strcmp(mode,'user')
    %TODO: Pretty-print values
  end;
end;
