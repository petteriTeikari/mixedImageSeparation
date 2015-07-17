function arabica_wrapper(type,pkg,name,varargin)
%ARABICA_WRAPPER LONI Pipeline Wrapper for Arabica Toolbox.
%   ARABICA_WRAPPER(TYPE,PACKAGE,NAME,...) validates and evaluates the
%   specified module using the shell command-line syntax defined by LONI
%   Pipeline. TYPE must be one of 'module', 'wrap' or 'wizard' and the
%   PACKAGE, NAME pair defines the package and module names, respectively.
%   All following arguments are forwarded to the module as they are.
%
%   NOTE: This function automatically performs initialization if necessary.
%   When called by the arabica_wrapper shell script this function
%   automatically performs uninitialization and waits until all
%   visualizations are closed.
%
%   See also ARABICA, ARABICA_VERSION.

% Copyright © 2008-2009  Jarkko Ylipaavalniemi
% License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
% This is free software: you are free to change and redistribute it. 
% There is NO WARRANTY, to the extent permitted by law.

%TODO: Maybe in the future optimize init by only asking for the named package
success=arabica_init('pipe');
if success
  success=false;
  api_core_checknarg(0,0,3,Inf);
  type=api_core_checkopt(type,'TYPE','module','wrap','visualize','wizard');
  api_core_checkarg(pkg,'PACKAGE','str');
  api_core_checkarg(name,'NAME','str');

  pid=api_core_progress('arabica_wrapper','new');
  api_core_progress('addhandler','pipe');
  [st,host]=system('hostname');
  if st~=0 host='localhost'; end;
  api_core_progress('sub',api_core_l10n('sprintf','Running LONI Pipeline wrapper in host %s...',host));
  try
    %TODO: Maybe in the future support package and/or module versions in strings
    mod=api_core_modules('type',type,'package',pkg,'name',name);
    if isempty(mod) api_core_error(api_core_l10n('sprintf','Required module "%s" is not among the initialized modules!',name));
    else
      mod=mod(end);
      api_core_progress('run',api_core_l10n('sprintf','Found %s "%s" version "%i.%i" in package "%s".',mod.type,mod.version.name,mod.version.major,mod.version.minor,mod.version.container));
      api_core_progress('sub',api_core_l10n('Validating module parameters...'));
      try
        [params,args]=mod.entry(mod,'validate',varargin{:});
        success=isstruct(params);
      catch err
        api_core_error(err);
        success=false;
      end;
      if ~success api_core_error(api_core_l10n('sprintf','Cannot validate module parameters!')); end;
      api_core_complete('complete',api_core_l10n('sprintf','Validated %i parameters with %i leftovers.',numel(params),numel(args)));
      api_core_progress('sub',api_core_l10n('Evaluating module...'));
      try
        success=mod.entry(mod,'evaluate',params,args{:});
      catch err
        api_core_error(err);
        success=false;
      end;
      if ~success api_core_error(api_core_l10n('sprintf','Cannot evaluate module!')); end;
      api_core_complete('complete',api_core_l10n('Module evaluation completed.'));
    end;
  catch err
    api_core_error(err);
    success=false;
  end;
  api_core_complete('complete',api_core_l10n('LONI Pipeline wrapper completed.'));
  api_core_complete('complete');
  api_core_progress(pid,'destroy');
end;

if ~isempty(getenv('MATLAB_EXITSTATUS'))
  fprintf(2,'MATLAB_EXITSTATUS=%i\n',~success);
  if success&&any(strcmp(type,{'visualize' 'wizard'}))&&api_core_isdesktop
    set(0,'ShowHiddenHandles','on');
    while ~isempty(get(0,'Children'))
      try
        uiwait;
      catch err
        fprintf(2,api_core_l10n('Error: Cannot wait until all figures are closed: %s\n',err.message));
        break;
      end;
    end;
  end;
  
  %NOTE: The success or unsuccess of uninitialization will not affect the reported status
  pid=api_core_progress('arabica_uninit','new');
  api_core_progress('addhandler','pipe');
  try
    success=api_core_init('uninitialize');
  catch err
    api_core_error(err);
    success=false;
  end;
  api_core_complete('complete');
  api_core_progress(pid,'destroy');
end;
