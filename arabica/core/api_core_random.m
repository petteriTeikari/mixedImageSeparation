function out=api_core_random(in)
%API_CORE_RANDOM Easily reset the default random generators.
%   API_CORE_RANDOM(SEED) resets the default generators based on the given
%   SEED as an integer.
%
%   API_CORE_RANDOM(RANDSTREAM) sets the given RandStream instance as the
%   default generator.
%
%   OUT = API_CORE_RANDOM(RANDSTREAM) also returns the previous default
%   RandStream instance.
%
%   API_CORE_RANDOM(STATE) resets the given state of either legacy RAND,
%   RANDN or RandStream instance.
%
%   OUT = API_CORE_RANDOM only returns current state of the default
%   generators without altering them.
%
%   OUT = API_CORE_RANDOM(...) always returns the previous state before
%   altering them.
%
%   OUT=API_CORE_RANDOM(SEED) for a string SEED returns an integer seed
%   value based on a hash of the string. If SEED is a filepath, only the
%   filename part is used in reverse order. This does not alter the default
%   generators.
%
%   NOTE: To make sure that Matlab does not randomly switch between legacy
%   and post 7.6 modes, it is important that the default random generators
%   are not altered with other functions between calling the default RAND,
%   RANDN, RANDI and RANDPERM.
%
%   Example:
%     API_CORE_RANDOM(0)
%
%   See also RAND, RANDSTREAM, MODULE_CORE.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,1,0,1);

if exist('RandStream','class')
  s=RandStream.getDefaultStream;
  res=struct('type',{s.Type},'seed',{s.Seed},'state',{s.State});
else res=struct('type','legacy','seed',{{rand('seed') randn('seed')}},'randn',{{rand('state') randn('state')}});
end;
if nargin>0
  mode=api_core_checkarg(in,{'SEED' 'str';'SEED' 'scalar integer';'RANDSTREAM' 'scalar RandStream';'STATE' 'scalar struct'});
  if mode==1
    in=char(in);
    t=regexp(in,'^.*(??@filesep)(.*?)\.\D*?$','tokens');
    if numel(t)==1 in=fliplr(t{1}{1}); end;
    t=5381;
    for i=1:length(in) t=mod(bitxor(33*t,double(in(i))),double(intmax('uint32'))+1); end;
    res=t;
  elseif mode==2
    if exist('RandStream','class')
      s=RandStream.create('mt19937ar','seed',in);
      RandStream.setDefaultStream(s);
    else
      rand('seed',in);
      randn('seed',in);
    end;
  elseif mode==3 RandStream.setDefaultStream(in);
  elseif mode==4
    if (numel(fieldnames(in))~=3)||(~all(strcmp(sort(fieldnames(in)),sort({'type';'seed';'state'})))) error('API_CORE_RANDOM:invalidInput','Input argument STATE must be a valid state structure.'); end;
    if strcmp(in.type,'legacy')&&iscell(in.seed)&&(numel(in.seed)==2)&&iscell(in.state)&&(numel(in.state)==2)
      rand('seed',in.seed{1});
      rand('state',in.state{1});
      randn('seed',in.seed{2});
      randn('state',in.state{2});
    else
      s=RandStream.getDefaultStream;
      if strcmp(s.Type,in.type)&&(s.Seed==in.seed) s.State=in.state;
      else
        s=RandStream.create(in.type,'seed',in.seed);
        s.State=in.state;
      end;
    end;  
  end;
else
end;

if nargout>0 out=res; end;
