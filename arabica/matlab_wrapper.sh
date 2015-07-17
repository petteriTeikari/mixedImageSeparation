#!/bin/bash

# The generic Matlab Wrapper for LONI Pipeline
#
# Usage: matlab_wrapper.sh [-display] [-diary filename] [-command name] [arg1 arg2 arg3 ...]
#   the value for switch -command is the name of a function, a .m|.p|.mex filename or a string
#   containing valid Matlab syntax with %s,%i,%f or %g as placeholders for the arguments
#   any remaining arguments are inserted into the command string with printf
#
# Can also be used by making a symbolic link to the wrapper
#   ln -s matlab_wrapper.sh func
#   func [-display] [-diary filename] [arg1 arg2 arg3 ...]
#
# If diary and/or command is omitted, the script has build in default values.
#
# The following environment variables can also be set to modify default behavior
#   ARABICA_STARTUP is the name of a shell script to source
#   MATLAB_EXE is name or path to the Matlab executable
#   MATLAB_CD is set as the current directory for Matlab
#   MATLAB_STARTUP is the name or path to a Matlab startup script
#   MATLAB_ARGS is extra arguments used when calling Matlab

# Copyright © 2009  Jarkko Ylipaavalniemi
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

#Global default values (config here or set env outside)
ARABICA_STARTUP=${ARABICA_STARTUP:-""};
MATLAB_EXE=${MATLAB_EXE:-"matlab"};
MATLAB_CD=${MATLAB_CD:-""};
MATLAB_STARTUP=${MATLAB_STARTUP:-""};
MATLAB_ARGS=${MATLAB_ARGS:-""};

#Internal default values (config here)
MATLAB_ARGS_DISP="-nosplash -nodesktop"
MATLAB_ARGS_NODISP="-nodisplay"
MATLAB_PATH="";
MATLAB_COMMAND="";
MATLAB_DIARY="";
MATLAB_DISPLAY=0;

# Function build_script()
build_script() {
	if [ "$MATLAB_CD" != "" ]; then
		echo "cd $MATLAB_CD;";
	fi

	if [ "$MATLAB_STARTUP" != "" ]; then
		echo "run $MATLAB_STARTUP;";
	fi

	if [ "$MATLAB_PATH" != "" ]; then
		printf "addpath('%s');\n" $MATLAB_PATH;
	fi

	echo "try";

	if [ "$MATLAB_DIARY" != "" ]; then
		echo "diary $MATLAB_DIARY;";
	fi

	if [ "$MATLAB_COMMAND" != "" ]; then
		if [ `expr "$MATLAB_COMMAND" : ".*[^%]%(s|i|f|g).*"` -eq 0 ]; then
			printf "$MATLAB_COMMAND\n" "$@";
		else
			printf "$MATLAB_COMMAND(%s);\n" "$@";
		fi
	fi

	if [ "$MATLAB_DIARY" != "" ]; then
		echo "diary off;";
	fi

	echo "if ~isempty(getenv('MATLAB_EXITSTATUS')) fprintf(2,'MATLAB_EXITSTATUS=0'); end;";
	echo "catch err";

	if [ "$MATLAB_DIARY" != "" ]; then
		echo "diary off;";
	fi

	echo "if ~isempty(getenv('MATLAB_EXITSTATUS')) fprintf(2,'MATLAB_EXITSTATUS=1'); end;";
	echo "end;";

	if [ $MATLAB_DISPLAY -ne 0 ]; then
		echo "set(0,'ShowHiddenHandles','on'); while ~isempty(get(0,'Children')) uiwait; end;";
	fi

	return 0;
}

if [ $# -gt 0 -a "$1" = "-display" ]; then
	shift;
	MATLAB_DISPLAY=1;
fi

if [ $# -gt 0 -a "$1" = "-diary" ]; then
	shift;
	#TODO: Maybe in the future give an error for invalid path
	MATLAB_DIARY=$1;
	shift;
fi

tempcmd=`basename "$0"`;
tempfun="${tempcmd%%.*}";
if [ "$tempfun" != "matlab_wrapper" ]; then
	MATLAB_COMMAND="$tempfun(%s);";
fi

if [ $# -gt 0 -a "$1" = "-command" ]; then
	shift;
	MATLAB_COMMAND=$1;
	shift;
fi

if [ -f "$MATLAB_COMMAND" ]; then
	tempdir=`dirname "$MATLAB_COMMAND"`;
	if [ "${tempdir%%/*}" != "" ]; then
		curdir=`pwd`;
		tempdir="$curdir/$tempdir";
	fi
	tempcmd=`basename "$MATLAB_COMMAND"`;
	tempfun="${tempcmd%%.*}";
	temptype=`echo "${tempcmd##*.}" | tr 'A-Z' 'a-z'`;
	#TODO: Maybe in the future give an error for unknown file types
	if [ "$temptype" = "m" -o "$temptype" = "p" -o "$temptype" = "mex" ]; then
		MATLAB_COMMAND="$tempfun(%s);";
		if [ "$tempdir" != "" ]; then
			MATLAB_PATH="$MATLAB_PATH $tempdir";
		fi
	fi
fi

if [ $MATLAB_DISPLAY -ne 0 ]; then
	MATLAB_ARGS="$MATLAB_ARGS $MATLAB_ARGS_DISP";
else
	MATLAB_ARGS="$MATLAB_ARGS $MATLAB_ARGS_NODISP";
fi

exec 3>&1;
export MATLAB_EXITSTATUS=0;
materr=`build_script "$@" | eval exec $MATLAB_EXE $MATLAB_ARGS 2>&1 1>&3`;
exec 3>&-;

if [[ "$materr" =~ ^(.*)[[:cntrl:]]*MATLAB_EXITSTATUS=([[:digit:]]+)[[:cntrl:]]*(.*)$ ]]; then
	printf "%s\n%s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}" >&2;
	matreturn=${BASH_REMATCH[2]};
else
	echo "$materr" >&2;
	matreturn=1;
fi

exit ${matreturn:-1};
