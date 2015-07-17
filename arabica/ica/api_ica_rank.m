function r=api_ica_rank(c,S,th)
%API_ICA_RANK  Rank goodness of clustering based on similarity.
%   r = API_ICA_RANK(c, S) rank the clusters c using the similarity matrix
%   S to measure to goodness of clustering. The ranking is returned in a ranking structure.
%
%   r = API_ICA_RANK(c, S, TH) only sets the include flags to true on clusters that have a rank
%   larger than threshold TH in the range from 0 to 1.
%
%   r = API_ICA_RANK(c, S, MIN) only sets the include flags to true on clusters that have more
%   components than threshold MIN.
%
%   Examples:
%     r = API_ICA_RANK(c, S);
%     r = API_ICA_RANK(c, S, 1);
%
%   See also API_ICA_SIMILARITY, API_ICA_LINKAGE, API_ICA_QUICKCLUSTER.

% Copyright © 2003-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(1,1,2,3);
api_core_checkarg(c,'c','struct nonempty');
%TODO: Check that fields of c are correct
s=max([c(:).indices]);
api_core_checkarg(S,{'S' 'square matrix nonempty';'S' 'square logical nonempty'});
if ~isequal([s s],size(S)) error('API_ICA_RANK:invalidInput','The size of S must match the one used for clustering!'); end;
if exist('th','var')
  api_core_checkarg(th,{'TH' 'scalar normalized';'MIN' 'scalar integer positive'});
else th=0;
end;

api_core_progress('sub',api_core_l10n('sprintf','Ranking the %i clusters...',numel(c)));
try
  api_core_progress('run',api_core_l10n('Calculating the intra- and inter-cluster similarities.'));
  for i=1:numel(c)
    l=c(i).indices;
    r(i).contribution=numel(l);
    r(i).intra=sum(abs(S(l,l)));
    r(i).inter=sum(abs(S(setdiff(1:s,l),l)));
  end;
  mc=max([r(:).contribution]);
  if mc==0 mc=1; end;
  msi=[r(:).intra];
  msi=[min(msi) max(msi)];
  mso=[r(:).inter];
  mso=[min(mso) max(mso)];
  ms=max(msi(2),mso(2));
  if ms==0 ms=1; end;
  api_core_progress('run',api_core_l10n('sprintf','Intra-cluster similarities are in the range %g - %g.',msi(1),msi(2)));
  api_core_progress('run',api_core_l10n('sprintf','Inter-cluster similarities are in the range %g - %g.',mso(1),mso(2)));
  for i=1:numel(r)
    r(i).contribution=r(i).contribution./mc;
    r(i).intra=r(i).intra./ms;
    r(i).inter=r(i).inter./ms;
    rm=mean(r(i).inter);
    if rm==0 rm=1; end;
    r(i).rank=r(i).contribution*mean(r(i).intra)/rm;
    r(i).include=true;
  end;
  rm=[r(:).rank];
  rm=[min(rm) max(rm)];
  api_core_progress('run',api_core_l10n('sprintf','Cluster ranks are in the range %g - %g.',rm(1),rm(2)));
  if rm(2)==0 rm=1; else rm=rm(2); end;
  [r(i).rank]=deal([r(i).rank]/rm);
  if th>=1 i=find(cellfun(@numel,{c(:).indices})<=th);
  else i=find([r(:).rank]<=th);
  end;
  if ~isempty(i)
    api_core_progress('run',api_core_l10n('sprintf','Excluding %i clusters which leaves %i good clusters.',numel(i),numel(r)-numel(i)));
    [r(i).include]=deal(false);
  end;
catch err
  api_core_error(err);
  r=struct('contribution',{},'intra',{},'inter',{},'rank',{});
end;
api_core_complete('complete',api_core_l10n('Ranking completed.'));
