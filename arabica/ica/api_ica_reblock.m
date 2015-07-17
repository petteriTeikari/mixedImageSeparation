function R=api_ica_reblock(varargin)
%API_ICA_REBLOCK  Reorder blocks of similarity matrix.
%   S = API_ICA_REBLOCK(MODE, S, c) reorders the block of similarity matrix S or any
%   suitable matrix according to the clustering c in mode MODE.
%
%   S = API_ICA_REBLOCK(MODE, S, c, r) uses to ranking r to
%   reorder and exclude the clusters in c.
%
%   The MODE is the reordering mode and must be one of 'reorder'.
%
%   Examples:
%     S = API_ICA_REBLOCK('reorder', S, c);
%     S = API_ICA_REBLOCK('reorder', S, c, r);
%
%   See also API_ICA_SIMILARITY, API_ICA_QUICKCLUSTER, API_ICA_ESTIMATE.

% Copyright © 2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,1,2,4);
mode='reorder';
r=[];
if ~isempty(varargin)
  if ischar(varargin{1})||iscellstr(varargin{1})
    api_core_checknarg(1,1,3,4);
    mode=api_core_checkopt(mode,'MODE',{'reorder'});
    varargin(1)=[];
  end;
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},{'S' 'square matrix nonempty';'S' 'square logical nonempty'});
  S=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  api_core_checkarg(varargin{1},'c','struct nonempty');
  c=varargin{1};
  varargin(1)=[];
end;
if ~isempty(varargin)
  if isstruct(varargin{1})
    api_core_checkarg(varargin{1},'r','struct nonempty');
    r=varargin{1};
    varargin(1)=[];
  end;
end;
%TODO: Check that fields of c and r are correct
s=max([c(:).indices]);
if ~isequal([s s],size(S)) error('API_ICA_REBLOCK:invalidInput','The size of S must match the one used for clustering!'); end;
if (~isempty(r))&&(numel(r)~=numel(c)) error('API_ICA_REBLOCK:invalidInput','Sizes of c and r do not match.'); end;

api_core_progress('sub',api_core_l10n('sprintf','Reordering the blocks of the %ix%i similarity matrix in mode %s...',size(S,1),size(S,2),mode));
try
  if ~isempty(r)
    i=[r(:).include];
    if ~all(i) api_core_progress('run',api_core_l10n('sprintf','Excluding %i clusters which leaves %i good clusters.',sum(i),numel(c)-sum(i))); end;
    r=r(i);
    c=c(i);
    [nil,i]=sort([r(:).rank],'descend');
    c=c(i);
  end;
  %TODO: Maybe in the future iterative cost-function optimization based on distance of off-diagonals
  if strcmp(mode,'reorder')
    bi=[0 cumsum(cellfun(@numel,{c(:).indices}))];
    api_core_progress('run',api_core_l10n('sprintf','Reordering into a %ix%i similarity matrix.',bi(end),bi(end)));
    R=zeros(bi(end),bi(end));
    for i=1:numel(c)
      for j=1:numel(c)
        R(bi(i)+(1:numel(c(i).indices)),bi(j)+(1:numel(c(j).indices)))=S(c(i).indices,c(j).indices);
      end;
    end;
  end;
catch err
  api_core_error(err);
  R=[];
end;
api_core_complete('complete',api_core_l10n('Reordering completed.'));
