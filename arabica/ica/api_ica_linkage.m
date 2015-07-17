function [L,i,j]=api_ica_linkage(S,varargin)
%API_ICA_LINKAGE  Calculate linkage of a similarity matrix.
%   L = API_ICA_LINKAGE(S) calculates the linkage of similarity matrix S in
%   mode 'inversescore' with threshold 0.85 and maximum path length of 4.
%
%   L = API_ICA_LINKAGE(S, MODE) calculates the linkage in mode MODE, where
%   MODE can be 'score', 'inversescore' or 'count'. For a pair (i, j) in
%   the linkage matrix L, the 'score' mode tells how many places are
%   reachable with all possible paths starting with a hop from i to j,
%   whereas the 'count' mode tells the number of hops needed to link i to
%   j. The 'inversescore' is a normalized 'score', where the diagonal is
%   set to one and the rest of the values are reversed into the range from
%   1 to maximum path length, so that its usage would be identical to mode
%   'count' except that the values are continuous instead of integers.
%
%   L = API_ICA_LINKAGE(..., TH, P) uses threshold TH and maximum path
%   length P to calculate the linkage.
%
%   [L,I,J] = API_ICA_LINKAGE(...) also returns the indices of all nonzero
%   link pairs (i, j) in L.
%
%   Examples:
%     L = API_ICA_LINKAGE(S);
%     L = API_ICA_LINKAGE(S, 'count');
%
%   See also API_ICA_SIMILARITY, API_ICA_QUICKCLUSTER.

% Copyright © 2003-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,3,1,4);
api_core_checkarg(S,{'S' 'square matrix nonempty';'S' 'square logical nonempty'});
mode='inversescore';
th=0.85;
p=4;
if ~isempty(varargin)
  if ischar(varargin{1})||iscellstr(varargin{1})
    mode=api_core_checkopt(varargin{1},'MODE','score','inversescore','count');
    varargin(1)=[];
  end;
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'TH','scalar normalized');
    th=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isempty(varargin)
  if ~isempty(varargin{1})
    api_core_checkarg(varargin{1},'P','scalar integer positive');
    p=varargin{1};
  end;
  varargin(1)=[];
end;

api_core_progress('sub',api_core_l10n('sprintf','Calculating linkage %s of the %i components...',mode,size(S,1)));
try
  S=abs(S)>th;
  api_core_progress('run',api_core_l10n('sprintf','Calculating the %ix%i linkage matrix with threshold %g and maximum path length %i.',size(S,1),size(S,1),th,p));
  if any(strcmp(mode,{'score' 'inversescore'}))
    L=S^p;
    if strcmp(mode,'inversescore')
      ind=logical(L);
      L(ind)=1+(p-1)*(1-L(ind)./max(L(ind)));
      ind=sub2ind(size(L),1:size(L,1),1:size(L,2));
      L(ind)=1;
    end;
  else
    Lmask=S;
    L=double(S);
    for k=2:p
      ind=xor(logical(S^k),Lmask);
      Lmask(ind)=true;
      L(ind)=k;
    end;
  end;
  [i,j]=find(tril(L,-1));
  ind=sub2ind(size(L),i,j);
  str=sprintf('Linkage %ss of %%i links are in the range %%g - %%g.',mode);
  api_core_progress('run',api_core_l10n('sprintf',str,numel(ind),min(L(ind)),max(L(ind))));
catch err
  api_core_error(err);
  [L,i,j]=deal([]);
end;
api_core_complete('complete',api_core_l10n('Linkage calculation completed.'));
