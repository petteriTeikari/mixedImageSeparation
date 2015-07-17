function [outat,outs]=api_core_duration(at1,at2)
%API_CORE_DURATION Calculate elapsed time.
%   %TODO: Write help text
%          () output the at structure of now
%          (<atstart>) output or print the duration between now and the given
%          start at structure
%          (<atstart>,<atend>) output or print the duration between end at and
%          start at structures
%
%          the output duration is also an at structure but instead of absolute
%          values contains the relative elapsed time
%          [dur,str]= also outputs the same duration as a string formatted
%          according to current locale
%
%   See also API_CORE_PROGRESS, API_CORE_L10N, CLOCK, CPUTIME, ETIME.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

atnow.clock=clock;
atnow.cpu=cputime;

api_core_checknarg([0 1 0 0;0 2 1 2]);
if exist('at1','var') api_core_checkarg(at1,'START','scalar struct'); end;
if exist('at2','var') api_core_checkarg(at2,'END','scalar struct'); end;
%TODO: Maybe in the future make struct fields type safe too
if nargin==0 atdur=atnow;
elseif nargin==1 at2=atnow;
end;

if nargin>0
  ss=etime(at2.clock,at1.clock);
  if ss<0 error('API_CORE_DURATION:invalidInput','Duration cannot be negative.'); end;
  atdur.clock=zeros(1,6);
  if ss==0 atdur.cpu=0; else atdur.cpu=(at2.cpu-at1.cpu)/ss; end;

  yy=at2.clock(1)-at1.clock(1);
  mm=at2.clock(2)-at1.clock(2);
  if mm<0
    yy=yy-1;
    mm=12+mm;
  end;
  dd=at2.clock(3)-at1.clock(3);
  if (dd<0)||((dd==0)&&(sum(at2.clock(4:6)-at1.clock(4:6))<0))
    mm=mm-1;
    dd=fix(ss/86400);
  end;
  hh=mod(fix(ss/3600),24);
  mi=mod(fix(ss/60),60);
  si=mod(ss,60);
  atdur.clock=[yy mm dd hh mi si];
end;

if nargout>0
  outat=atdur;
  if exist('outs','var') outs=api_core_l10n('duration',atdur); end;
else
  if nargin>0 api_core_l10n('fprintf','Elapsed time: %<duration>\n\n',atdur);
  else api_core_l10n('fprintf','Now: %<datetime>\n\n',atdur);
  end;
end;
