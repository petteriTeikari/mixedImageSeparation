function [d,E,C]=api_ica_pca(varargin)
%API_ICA_PCA Perform Principal Component Analysis.
%   [d, E] = API_ICA_PCA(C) calculates the principal components of the
%   covariance matrix C. Returns the component variances in d and
%   the corresponding components as rows of E.
%
%   [d, E] = API_ICA_PCA(X) calculates the principal components of the
%   data matrix X, with observations in rows and samples in columns.
%
%   [d, E] = API_ICA_PCA(X, LAG) calculates the principal components of
%   the data matrix X, with observations in rows and samples in
%   columns. LAG is used as a temporal lag when estimating the
%   covariance matrix. The value 0 equals to calling without LAG.
%
%   [d, E] = API_ICA_PCA(X1, X2) calculates the principal components of
%   the time or otherwise "shifted" data matrices X1 and X2. The
%   data matrices must be the same size. This is useful, when the
%   "shift" is a more complex function than just a temporal lag.
%
%   [d, E, C] = API_ICA_PCA(...) also returns the estimated covariance
%   matrix C.
%
%   NOTE: The data matrix X or matrices X1 and X2 must have their
%   observation means removed, they are not removed automatically!
%   See e.g. API_ICA_NORMALIZE.
%
%   Examples:
%     [d, E] = API_ICA_PCA(C);
%     [d, E, C] = API_ICA_PCA(X);
%
%   See also VISUALIZE_ICA_PCA, API_ICA_NORMALIZE, API_ICA_WHITEN.

% Copyright © 2004-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,3,1,2);
mode=api_core_checkarg(varargin{1},{'C' 'matrix nonempty real symmetric normalized';'X' 'matrix nonempty'});
if mode==1
  C=varargin{1};
  if any(size(C)<2) error('API_ICA_PCA:invalidInput','C must be atleast 2x2.'); end;
  api_core_checknarg(1,2);
elseif mode==2
  X1=varargin{1};
  lag=0;
  if nargin>=2
    mode=api_core_checkarg(varargin{2},{'LAG' 'scalar integer nonnegative';'X2' 'matrix nonempty'});
    if mode==1 lag=varargin{2};
    elseif mode==2
      X2=varargin{2};
      if any(size(X1)<2) error('API_ICA_PCA:invalidInput','X1 must be atleast 2x2.'); end;
      if any(size(X2)<2) error('API_ICA_PCA:invalidInput','X2 must be atleast 2x2.'); end;
      if ~isequal(size(X1),size(X2)) error('API_ICA_PCA:invalidInput','X1 and X2 must be the same size.'); end;
      lag=0;
    end;
  end;
  if any(size(X1)<2) error('API_ICA_PCA:invalidInput','X must be atleast 2x2.'); end;
end;
if exist('C','var') [m,n]=size(C); else [m,n]=size(X1); end;

api_core_progress('sub',api_core_l10n('sprintf','Principal Component Analysis of %i dimensional data...',m));
try
  if exist('X2','var')
    api_core_progress('run',api_core_l10n('sprintf','Estimating covariance from the two %ix%i shifted data matrices.',m,n));
    C=(X2*X1.')./(n-1);
    C=(C+C')./2;
  elseif exist('X1','var')
    if lag==0
      api_core_progress('run',api_core_l10n('sprintf','Estimating covariance from the %ix%i data matrix.',m,n));
      C=(X1*X1.')./(n-1);
    else
      api_core_progress('run',api_core_l10n('sprintf','Estimating covariance from the %ix%i data matrix with lag %i.',m,n,lag));
      C=(X1(1:end-lag,:)*X1(1+lag:end,:).')./(n-1-lag);
      C=(C+C')./2;
    end;
  else api_core_progress('run',api_core_l10n('sprintf','Using the provided %ix%i covariance matrix.',m,n));
  end;
  
  if exist('C','var')
    api_core_progress('run',api_core_l10n('Calculating the principal components.'));
    [U,d,E]=svd(C);
    d=diag(d);
  end;
  
  r=length(find(d>0));
  if r>0
    api_core_debug(api_core_l10n('sprintf','The rank of the data is %i out of %i.',r,numel(d)));
    d=d(1:r);
    E=E(:,1:r).';
  else
    api_core_warning(api_core_l10n('The rank of the data is 0.'));
    d=[];
    E=[];
  end;
catch err
  api_core_error(err);
  [d,E,C]=deal([]);
end;
api_core_complete('complete',api_core_l10n('Principal component analysis completed.'));
