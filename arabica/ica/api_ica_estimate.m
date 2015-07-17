function [rA,rW,rS]=api_ica_estimate(mode,c,varargin)
%API_ICA_ESTIMATE  Estimate cluster components.
%   [cA, cW] = API_ICA_ESTIMATE(MODE, c, A, W, X) estimates the components
%   defined by the cluster structure c. A and W are the mixing and
%   demixing matrices related to the clustering. They can also be
%   the cell arrays of multiple runs. X is the original data
%   matrix. The resulting cluster mixing and demixing matrices cA
%   and cW are returned. The components are scaled to have zero
%   mean and unit variance, so the corresponding mixing will
%   contain all of the original magnitude. Additionally, the sign
%   of each component is fixed according to skewness.
%
%   [cA, cW] = API_ICA_ESTIMATE(MODE, c, r, A, W, X) uses to ranking r to
%   reorder and exclude the clusters in c.
%
%   [cA, cW, cS] = API_ICA_ESTIMATE(...) also returns the
%   resulting cluster components in cS calculated as cS = cW * X.
%
%   The MODE is the estimation mode and must be one of
%   'centroid', 'variance' or 'quantile'. NOTE: The
%   'quantile' mode actually returns cell arrays containing the
%   5%, 15%, 25%, 50%, 75%, 85% and 95% quantiles.
%
%   Examples:
%     [cA, cW] = API_ICA_ESTIMATE('centroid', c, A, W, X);
%     [cA, cW, cS] = API_ICA_ESTIMATE('centroid', c, A, W, X);
%
%   See also API_ICA_ICA, API_ICA_QUICKCLUSTER.

% Copyright © 2004-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(2,3,5,6);
mode=api_core_checkopt(mode,'MODE',{'centroid','variance','quantile'});
api_core_checkarg(c,'c','struct nonempty');
r=[];
if ~isempty(varargin)
  if isstruct(varargin{1})
    api_core_checknarg(2,3,6,6);
    api_core_checkarg(varargin{1},'r','struct nonempty');
    r=varargin{1};
    varargin(1)=[];
  end;
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},{'A' 'matrix nonempty';'A' 'cell nonempty'});
  A=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},{'W' 'matrix nonempty';'W' 'cell nonempty'});
  W=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'X','matrix nonempty');
  X=varargin{1};
  varargin(1)=[];
end;
%TODO: Check that fields of c and r are correct
if (~isempty(r))&&(numel(r)~=numel(c)) error('API_ICA_ESTIMATE:invalidInput','Sizes of c and r do not match.'); end;
if iscell(A) A=horzcat(A{:}); end;
if iscell(W) W=vertcat(W{:}); end;
if ~isequal(size(A),fliplr(size(W))) error('API_ICA_ESTIMATE:invalidInput','Sizes of A and W do not match.'); end;
if (size(X,1)~=size(A,1))||(size(X,1)~=size(W,2)) error('API_ICA_ESTIMATE:invalidInput','Size of X does not match.'); end;

str=sprintf('Estimating the %ss of the %%i clusters...',mode);
api_core_progress('sub',api_core_l10n('sprintf',str,numel(c)));
try
  api_core_progress('run',api_core_l10n('Normalizing the mixing matrixes.'));
  A=api_ica_normalize(A.','variance').';
  api_core_progress('run',api_core_l10n('Normalizing the demixing matrixes.'));
  W=api_ica_normalize(W,'variance');

  if ~isempty(r)
    i=[r(:).include];
    if all(i) api_core_progress('run',api_core_l10n('Reordering clusters.'));
    else api_core_progress('run',api_core_l10n('sprintf','Reordering and excluding %i clusters which leaves %i good clusters.',sum(i),numel(c)-sum(i)));
    end;
    r=r(i);
    c=c(i);
    [nil,i]=sort([r(:).rank],'descend');
    c=c(i);
  end;

  api_core_progress('run',api_core_l10n('Calculating the cluster mixing and demixing matrixes.'));
  cA=zeros(size(A,1),numel(c));
  cW=zeros(numel(c),size(W,2));
  for i=1:numel(c)
    cA(:,i)=mean(A(:,c(i).indices).*c(i).signs(ones(1,size(A,1)),:),2);
    cW(i,:)=mean(W(c(i).indices,:).*c(i).signs(ones(1,size(W,2)),:).',1);
  end;

  api_core_progress('run',api_core_l10n('Normalizing the sign and magnitude of the components.'));
  cS=cW*X;
  [cS,nil,cSs]=api_ica_normalize(cS,'variance');
  cSs(cSs==0)=1;
  cSf=sign(skewness(cS,0,2));
  cSf(cSf==0)=1;
  cSs=cSs.*cSf;
  cS=cS.*cSf(:,ones(1,size(cS,2)));
  cW=cW./cSs(:,ones(1,size(cW,2)));
  cA=cA.*cSs(:,ones(1,size(cA,1))).';

  if strcmpi(mode,'centroid')
    api_core_progress('run',api_core_l10n('Calculating the cluster component centroids.'));
    rA=cA;
    rW=cW;
    if nargout>2 rS=cS; end;
  elseif strcmpi(mode,'variance')
    api_core_progress('run',api_core_l10n('Calculating the cluster component variances.'));
    rA=zeros(size(A,1),numel(c));
    rW=zeros(numel(c),size(W,2));
    for i=1:numel(c)
      rA(:,i)=var(A(:,c(i).indices).*c(i).signs(ones(1,size(A,1)),:),0,2);
      rW(i,:)=var(W(c(i).indices,:).*c(i).signs(ones(1,size(W,2)),:).',0,1);
    end;
    rA=rA.*abs(cSs(:,ones(1,size(rA,1)))).';
    rW=rW./abs(cSs(:,ones(1,size(rW,2))));
    if nargout>2
      d=fix(size(X,2)/10);
      r=mod(size(X,2),10);
      rS=zeros(size(cS));
      for i=1:numel(c)
        w=W(c(i).indices,:).*c(i).signs(ones(1,size(W,2)),:).'./cSs(i);
        for j=0:10
          if j<10 l=d; else l=r; end;
          s=w*X(:,j*d+(1:l));
          rS(i,j*d+(1:l))=var(s,0,1);
        end;
      end;
    end;
  elseif strcmpi(mode,'quantile')
    api_core_progress('run',api_core_l10n('Calculating the cluster component quantiles.'));
    rA=cell(1,numel(c));
    rW=cell(numel(c),1);
    for i=1:numel(c)
      rA{i}=quantile(A(:,c(i).indices).*c(i).signs(ones(1,size(A,1)),:),[0.05 0.15 0.25 0.5 0.75 0.85 0.95],2);
      rW{i}=quantile(W(c(i).indices,:).*c(i).signs(ones(1,size(W,2)),:).',[0.05 0.15 0.25 0.5 0.75 0.85 0.95],1);
      rA{i}=rA{i}.*cSs(i);
      rW{i}=rW{i}./cSs(i);
    end;
    if nargout>2
      rS=cell(1,numel(c));
      d=fix(size(X,2)/10);
      r=mod(size(X,2),10);
      for i=1:numel(c)
        S=zeros(7,size(X,2));
        w=W(c(i).indices,:).*c(i).signs(ones(1,size(W,2)),:).'./cSs(i);
        for j=0:10
          if j<10 l=d; else l=r; end;
          s=w*X(:,j*d+(1:l));
          S(:,j*d+(1:l))=quantile(s,[0.05 0.15 0.25 0.5 0.75 0.85 0.95],1);
        end;
        rS{i}=S;
      end;
    end;
  end;
catch err
  api_core_error(err);
  [rA,rW,rS]=deal([]);
end;
api_core_complete('complete',api_core_l10n('Estimation completed.'));
