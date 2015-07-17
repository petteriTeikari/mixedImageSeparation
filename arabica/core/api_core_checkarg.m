function [opt,err,id]=api_core_checkarg(arg,varargin)
%API_CORE_CHECKARG Check validity of input argument.
%   API_CORE_CHECKARG(ARG, NAME, CLASS) for a string CLASS checks whether the
%   argument ARG belongs to the class CLASS. If not, API_CORE_CHECKARG issues
%   a formatted error message using NAME.
%
%   API_CORE_CHECKARG(ARG, NAME, CLASS) for a cell array of strings CLASS
%   checks whether the argument ARG belongs to all the classes in
%   CLASS. If not, API_CORE_CHECKARG issues a formatted error message using
%   NAME.
%
%   API_CORE_CHECKARG(ARG, VALID) for a Nx2 cell array VALID checks according
%   to each row {NAME CLASS} of cell array VALID.
%
%   API_CORE_CHECKARG(ARG) checks whether the argument ARG evaluates
%   succesfully with if.
%
%   API_CORE_CHECKARG by itself lists the supported strings for CLASS. In
%   addition all strings accepted by the builtin function ISA are
%   also supported.
%
%   OPT = API_CORE_CHECKARG(...) returns the index of the succesful match.
%   0 or 1 for the API_CORE_CHECKARG(ARG, NAME, CLASS) version and from
%   0 to N for the API_CORE_CHECKARG(ARG, VALID) version.
%
%   [OPT, ERR] = API_CORE_CHECKARG(...) does not issue a formatted error
%   message. Instead it returns the error message in ERR.
%
%   [OPT, ERR, ID]=API_CORE_CHECKARG(...) does not issue a formatted error
%   message. Instead it returns the error message in ERR and the
%   error id in ID.
%
%   Example:
%     API_CORE_CHECKARG(in1, 'A', 'numeric')
%
%   See also API_CORE_CHECKNARG, API_CORE_CHECKOPT, ISA, VARARGIN,
%   VARARGOUT.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

persistent classes;
if isempty(classes)
  classes=initclasses;
  if ~mislocked mlock; end;
end;

lid='';
lerr={};
lopt=0;

try
  if nargin==1
    if arg lopt=1; else lopt=0; end;
  elseif (nargin==2)||(nargin==3)
    if nargin==2 opts=varargin{1};
    else opts={varargin{1} varargin{2}};
    end;
    for i=1:size(opts,1)
      valid=1;
      argname=opts{i,1};
      class=opts{i,2};
      if ischar(class) class=strread(class,'%s'); end;
      for j=1:length(class)
        name=lower(class{j});
        if isempty(name)||strcmpi(name,'any') continue; end;
        try test=classes.(name); catch test=[]; end;
        if regexp(name,'^(n|\d+)(x(n|\d+))*$') sizes=str2num(strrep(strrep(name,'n','NaN'),'x',' ')); else sizes=[]; end;
        if regexp(name,'^\d+d$') dims=str2num(name(1:end-1)); else dims=[]; end;
        if ~isempty(test)
          try valid=feval(test.isa,arg); catch valid=0; end;
          if ~valid
            %TODO: Build better error msg
            lerr{end+1}=sprintf('Input argument %s must be %s.',argname,name);
            break;
          end;
        elseif ~isempty(sizes)
          try
            vs=size(arg);
            valid=(ndims(arg)==numel(sizes))&&(isequal(vs(~isnan(sizes)),sizes(~isnan(sizes))));
          catch valid=0;
          end;
          if ~valid
            %TODO: Build better error msg
            lerr{end+1}=sprintf('Input argument %s must be of size %s.',argname,name);
            break;
          end;
        elseif ~isempty(dims)
          try valid=(ndims(arg)==dims); catch valid=0; end;
          if ~valid
            %TODO: Build better error msg
            lerr{end+1}=sprintf('Input argument %s must have dimensionality %s.',argname,name);
            break;
          end;
        else
          try valid=isa(arg,class{j}); catch valid=0; end;
          if ~valid
            %TODO: Build better error msg
            lerr{end+1}=sprintf('Input argument %s must be class %s.',argname,class{j});
            break;
          end;
        end;
      end;
      if valid
        lopt=i;
        break;
      end;
    end;
  elseif nargin==0
    %TODO: Print additional help like the classes.fieldnames
    class=sort(fieldnames(classes));
    if rem(length(class),3) class{end+1}=''; end;
    if rem(length(class),3) class{end+1}=''; end;
    fprintf('\n API_CORE_CHECKARG supports the following strings as classes:\n\n');
    for i=1:length(class)/3
      fprintf('    %s   %s   %s\n',class{3*i-2,:},class{3*i-1,:},class{3*i,:});
    end;
    fprintf('\n The following special strings are defined:\n\n');
    fprintf('    1d, 2d, 3d, ..., Nd\n');
    fprintf('    0x0, 0x1, ..., MxNxPx...\n');
    fprintf('\n Additionally, all strings accepted by the builtin\n function ISA are also supported.\n\n');
    return;
  elseif nargin>3 error('API_CORE_CHECKARG:invalidInput','Too many input arguments.');
  end;
catch err
  if isempty(err.identifier)||isempty(strmatch(err.identifier,'API_CORE_CHECKARG'))
    if nargin==1
      error('API_CORE_CHECKARG:invalidInput','Argument ARG can not be checked with if.');
    elseif nargin==2
      %TODO: Better error analysis
      error('API_CORE_CHECKARG:invalidInput','Invalid 1 or 2 input argument(s).');
    elseif nargin==3
      %TODO: Better error analysis
      error('API_CORE_CHECKARG:invalidInput','Invalid 1-3 input argument(s).');
    else error('API_CORE_CHECKARG:invalidInput','Invalid input argument(s).');
    end;
  else rethrow(err);
  end;
end;

if lopt==0
  %TODO: Select best matching error msg instead of concat
  temp=lerr;
  lerr=temp{1};
  if length(temp)>1 lerr=[lerr sprintf('\nOR\n    %s',temp{2:end})]; end;
  st=dbstack(1);
  if isempty(st) name='API_CORE_CHECKARG';
  else name=upper(st(1).name);
  end;
  if isempty(lid) lid='invalidInput'; end;
  lid=[name ':' lid];
end;

[opt,err,id]=deal(lopt,lerr,lid);
if (nargout<=1)&&(lopt==0)
  cerr.message=lerr;
  cerr.identifier=lid;
  cerr.stack=st;
  lasterror(cerr);
  rethrow(cerr);
elseif nargout>3 error('API_CORE_CHECKARG:invalidOutput','Too many output arguments.');
end;


function classes=initclasses
%INITCLASSES Build valid classes structure.

% These are tested with the builtin isa() function:
%   int8
%   uint8
%   int16
%   uint16
%   int32
%   uint32
%   single
%   double
%   numeric
%   logical
%   char
%   cell
%   struct
%   function_handle
%   <class_name>

% These are tested as a special case:
%   '', any
%   1d, 2d, 3d, ..., Nd
%   0x0, 0x1, ..., MxNxPx...

% These are tested as defined here:
%TODO: Upgrade these into the newer way of defining inlines
classes.busday.isa=@isbusday;
classes.bw.isa=@isbw;
classes.cellstr.isa=@iscellstr;
classes.cvar.isa=@iscvar;
classes.dir.isa=@isdir;
classes.empty.isa=@isempty;
classes.finite.isa=inline('~any(~isfinite(x(:)));');
classes.nonfinite.isa=inline('~any(isfinite(x(:)));');
classes.fis.isa=@isfis;
classes.global.isa=@isglobal;
classes.gray.isa=@isgray;
classes.handle.isa=inline('~any(~ishandle(x(:)));');
classes.ind.isa=@isind;
classes.inf.isa=inline('~any(~isinf(x(:)));');
classes.java.isa=@isjava;
classes.keyword.isa=@iskeyword;
classes.letter.isa=inline('~any(~isletter(x(:)));');
classes.nan.isa=inline('~any(~isnan(x(:)));');
classes.object.isa=@isobject;
classes.pref.isa=@ispref;
classes.prime.isa=inline('~any(~isprime(x(:)));');
classes.primitive.isa=inline('~any(~isprimitive(x));');
classes.real.isa=inline('~any(~isreal(x(:)));');
classes.reserved.isa=@isreserved;
classes.rgb.isa=@isrgb;
classes.sorted.isa=inline('~any(~issorted(x));');
classes.space.isa=inline('~any(~isspace(x(:)));');
classes.sparse.isa=@issparse;
classes.trellis.isa=@istrellis;
classes.varname.isa=@isvarname;
classes.function.isa=inline('isa(x,''function_handle'');');
classes.matrix.isa=inline('isnumeric(x)&&(ndims(x)==2);');
classes.vector.isa=inline('(ndims(x)==2)&&(isempty(x)||(any(size(x)==1)));');
classes.row.isa=inline('(ndims(x)==2)&&(isempty(x)||(size(x,1)==1));');
classes.column.isa=inline('(ndims(x)==2)&&(isempty(x)||(size(x,2)==1));');
classes.scalar.isa=inline('~any(size(x)~=1);');
classes.square.isa=inline('(ndims(x)==2)&&(size(x,1)==size(x,2));');
classes.wide.isa=inline('(ndims(x)==2)&&(size(x,1)<size(x,2));');
classes.tall.isa=inline('(ndims(x)==2)&&(size(x,1)>size(x,2));');
classes.nonsparse.isa=inline('~issparse(x);');
classes.nonempty.isa=inline('~isempty(x);');
classes.nonnan.isa=inline('~any(isnan((x(:))));');
classes.normalized.isa=inline('(~any(x(:)<0))&&(~any(x(:)>1));');
classes.positive.isa=inline('~any(x(:)<=0);');
classes.nonpositive.isa=inline('~any(x(:)>0);');
classes.negative.isa=inline('~any(x(:)>=0);');
classes.nonnegative.isa=inline('~any(x(:)<0);');
classes.zero.isa=inline('~any(x(:)~=0);');
classes.nonzero.isa=inline('~any(x(:)==0);');
classes.integer.isa=inline('isinteger(x)||(~any(mod(x(:),1)));');
classes.even.isa=inline('~any(bitand(x(:),1))');
classes.odd.isa=inline('~any(~bitand(x(:),1))');
classes.complex.isa=inline('~any(isreal(x(:)));');
classes.symmetric.isa=inline('(ndims(x)==2)&&(size(x,1)==size(x,2))&&isequal(x,x.'');');
classes.hermite.isa=inline('(ndims(x)==2)&&(size(x,1)==size(x,2))&&isequal(x,x'');');

%TODO: These are still undone
%classes.orthogonal.isa=
%classes.orthonormal.isa=
%classes.affine.isa=
%classes.diagonal.isa=
%classes.uppertri.isa=
%classes.lowertri.isa=

classes.str.isa=inline('ischar(x)||iscellstr(x);');
classes.nonbusday.isa=inline('~isbusday(x);');
