function [err,id]=api_core_checknarg(varargin)
%API_CORE_CHECKNARG Check number of input and output arguments.
%   API_CORE_CHECKNARG(INMIN, INMAX) checks whether the number of input
%   arguments is in the range indicated by INMIN and INMAX.
%   If not, API_CORE_CHECKNARG issues a formatted error message.
%
%   API_CORE_CHECKNARG(OUTMIN, OUTMAX, INMIN, INMAX) checks whether the
%   number of input arguments is in the range indicated by INMIN
%   and INMAX and whether the number of output arguments is in the
%   range indicated by OUTMIN and OUTMAX. If not, API_CORE_CHECKNARG issues
%   a formatted error message.
%
%   API_CORE_CHECKNARG(in) for a Nx2 matrix in checks according to each row
%   [INMIN INMAX] of the matrix in.
%
%   API_CORE_CHECKNARG(OUTIN) for a Nx4 matrix OUTIN checks according to
%   each row [OUTMIN OUTMAX INMIN INMAX] of the matrix OUTIN.
%
%   ERR = API_CORE_CHECKNARG(...) does not issue a formatted error message.
%   Instead it returns the error message in ERR.
%
%   [ERR, ID] = API_CORE_CHECKNARG(...) does not issue a formatted error
%   message. Instead it returns the error message in ERR and the
%   error id in ID.
%
%   INMIN and OUTMIN must be scalar nonnegative integers or Nans.
%   Nan means equal to number of outputs.
%
%   INMAX and OUTMAX must be scalar nonnegative integers, Infs or
%   Nans. Nan means equal to number of inputs.
%
%   Example:
%     API_CORE_CHECKNARG(0, 1, 1, 4)
%
%   See also API_CORE_CHECKARG, API_CORE_CHECKOPT, API_CORE_CHECKPARAM,
%   NARGIN, NARGOUT, NARGCHK, NARGOUTCHK.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

lid='';
lerr='';
res=evalin('caller','{nargin nargout};');
[nin,nout]=deal(res{:});

try
  if nargin==1
    if size(varargin{1},2)==2
      out=[];
      in=varargin{1};
    elseif size(varargin{1},2)==4
      out=varargin{1}(:,1:2);
      in=varargin{1}(:,3:4);
    else error('API_CORE_CHECKNARG:invalidInput','Input in must be a Nx2 or OUTIN a Nx4 matrix.');
    end;
  elseif nargin==2
    out=[];
    in=[varargin{:}];
  elseif nargin==4
    out=[varargin{1:2}];
    in=[varargin{3:4}];
  elseif nargin==0 error('API_CORE_CHECKNARG:invalidInput','Not enough input arguments.');
  elseif nargin==3 error('API_CORE_CHECKNARG:invalidInput','Wrong number of input arguments.');
  else error('API_CORE_CHECKNARG:invalidInput','Too many input arguments.');
  end;

  in(isnan(in))=nout;
  in=[nin<in(:,1) nin>in(:,2)];
  if all(any(in,2))
    if all(in(:,1)) lerr='Not enough input arguments.';
    elseif all(in(:,2)) lerr='Too many input arguments.';
    else lerr='Wrong number of input arguments.';
    end;
    lid='invalidInput';
  elseif ~isempty(out)
    out(isnan(out))=nin;
    out=[nout<out(:,1) nout>out(:,2)];
    if all(any(out,2))
      if all(out(:,1)) lerr='Not enough output arguments.';
      elseif all(out(:,2)) lerr='Too many output arguments.';
      else lerr='Wrong number of output arguments.';
      end;
      lid='invalidOutput';
    elseif all(any([out in],2))
      if all(out(find(~any(in,2)),1)) lerr='Not enough output arguments.';
      elseif all(out(find(~any(in,2)),2)) lerr='Too many output arguments.';
      else lerr='Wrong number of output arguments.';
      end;
      lid='invalidOutput';
    end;
  end;
catch err
  if isempty(err.identifier)||isempty(strmatch(err.identifier,'API_CORE_CHECKNARG'))
    if nargin==1
      t=varargin{1};
      if ~(isnumeric(t)&&(ndims(t)==2)&&((size(t,2)==2)||(size(t,2)==4)))
        error('API_CORE_CHECKNARG:invalidInput','Input in must be a Nx2 or OUTIN a Nx4 matrix.');
      end;
    elseif nargin==2
      t=varargin{1};
      if ~(isnumeric(t)&&(numel(t)==1)&&((isfinite(t)&&(t>=0))||isnan(t)))
        error('API_CORE_CHECKNARG:invalidInput','Input INMIN must be a scalar nonnegative integer or Nan.');
      end;
      t=varargin{2};
      if ~(isnumeric(t)&&(numel(t)==1)&&((t>=0)||isnan(t)))
        error('API_CORE_CHECKNARG:invalidInput','Input INMAX must be a scalar nonnegative integer, Inf or Nan.');
      end;
    elseif nargin==4
      t=varargin{1};
      if ~(isnumeric(t)&&(numel(t)==1)&&((isfinite(t)&&(t>=0))||isnan(t)))
        error('API_CORE_CHECKNARG:invalidInput','Input OUTMIN must be a scalar nonnegative integer or Nan.');
      end;
      t=varargin{2};
      if ~(isnumeric(t)&&(numel(t)==1)&&((t>=0)||isnan(t)))
        error('API_CORE_CHECKNARG:invalidInput','Input OUTMAX must be a scalar nonnegative integer, Inf or Nan.');
      end;
      t=varargin{3};
      if ~(isnumeric(t)&&(numel(t)==1)&&((isfinite(t)&&(t>=0))||isnan(t)))
        error('API_CORE_CHECKNARG:invalidInput','Input INMIN must be a scalar nonnegative integer or Nan.');
      end;
      t=varargin{4};
      if ~(isnumeric(t)&&(numel(t)==1)&&((t>=0)||isnan(t)))
        error('API_CORE_CHECKNARG:invalidInput','Input INMAX must be a scalar nonnegative integer, Inf or Nan.');
      end;
    else error('API_CORE_CHECKNARG:invalidInput','Invalid input argument(s).');
    end;
  else rethrow(err);
  end;
end;

if lerr
  st=dbstack(1);
  if isempty(st) name='API_CORE_CHECKNARG';
  else name=upper(st(1).name);
  end;
  if isempty(lid) lid='invalidInput'; end;
  lid=[name ':' lid];
end;

[err,id]=deal(lerr,lid);
if (nargout==0)&&(~isempty(lerr))
  cerr.message=lerr;
  cerr.identifier=lid;
  cerr.stack=st;
  lasterror(cerr);
  rethrow(cerr);
elseif nargout>2 error('API_CORE_CHECKNARG:invalidOutput','Too many output arguments.');
end;
