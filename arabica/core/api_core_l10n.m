function out=api_core_l10n(varargin)
%API_CORE_L10N Translate or manage translations.
%   %TODO: Write help text
%          () outputs current locale
%          (<txt>) outputs txt translated to current locale
%          ('fprintf',...) works just like fprintf but the format string is also
%          translated to current locale
%          ('sprintf',...) works just like sprintf but the format string is also
%          translated to current locale
%          ('translate',<txt>) outputs txt translated to current locale
%          ('translate',<txt>,'<locale>') outputs txt translated to given locale
%          ('file',<path>) outputs current locale version of file path
%          ('file',<path>,'<locale>') outputs given locale version of file path
%          ('time',<date>) outputs current locale version time
%          ('time',<date>,'<locale>') outputs given locale version time
%          ('date',<date>) outputs current locale version date
%          ('date',<date>,'<locale>') outputs given locale version date
%          ('datetime',<date>) outputs current locale version date and time
%          ('datetime',<date>,'<locale>') outputs given locale version date and
%          time
%          ('duration',<date>) outputs current locale version duration
%          ('duration',<date>,'<locale>') outputs given locale version duration
%          ('decimal',<float>) outputs current locale version of decimal number
%          ('decimal',<float>,'<locale>') outputs given locale version of
%          decimal number
%          ('ordinal',<integer>) outputs current locale version of integer
%          ordinal
%          ('ordinal',<integer>,'<locale>') outputs given locale version of
%          integer ordinal
%          ('list','current') outputs current locale
%          ('list','locales') outputs all known locales
%          ('list','strings','<locale>') outputs all known translations in given
%          locale
%
%          all inputs can be arrays or cells with any number of elements
%          for text and path the output will be in the same format and for other
%          modes the output will always be a single or cell string
%          date format can be date vec or at structure for other than duration
%          also serial date
%          empty locale means current one
%          if the translation text or file path for target locale is not known
%          returns the input unchanged
%
%          translations used when calling from for file <name>.* are defined in
%          files named <name>_<locale>.lang
%
%          note: not fully implemented yet meaning that:
%          it will always simply return what ever you give it to translate and
%          reports the builtin 'en' as the current locale
%          list will always list the builtin 'en' as the only known locale and
%          an empty list as the known translations
%
%   See also API_CORE_DURATION, DATESTR, DATENUM, DATEVEC, SPRINTF, FPRINTF.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

%TODO: The whole translation process should be compatible with GNU gettext
%TODO: Maybe in the future actually implement many locales
%TODO: Maybe in the future support the GNU gettext Python standard
persistent locs;
if isempty(locs)
  locs.name='en';
  locs.decimal='.';
  locs.date={13 1 0};
  locs.duration={'y' 'mo' 'd' 'h' 'm' 's'};
  locs.ordinal={'th' 'st' 'nd' 'rd' 'th' 'th' 'th' 'th' 'th' 'th'};
end;

api_core_checknarg(0,1,0,Inf);

if nargin==1
  mode='translate';
  loc='';
  in=varargin{1};
elseif nargin>1
  mode=api_core_checkopt(varargin{1},'MODE','fprintf','sprintf','translate','file','time','date','datetime','duration','decimal','ordinal','list');
  varargin(1)=[];
  if any(strcmp(mode,{'fprintf','sprintf'})) loc='';
  else
    in=varargin{1};
    varargin(1)=[];
    if nargin>2
      loc=varargin{1};
      varargin(1)=[];
    else loc='';
    end;
  end;
elseif nargin==0
  mode='list';
  in='current';
  loc='';
end;

if isempty(loc) loc='en';
else api_core_checkopt(loc,'LOCALE',{locs.name});
end;
loc=locs(find(strcmp(loc,{locs.name}),1));

if any(strcmp(mode,{'fprintf','sprintf'}))
  in='';
  if ~isempty(varargin)
    if isnumeric(varargin{1})
      fid=varargin{1};
      varargin(1)=[];
    end;
    if ~isempty(varargin)
      in=varargin{1};
      varargin(1)=[];
    end;
    if ~isempty(in)
      pre=regexp(in,'^(\\[nrtbf]|\s)*','tokens');
      if iscell(pre) pre=horzcat(pre{:}); end;
      if iscell(pre) pre=horzcat(pre{:}); end;
      in(1:length(pre))=[];
      post=regexp(in,'(\\[nrtbf]|\s)*$','tokens');
      if iscell(post) post=horzcat(post{:}); end;
      if iscell(post) post=horzcat(post{:}); end;
      in((end+1-length(post)):end)=[];
      in=strrep(in,'$','$$');
      m=regexp(in,'(?<!%)(%(<(translate|file|time|date|datetime|duration|decimal|ordinal)>|[-+ 0]?[1234567890.]*[bt]?[diouxXfeEgGcs]))','tokenExtents');
      if ~isempty(m)
        f=cellfun(@(i)in(i(1):i(2)),m,'UniformOutput',false);
        for i=length(f):-1:1
          in=[in(1:(m{i}(1)-1)) sprintf('$%i',i) in((m{i}(2)+1):end)];
          fm=regexp(f{i},'^%<(?<mode>\w+)>$','names');
          if numel(fm)==1
            f{i}='%s';
            if length(varargin)>=i varargin{i}=api_core_l10n(fm.mode,varargin{i}); end;
          end;
        end;
        m=regexp(in,'("\$\d+")','tokenExtents');
        for i=length(m):-1:1
          fm=str2double(in((m{i}(1)+2):(m{i}(2)-1)));
          f{fm}=['"' f{fm} '"'];
          in(m{i})=[];
        end;
        %TODO: Maybe in the future actually implement the translation here as in=translated(in)
        m=regexp(in,'(?<!\$)(\$\d+)','tokenExtents');
        fm=cellfun(@(i)str2double(in((i(1)+1):i(2))),m);
        for i=length(fm):-1:1 in=[in(1:(m{i}(1)-1)) f{fm(i)} in((m{i}(2)+1):end)]; end;
        varargin=varargin(fm);
      end;
      in=strrep(in,'$$','$');
      in=[pre in post];
    end;
    if strcmp(mode,'fprintf')
      if exist('fid','var') fprintf(fid,in,varargin{:}); else fprintf(in,varargin{:}); end;
    else out=sprintf(in,varargin{:});
    end;
  end;
elseif strcmp(mode,'translate')
  if ischar(in) txt=cellstr(in);
  elseif iscellstr(in) txt=in;
  else error('API_CORE_L10N:invalidInput','The TXT must be char or cell array of strings.');
  end;
  out=cell(size(txt));
  for i=1:length(txt)
    t=strrep(txt{i},'%','%%');
    t=strrep(t,'\','\\');
    t=api_core_l10n('sprintf',t);
    t=strrep(t,'\\','\');
    out{i}=strrep(t,'%%','%');
  end;
  if ischar(in) out=char(out);
  elseif numel(out)==1 out=out{1};
  end;
elseif strcmp(mode,'file')
  if ischar(in) txt=cellstr(in);
  elseif iscellstr(in) txt=in;
  else error('API_CORE_L10N:invalidInput','The PATH must be char or cell array of strings.');
  end;
  out=cell(size(txt));
  for i=1:length(txt)
    % [pathname,name,ext,v]=fileparts(txt{i});
    [pathname,name,ext]=fileparts(txt{i});
    fn=fullfile(pathname,[name '_' loc.name '.lang']);
    if exist(fn,'file') out{i}=fn; else out{i}=txt{i}; end;
  end;
  if ischar(in) out=char(out);
  elseif numel(out)==1 out=out{1};
  end;
elseif any(strcmp(mode,{'time','date','datetime'}))
  %TODO: Maybe in the future more type safe
  f=loc.date{strcmp(mode,{'time','date','datetime'})};
  if isstruct(in) in=vertcat(in.clock); end;
  if iscell(in)
    out=cell(size(in));
    for i=1:numel(in)
      if isstruct(in{i}) out{i}=datestr(vertcat(in{i}.clock),f);
      else out{i}=datestr(in{i},f);
      end;
    end;
    if numel(out)==1 out=out{1}; end;
  else out=datestr(in,f);
  end;
elseif strcmp(mode,'duration')
  %TODO: Maybe in the future more type safe
  if isstruct(in) dur=vertcat(in.clock); else dur=in; end;
  out=cell(1,size(in,1));
  for i=1:size(dur,1)
    s='';
    if dur(1)>0 s=[s sprintf(' %i%s',dur(1),loc.duration{1})]; end;
    if dur(2)>0 s=[s sprintf(' %i%s',dur(2),loc.duration{2})]; end;
    if dur(3)>0 s=[s sprintf(' %i%s',dur(3),loc.duration{3})]; end;
    if dur(4)>0 s=[s sprintf(' %i%s',dur(4),loc.duration{4})]; end;
    if dur(5)>0 s=[s sprintf(' %i%s',dur(5),loc.duration{5})]; end;
    if dur(6)>0 s=[s sprintf(' %.3f%s',dur(6),loc.duration{6})]; end;
    if isstruct(in) s=[s sprintf(' (CPU: %.0f%%)',100*in(i).cpu)]; end;
    out{i}=s(2:end);
  end;
  if numel(out)==1 out=out{1}; end;
elseif strcmp(mode,'decimal')
  %TODO: Maybe in the future more type safe
  out=cell(size(in));
  for i=1:numel(in)
    if iscell(in) out{i}=sprintf('%f',in{i}); else out{i}=sprintf('%f',in(i)); end;
    out{i}=strrep(out{i},'.',loc.decimal);
  end;
  if numel(out)==1 out=out{1}; end;
elseif strcmp(mode,'ordinal')
  %TODO: Maybe in the future more type safe
  out=cell(size(in));
  for i=1:numel(in)
    if iscell(in) out{i}=sprintf('%i%s',in{i},loc.ordinal{1+rem(in{i},10)});
    else out{i}=sprintf('%i%s',in(i),loc.ordinal{1+rem(in(i),10)});
    end;
  end;
  if numel(out)==1 out=out{1}; end;
elseif strcmp(mode,'list')
  w=api_core_checkopt(in,'WHAT','current','locales','strings');
  if strcmp(w,'current')
    if nargout>0 out=loc.name;
    else api_core_l10n('fprintf','Current locale is: %s\n',loc.name);
    end;
  elseif strcmp(w,'locales')
    if nargout>0 out={locs.name};
    else
      fprintf(api_core_l10n('Known locales are:\n'));
      fprintf('  %s',locs(1).name);
      if size(locs,1)>1 fprintf(', %s',{locs(2:end).name}); end;
      fprintf('\n');
    end;
  elseif strcmp(w,'strings')
    if nargout>0 out={};
    else
      api_core_l10n('fprintf','Known translations for locale %s are:\n',loc.name);
      %TODO: Maybe in the future actually implement proper listing
      fprintf('  <none>\n');
    end;
  end;
end;
