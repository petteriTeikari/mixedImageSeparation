function [wM,dwM,wX]=api_ica_whiten(d,E,varargin)
%API_ICA_WHITEN  Whitening of a data matrix.
%   [wM, dwM] = API_ICA_WHITEN(d, E) calculates the whitening matrix wM
%   and dewhitening matrix dwM without reducing dimensions. The d
%   and E are the principal components as returned by API_ICA_PCA.
%
%   [wM, dwM] = API_ICA_WHITEN(d, E, DIM) reduces dimensions to the DIM
%   strongest principal components. DIM must be less than or equal
%   to the amount of original dimensions.
%
%   [wM, dwM] = API_ICA_WHITEN(d, E, DIMS) for vector DIMS reduces
%   dimensions according to the list of principal component indexes
%   in DIMS. The list DIMS can contain indexes in any order, but
%   there must not be duplicates and the length of DIMS must be
%   less than or equal to the amount of original dimensions.
%
%   [wM, dwM] = API_ICA_WHITEN(d, E, LOW, HIGH) reduces dimensions to the
%   given range LOW - HIGH of principal components.
%
%   [wM, dwM] = API_ICA_WHITEN(d, E, ..., 'symmetric') uses the so called
%   symmetric whitening, i.e., brings the data back to the original domain.
%
%   [wM, dwM, wX] = API_ICA_WHITEN(d, E, X, ...) also returns the whitened
%   data matrix wX, i.e., wX = wM * X.
%
%   NOTE: The data matrix X must have its observation means removed,
%   they are not removed automatically! See e.g. API_ICA_NORMALIZE.
%
%   Examples:
%     [wM, dwM] = API_ICA_WHITEN(d, E);
%     [wM, dwM, wX] = API_ICA_WHITEN(d, E, X, 10);
%
%   See also API_ICA_NORMALIZE, API_ICA_PCA, API_ICA_ICA.

% Copyright © 2003-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(2,3,2,6);
api_core_checkarg(d,'d','vector nonempty real positive');
api_core_checkarg(E,'E','matrix nonempty real');
if numel(d)~=size(E,1) error('API_ICA_WHITEN:invalidInput','Illegal principal components d and E.'); end;
i=1:numel(d);
symm=false;
while ~isempty(varargin)
  if (ischar(varargin{1})||iscellstr(varargin{1}))
    api_core_checkopt(varargin{1},'SYMMETRIC','symmetric');
    symm=true;
    varargin(1)=[];
  elseif (numel(varargin)>=2)&&isnumeric(varargin{1})&&(numel(varargin{1})==1)&&isnumeric(varargin{2})&&(numel(varargin{2})==1)
    api_core_checkarg(varargin{1},'LOW','scalar nonempty integer positive');
    api_core_checkarg(varargin{2},'HIGH','scalar nonempty integer positive');
    if varargin{1}>length(d) error('API_ICA_WHITEN:invalidInput','Illegal number of dimensions LOW.'); end;
    if varargin{2}>length(d) error('API_ICA_WHITEN:invalidInput','Illegal number of dimensions HIHG.'); end;
    i=varargin{1}:varargin{2};
    varargin(1:2)=[];
  else
    mode=api_core_checkarg(varargin{1},{'DIM or LOW' 'scalar nonempty integer positive';'DIMS' 'vector nonempty integer positive';'X' 'matrix nonempty'});
    if mode==1
      if varargin{1}>length(d) error('API_ICA_WHITEN:invalidInput','Illegal number of dimensions DIM.'); end;
      i=1:varargin{1};
    elseif mode==2
      if (max(varargin{1})>numel(d))||(numel(unique(varargin{1}))~=numel(varargin{1}))||(numel(varargin{1})>numel(d)) error('API_ICA_WHITEN:invalidInput','Illegal indexes of dimensions DIMS.'); end;
      i=varargin{1};
    elseif mode==3
      X=varargin{1};
      if size(X,1)~=size(E,2) error('API_ICA_WHITEN:invalidInput','Illegal X for principal components d and E.'); end;
    end;
    varargin(1)=[];
  end;
end;
if (nargout==3)&&(~exist('X','var')) error('API_ICA_WHITEN:invalidOutput','Too many output arguments.'); end;

api_core_progress('sub',api_core_l10n('sprintf','Whitening %i dimensional data...',length(d)));
api_core_progress('run',api_core_l10n('sprintf','Selecting the %i principal components.',length(i)));
api_core_progress('run',api_core_l10n('sprintf','Variances are in the range %g - %g.',min(d(i)),max(d(i))));
api_core_progress('run',api_core_l10n('sprintf','Variance explained %g is %g%% out of total %g.',sum(d(i)),100*sum(d(i))/sum(d),sum(d)));
try
  wM=diag(1./sqrt(d(i)))*E(i,:);
  dwM=E(i,:).'*diag(sqrt(d(i)));
  if symm
    api_core_debug(api_core_l10n('Making whitening matrix symmetric.'));
    wM=E(i,:).'*wM;
    dwM=dwM*E(i,:);
  end;
  
  if exist('X','var')&&(nargout==3)
    api_core_progress('run',api_core_l10n('sprintf','Calculating the whitened %ix%i data matrix.',size(wM,1),size(X,2)));
    wX=wM*X;
    
    if ~isreal(wX) api_core_error(api_core_l10n('Whitened data contains imaginary values.')); end;
    if ~symm
      C=abs(cov(wX.')-eye(size(wX,1)));
      c=max(C(:));
      if c>sqrt(eps) api_core_warning(api_core_l10n('Whitened data is not white.'));
      else api_core_debug(api_core_l10n('sprintf','Covariance of whitened data differs from identity by %g.',c));
      end;
    end;
  end;
catch err
  api_core_error(err);
  [wM,dwM,wX]=deal([]);
end;
api_core_complete('complete',api_core_l10n('Data whitening completed.'));
