function [out,ft]=api_core_checkfiletype(ftest,varargin)
%API_CORE_CHECKFILETYPE Check or compare filetype structure(s).
%   %TODO: Write help text
%          (ftest) if valid filetype definition list
%          (ftest,'fname') if one or list of filenames matches def
%          output is bool for validity test
%
%   See also API_CORE_DEFFILETYPE.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

api_core_checknarg(0,2,1,Inf);
api_core_checkarg(ftest,'TEST','struct');
res=(numel(fieldnames(ftest))==4)&&all(strcmp(sort(fieldnames(ftest)),sort({'name';'description';'extension';'need'})));
%TODO: Check validity of each field in ftest(:)

ft=[];
if res&&(nargin>1)
  ft={};
  while ~isempty(varargin)
    api_core_checkarg(varargin{1},'FILENAME','str');
    fn=cellstr(varargin{1});
    ft{end+1}=repmat(NaN,1,numel(fn));
    for i=1:numel(fn)
      %TODO: Maybe in the future check that the file paths are atleast syntactically valid
      for j=1:numel(ftest)
        fe=fullfile(fn{i});
        if length(fe)>length(ftest(j).extension)&&strcmp(fe((end-length(ftest(j).extension)):end),['.' ftest(j).extension])
          if exist(fullfile(fn{i}),'file')
            if ~exist(fullfile(fn{i}),'dir')
              ft{end}(i)=j;
              for k=1:numel(ftest(j).need)
                %TODO: Check that all needs are there and if not ft{end}(i)=NaN;
              end;
              if ~isnan(ft{end}(i)) break; end;
            end;
          else
            ft{end}(i)=j;
            break;
          end;
        end;
      end;
    end;
    varargin(1)=[];
  end;
  ft=[ft{:}];
end;

if nargout>0 out=res;
else
  if nargin>1
    if any(isnan(res)) api_core_l10n('fprintf','Not valid filename(s).\n\n');
    elseif numel(res)==1 api_core_l10n('fprintf','Valid filename of type "%s".\n\n',ftest(res).name);
    else api_core_l10n('fprintf','Valid filename(s).\n\n');
    end;
  else
    if res api_core_l10n('fprintf','Valid filetype definition(s).\n\n');
    else
      api_core_l10n('fprintf','Not valid filetype definition(s).\n');
      if exist('err','var') fprintf('  %s\n\n',err); else fprintf('\n'); end;
    end;
  end;
end;
