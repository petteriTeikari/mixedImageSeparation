function [c,r]=api_ica_quickcluster(L,varargin)
%API_ICA_QUICKCLUSTER  Cluster linkage matrix L in one quick pass.
%   c = API_ICA_QUICKCLUSTER(L) clusters the linkage matrix L and assumes
%   that it was originally one big block.
%
%   c = API_ICA_QUICKCLUSTER(L, S) also uses the similarity matrix S or any
%   matrix of the proper size to calculate the signs of the links in L.
%
%   c = API_ICA_QUICKCLUSTER(..., BLOCK) assumes that the linkage matrix
%   was concatenated from evenly sized block each having BLOCK components.
%
%   c = API_ICA_QUICKCLUSTER(..., BLOCKS) assumes that the linkage matrix
%   was concatenated from blocks each having the number of components
%   indicated by the value in vector BLOCKS, where the length of BLOCKS
%   defines the number of blocks.
%
%   [c, r] = API_ICA_QUICKCLUSTER(...) also return a simple ranking based
%   on the ratio of mean intra and inter cluster linkage weighted with the
%   number of components.
%
%   Examples:
%     c = API_ICA_QUICKCLUSTER(L);
%     c = API_ICA_QUICKCLUSTER(L, S, 40);
%
%   See also API_ICA_SIMILARITY, API_ICA_LINKAGE, API_ICA_RANK.

% Copyright © 2003-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,2,1,3);
api_core_checkarg(L,{'L' 'square matrix nonempty';'L' 'square logical nonempty'});
S=[];
bl=[];
if ~isempty(varargin)
  mode=api_core_checkarg(varargin{1},{'BLOCK' 'scalar integer positive';'BLOCKS' 'vector integer nonnegative';'S','square matrix nonempty'});
  if mode==3 S=varargin{1};
  else
    api_core_checknarg(1,1,2,2);
    bl=varargin{1};
  end;
  varargin(1)=[];
end;
if ~isequal(size(L),size(S)) error('API_ICA_QUICKCLUSTER:invalidInput','The size of S must be equal to the size of L!'); end;
if (~isempty(varargin))&&isempty(bl)
  api_core_checkarg(varargin{1},{'BLOCK' 'scalar integer positive';'BLOCKS' 'vector integer nonnegative'});
  bl=varargin{1};
  varargin(1)=[];
end;
if isempty(bl) bl=[1 1+size(L,1)];
elseif numel(bl)==1 bl=[1 1+cumsum(repmat(bl,1,ceil(size(L,1)/bl)))];
else bl=[1 1+cumsum(bl(:).')];
end;
if bl(end)<=size(L,1) error('API_ICA_QUICKCLUSTER:invalidInput','The sum of BLOCKS must be higher than the number of components in L!'); end;

s=size(L);
api_core_progress('sub',api_core_l10n('sprintf','Clustering the %i components in %i blocks...',s(1),numel(bl)-1));
try
  i=find(tril(L,-1));
  [nil,j]=sort(L(i));
  g={};
  u=1:s(1);
  for k=1:numel(j)
    if isempty(u) break; end;
    [a,b]=ind2sub(s,i(j(k)));
    m=ismember([a b],u);
    if all(m) g{end+1}=[a b];
    elseif any(m)
      if m(1) f=b; else f=a; end;
      for n=1:numel(g)
        if ismember(f,g{n}) g{n}=union(g{n},[a b]); end;
      end;
    end;
    if any(m) u=setdiff(u,[a b]); end;
  end;
  g=horzcat(g,num2cell(u));
  api_core_progress('run',api_core_l10n('sprintf','Creating %i clusters.',numel(g)));
  ml=zeros(1,numel(g));
  for i=1:numel(g)
    l=g{i};
    c(i).indices=l;
    if isempty(S) c(i).signs=ones(1,numel(l)); else c(i).signs=sign(S(l(1),l)); end;
    [nil,c(i).blocks]=histc(l,bl);
    ml(i)=numel(l);
  end;
  api_core_progress('run',api_core_l10n('sprintf','Cluster counts are in the range %i - %i.',min(ml),max(ml)));
  [nil,i]=sort(ml,'descend');
  c=c(i);

  if nargout>1 r=api_ica_rank(c,logical(L)); end;
catch err
  api_core_error(err);
  c=struct('indices',{},'signs',{},'blocks',{});
  r=struct('contribution',{},'intra',{},'inter',{},'rank',{});
end;
api_core_complete('complete',api_core_l10n('Clustering completed.'));
