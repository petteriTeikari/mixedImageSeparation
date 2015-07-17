function [A,W,WM,DWM]=api_ica_ica(X,varargin)
%API_ICA_ICA  Perform Independent Component Analysis.
%   [A, W] = API_ICA_ICA(X) runs FastICA using nonlinearity 'tanh' and
%   approach 'defl' estimating as many independent components as
%   there are dimensions in the data matrix X. Returns the mixing A
%   and demixing W matrices related to X.
%
%   [A, W] = API_ICA_ICA(X, N) runs FastICA N times and returns a cell
%   array A of mixing matrices and a cell array W of demixing
%   matrices related to X.
%
%   [A, W] = API_ICA_ICA(..., 'approach', APP, ...) uses the FastICA
%   approach APP. APP must be either 'symm' or 'defl'.
%
%   [A, W] = API_ICA_ICA(..., 'nonlinearity', NLIN, ...) uses the
%   FastICA nonlinearity NLIN. NLIN must be one of 'pow3', 'tanh',
%   'gaus' or 'skew'.
%
%   [A, W] = API_ICA_ICA(..., 'dim', DIM, ...) reduces dimensions to DIM.
%   DIM must be less than or equal to the number of dimensions in
%   the data matrix X and higher than or equal to the number of
%   estimated independent components.
%
%   [A, W] = API_ICA_ICA(..., 'ics', NUM, ...) estimates only NUM
%   independent components in each run. NUM must be less than or
%   equal to the number of dimensions in the data matrix and the
%   number of reduced dimensions.
%
%   [A, W] = API_ICA_ICA(..., 'skip', NUM, ...) skips the first NUM
%   iterations in a multiple run scheme, i.e. allows to continue
%   after existing run or runs. It also makes multiple parallel
%   runs possible.
%
%   [A, W] = API_ICA_ICA(..., 'bootstrap', BS, ...) uses resampling to
%   bootstrap the data. If BS is in the range from  0 to 1, that fraction
%   of samples are used in each run and if BS is greater than 1, that
%   number of samples are used in each run. Additionally, if the sign of BS
%   is negative, the order of samples is allowed to change. The value 0
%   disables bootstrapping. If BS is a function handle, that function is
%   called to generate the random indices as BS(N) and must return a row
%   vector of indices in the range from 1 to N.
%
%   [A, W] = API_ICA_ICA(..., 'nomean', ...) disables the removal of the
%   mean of the data matrix, i.e., uses correlation instead of
%   covariance in whitening.
%
%   [A, W, wM, dwM] = API_ICA_ICA(...) return also the whitening and
%   dewhitening matrixes, or cell arrays of the matrixes.
%
%   Examples:
%     [A, W] = API_ICA_ICA(X);
%     [A, W] = API_ICA_ICA(X, 100, 'dim', 20, 'ics', 10);
%
%   See also API_ICA_WHITE, API_ICA_QUICKCLUSTER, API_ICA_ESTIMATE,
%   FASTICA.

% Copyright © 2003-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,4,1,15);
api_core_checkarg(X,'X','matrix nonempty');
n=1;
skip=0;
ics=size(X,1);
dim=size(X,1);
nlin='tanh';
app='symm';
bs=0;
nom=false;
if (~isempty(varargin))&&isnumeric(varargin{1})
  api_core_checkarg(varargin{1},'N','scalar integer positive');
  n=varargin{1};
  varargin(1)=[];
end;
while ~isempty(varargin)
  param=api_core_checkopt(varargin{1},'PARAMETER','approach','nonlinearity','dim','ics','skip','bootstrap','nomean');
  if strcmp(param,'nomean') nom=true;
  else
    if numel(varargin)<2 error('API_ICA_ICA:invalidInput','Parameter without value.'); end;
    if strcmp(param,'approach')
      app=api_core_checkopt(varargin{2},'APPROACH','deflation','symmetric');
      if strcmp(app,'deflation') app='defl';
      elseif strcmp(app,'symmetric') app='symm';
      end;
    elseif strcmp(param,'nonlinearity')
      nlin=api_core_checkopt(varargin{2},'NONLINEARITY','pow3','tanh','gaus','skew');
    elseif strcmp(param,'dim')
      api_core_checkarg(varargin{2},'DIM','scalar integer positive');
      dim=varargin{2};
    elseif strcmp(param,'ics')
      api_core_checkarg(varargin{2},'ICS','scalar integer positive');
      ics=varargin{2};
    elseif strcmp(param,'skip')
      api_core_checkarg(varargin{2},'SKIP','scalar integer nonnegative');
      skip=varargin{2};
    elseif strcmp(param,'bootstrap')
      api_core_checkarg(abs(varargin{2}),{'BOOTSTRAP' 'scalar normalized';'BOOTSTRAP' 'scalar integer positive';'BOOTSTRAP' 'scalar function_handle'});
      bs=varargin{2};
      if isnumeric(bs)&&(((abs(bs)>1)&&rem(bs,1))||(abs(bs)>size(X,2))) error('API_ICA_ICA:invalidInput','Invalid number BS for bootstrap.'); end;
    end;
    varargin(1)=[];
  end;
  varargin(1)=[];
end;
if dim>size(X,1) error('API_ICA_ICA:invalidInput','Invalid number DIM of dimensions.'); end;
if (ics>dim)||(ics>size(X,1)) error('API_ICA_ICA:invalidInput','Invalid number NUM of ics.'); end;

if n==1 [A,W]=deal([]); else [A,W]=deal({}); end;
if (n==1)||(isnumeric(bs)&&(~bs)) [WM,DWM]=deal([]); else [WM,DWM]=deal({}); end;

api_core_progress('sub',api_core_l10n('sprintf','Performing independent component analysis for the %ix%i data matrix...',size(X,1),size(X,2)));
try
  if skip==0 api_core_progress('run',api_core_l10n('sprintf','Running FastICA %i times.',n));
  else api_core_progress('run',api_core_l10n('sprintf','Continuing FastICA %i times after %i skipped runs.',n,skip));
  end;
  if isnumeric(bs)&&bs
    if abs(bs)<=1 bs=fix(sign(bs)*max(1,abs(bs)*size(X,2))); end;
    if bs>0 api_core_progress('run',api_core_l10n('sprintf','Bootstrapping to a %ix%i data matrix.',size(X,1),abs(bs)));
    else api_core_progress('run',api_core_l10n('sprintf','Bootstrapping to a reordered %ix%i data matrix.',size(X,1),abs(bs)));
    end;
  elseif isa(bs,'function_handle') api_core_progress('run',api_core_l10n('Bootstrapping with a custom function.'));
  end;
  if nom api_core_progress('run',api_core_l10n('Using Correlation instead of Covariance')); end;
  api_core_progress('run',api_core_l10n('sprintf','Whitening to %i dimension.',dim));
  for i=skip:skip+n-1
    api_core_progress('run',(1+i-skip)/n,1,api_core_l10n('sprintf','Starting run %i.',i+1));
    api_core_random(2009+i);
    if isnumeric(bs)&&bs
      if exist('randi','builtin') boots=randi(size(X,2),1,abs(bs)); else boots=fix(1+size(X,2).*rand(1,abs(bs))); end;
      if bs>0 boots=sort(boots); end;
      bX=X(:,boots);
    elseif isa(bs,'function_handle') bX=X(:,bs(size(X,2)));
    else bX=X;
    end;
    if (isnumeric(bs)&&bs)||isa(bs,'function_handle')||(~exist('wX','var'))
      if nom nX=bX; else nX=api_ica_normalize(bX,'mean'); end;
      [d,E]=api_ica_pca(nX);
      [wM,dwM,wX]=api_ica_whiten(d,E,nX,dim);
      if ~((isnumeric(bs)&&(bs))||isa(bs,'function_handle')) [WM,DWM]=deal(wM,dwM); end;
    end;
    api_core_progress('run',api_core_l10n('sprintf','Looking for %i independent components with FastICA using approach %s and nonlinearity %s.',ics,app,nlin));
    [a,w]=fpica(wX,wM,dwM,app,ics,nlin,'off',1,1,1,'off',0.0001,300,5,'rand',0,1,'off',1,'off');
    if isempty(w)||(size(w,2)<ics)
      api_core_warning(api_core_l10n('sprintf','Run %i aborted.',i+1));
    else
      api_core_progress('run',(1+i-skip)/n,1,api_core_l10n('sprintf','Run %i completed.',i+1));
      if n==1 [A,W]=deal(a,w);
      else
        A{1,end+1}=a;
        W{end+1,1}=w;
        if (isnumeric(bs)&&bs)||isa(bs,'function_handle')
          WM{end+1,1}=wM;
          DWM{1,end+1}=dwM;
        end;
      end;
    end;
  end;
  api_core_complete('complete',api_core_l10n('FastICA runs completed.'));
catch err
  api_core_error(err);
end;
api_core_complete('complete',api_core_l10n('Independent component analysis completed.'));
