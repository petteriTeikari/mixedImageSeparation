function [nX,varargout]=api_ica_normalize(X,mode)
%API_ICA_NORMALIZE Normalize a data matrix.
%   NX = API_ICA_NORMALIZE(X) removes the mean of the observations.
%
%   NX = API_ICA_NORMALIZE(X, MODE) normalizes the observations according
%   to MODE, which can be any of the valid normalization modes
%   explained below:
%
%       MODE    - Description
%   ----------------------------------------------------------------
%   'mean'       - Removes the mean of the observations.
%
%   'variance'   - Removes the mean of the observations and makes
%                  their variances unit.
%
%   'scale'      - Makes the observatitions have unit variances
%                  while retaining their mean.
%
%   'range'      - Scales the observations linearly to the range
%                  0 - 1.
%
%   'ln'         - Scales the observations using the natural
%                  logarithm, i.e. each observation x is scaled
%                  according to ln(1+x-min(x)).
%
%   'log2'       - Scales the observations using a 2 base
%                  logarithm. Otherwise the same as 'ln'.
%
%   'log10'      - Scales the observations using a 10 base
%                  logarithm. Otherwise the same as 'ln'.
%
%   'softmax'    - Removes the mean of the observations, makes their
%                  variances unit and scales using the natural
%                  exponent, i.e. each observation x is scaled
%                  according to 1/(1+exp(-x)).
%
%   'ztransform' - Treats the observations as correlations and
%                  performs the Fisher's z transform to make them
%                  Gaussian with zero mean and variance 1/(n-3),
%                  where n is the true degrees of freedom. The
%                  values should be in the range -1 - 1.
%
%   'norm'       - Scales the observations to have unit Euclidean
%                  norm.
%
%   'histogram'  - Scales the observations nonlinearly by equalizing
%                  their histogram.
%
%   [NX, M, S] = API_ICA_NORMALIZE(...) when MODE is one of 'mean',
%   'variance' or 'softmax' also returns the mean and standard
%   deviation of the observations in M and S respectively.
%
%   [NX, MIN, MAX] = API_ICA_NORMALIZE(...) when MODE is 'range' also
%   returns the minimum and maximum of the observations in MIN and
%   MAX.
%
%   [NX, MIN] = API_ICA_NORMALIZE(...) when MODE is one of 'ln', 'log2'
%   or 'log10' also returns the minimum of the observations in MIN.
%
%   [NX, NORM] = API_ICA_NORMALIZE(...) when MODE is 'norm' also returns
%   the norm of the observations in NORM.
%
%   [NX, ...] = API_ICA_NORMALIZE(...) when MODE is 'histogram' also
%   returns ...
%
%   The data matrix X must contain the observations as rows and
%   samples as columns. Only finite values are taken into account
%   when normalizing the data. The data can also be complex.
%
%   Examples:
%     NX = API_ICA_NORMALIZE(X);
%     NX = API_ICA_NORMALIZE(X, 'variance');
%
%   See also MEAN, RANGE, STD, HISTEQ.

% Copyright © 2004-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,3,1,2);
api_core_checkarg(X,'X','matrix nonempty');
if nargin>=2
  mode=api_core_checkopt(mode,'MODE',{'mean' 'variance' 'scale' 'range' 'ln' 'log2' 'log10' 'softmax' 'ztransform' 'norm' 'histogram'});
else mode='mean';
end;

api_core_progress('sub',api_core_l10n('sprintf','Normalizing the %ix%i data matrix in %s mode...',size(X,1),size(X,2),mode));
try
  nX=X;
  [m,n]=size(nX);
  rep=ones(n,1);
  nfine=~isfinite(nX);
  count=max(1,sum(~nfine,2));
  nX(nfine)=0;
  
  if any(strcmpi(mode,{'mean' 'variance' 'scale' 'softmax'}))
    api_core_progress('run',api_core_l10n('Removing the mean of the observations.'));
    meanX=sum(nX,2)./count;
    nX=nX-meanX(:,rep);
  end;
  
  if any(strcmpi(mode,{'variance' 'scale' 'softmax'}))
    api_core_progress('run',api_core_l10n('Making the observations have unit variance.'));
    stdX=sqrt(sum(conj(nX).*nX,2)./max(1,count-1));
    divX=stdX;
    divX(divX==0)=1;
    nX=nX./divX(:,rep);
  end;
  
  if strcmpi(mode,'scale')
    api_core_progress('run',api_core_l10n('Adding the mean back to the observations.'));
    nX=nX+meanX(:,rep);
  end;
  
  nX(nfine)=NaN;
  
  if strcmpi(mode,'range')
    api_core_progress('run',api_core_l10n('Scaling the observations linearly to the range 0 - 1.'));
    minX=min(nX,[],2);
    maxX=max(nX,[],2);
    rangeX=maxX-minX;
    divX=rangeX;
    divX(divX==0)=1;
    nX=(nX-minX(:,rep))./divX(:,rep);
  elseif strcmpi(mode,'ln')
    api_core_progress('run',api_core_l10n('Scaling the observations using the natural logarithm.'));
    minX=min(nX,[],2);
    nX=log(1+nX-minX(:,rep));
  elseif strcmpi(mode,'log2')
    api_core_progress('run',api_core_l10n('Scaling the observations using a 2 base logarithm.'));
    minX=min(nX,[],2);
    nX=log2(1+nX-minX(:,rep));
  elseif strcmpi(mode,'log10')
    api_core_progress('run',api_core_l10n('Scaling the observations using a 10 base logarithm.'));
    minX=min(nX,[],2);
    nX=log10(1+nX-minX(:,rep));
  elseif strcmpi(mode,'softmax')
    api_core_progress('run',api_core_l10n('Scaling the observations using the natural exponent.'));
    nX=1./(1+exp(-nX));
  elseif strcmpi(mode,'ztransform')
    api_core_progress('run',api_core_l10n('Transforming the observations with Fisher''s z transform.'));
    nX=0.5.*log((1+nX)./(1-nX));
  elseif strcmpi(mode,'norm')
    api_core_progress('run',api_core_l10n('Scaling the observations to have unit Euclidean norm.'));
    nX(nfine)=0;
    normX=sqrt(sum(nX.^2,2));
    nX(nfine)=NaN;
    divX=normX;
    divX(divX==0)=1;
    nX=nX./divX(:,rep);
  elseif strcmpi(mode,'histogram')
    api_core_progress('run',api_core_l10n('Scaling the observations to have equalized histogram.'));
    error('API_ICA_NORMALIZE:unimplemented','Discrete histogram equalization unimplemented!');
    %TODO: Discrete histogram equalization...
    %p = unique(x(inds));
    %bins = length(p);
    %inds = find(~isnan(x) & ~isinf(x))';
    %for i = inds,
    %  [dummy ind] = min(abs(x(i) - p));
    %  if x(i) > p(ind) & ind < bins,
    %    x(i) = ind + 1;
    %  else
    %    x(i) = ind;
    %  end
    %end
    %x = (x-1)/(bins-1);
  end;
  
  nX(nfine)=X(nfine);

  if nargout>=2
    if exist('meanX','var') varargout{1}=meanX;
    elseif exist('minX','var') varargout{1}=minX;
    elseif exist('normX','var') varargout{1}=normX;
    end;
  end;
  if nargout>=3
    if exist('stdX','var') varargout{2}=stdX;
    elseif exist('maxX','var') varargout{2}=maxX;
    end;
  end;
  %TODO: Histogram returns...
catch err
  api_core_error(err);
  nX=[];
  varargout=cell(1,nargout-1);
end;
api_core_complete('complete',api_core_l10n('Data normalizing completed.'));
