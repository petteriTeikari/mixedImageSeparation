function [S,bl]=api_ica_similarity(X,mode,type)
%API_ICA_SIMILARITY  Calculate a similarity matrix of components.
%   S = API_ICA_SIMILARITY(X) calculates the similarity matrix of the data
%   matrix X. X can also be a cell array of multiple instances, which will
%   be automatically concatenated. Automatically selects the smaller
%   dimension to be the dimension of the similarity matrix. The
%   similarity type is 'correlation' after normalizing with mode
%   'variance'.
%
%   S = API_ICA_SIMILARITY(X, MODE, TYPE) calculates similarities of the
%   given TYPE after using normalization of MODE, where TYPE can be
%   'correlation', 'euclidean', 'cityblock', 'mahalanobis', 'minkowski',
%   'cosine', 'spearman', 'hamming', 'jaccard' or 'chebychev' as defined by
%   PDIST and MODE can be any of the valid modes for API_ICA_NORMALIZE.
%   NOTE: Unlike in PDIST the similarities of the type 'correlation' are
%   signed.
%
%   [S, BLOCKS] = API_ICA_SIMILARITY(...) also returns the number of
%   components in each block when X is a cell array or [] otherwise.
%
%   Examples:
%     S = API_ICA_SIMILARITY(X);
%     S = API_ICA_SIMILARITY(X, 'norm', 'euclidean');
%
%   See also API_ICA_NORMALIZE, API_ICA_QUICKCLUSTER, API_ICA_RANK, PDIST.

% Copyright © 2003-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,2,1,3);
api_core_checkarg(X,{'X' 'matrix nonempty';'X' '2d cell nonempty'});
if nargin<2 mode='variance'; end;
if nargin>2 type=api_core_checkopt(type,'TYPE','correlation','euclidean','cityblock','mahalanobis','minkowski','cosine','spearman','hamming','jaccard','chebychev');
else type='correlation';
end;
bl=[];
if iscell(X)
  if size(X,1)>size(X,2)
    bl=cellfun(@(x)size(x,1),X).';
    X=vertcat(X{:});
  else
    bl=cellfun(@(x)size(x,2),X);
    X=horzcat(X{:}).';
  end;
elseif size(X,1)>size(X,2) X=X.';
end;

api_core_progress('sub',api_core_l10n('sprintf','Calculating similarities of the %i components...',size(X,1)));
try
  if isempty(mode) api_core_progress('run',api_core_l10n('sprintf','Not normalizing the %ix%i data matrix.',size(X,1),size(X,2)));
  else X=api_ica_normalize(X,mode);
  end;
  api_core_progress('run',api_core_l10n('sprintf','Calculating the %ix%i similarity matrix of type %s.',size(X,1),size(X,1),type));
  if strcmp(type,'correlation')
    S=(X*X')./(size(X,2)-1);
    %TODO: Maybe in the future think the scaling again
    %api_core_debug(api_core_l10n('sprintf','[%g %g]',min(S(:)),max(S(:))));
    S=S./max(abs(S(:)));
  else
    %TODO: Maybe in the future make all these signed at huge computational cost
    S=pdist(X,type);
    S=squareform(S);
    S=1-S./max(S(:));
  end;
  ind=tril(repmat(true,size(S)),-1);
  api_core_progress('run',api_core_l10n('sprintf','Similarities are in the range %g - %g.',min(S(ind)),max(S(ind))));
catch err
  api_core_error(err);
  [S,bl]=deal([]);
end;
api_core_complete('complete',api_core_l10n('Similarity calculation completed.'));
