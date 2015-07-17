#!/bin/bash

# The Arabica Matlab Wrapper for LONI Pipeline
#
# Usage: arabica_wrapper.sh [-<type> module] [arg1 arg2 arg3 ...]
#   where <type> must be one of module, wrap, visualize or wizard
#   the value for switch -<type> is the module name
#   any remaining arguments are forwarded to the wrapper inside Matlab
#
# Can also be used by making a symbolic link to the wrapper
#   ln -s arabica_wrapper.sh module
#   module [-<type>] [arg1 arg2 arg3 ...]
#
# The module name can be in the form "package/module" and the symbolic link can
# also contain the package name and even <type> as parent directories
# [type/]package/module. If package and or <type> is omitted, the script has
# build in default values.
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
ARABICA_TYPE="module";
ARABICA_PACKAGE="core";
ARABICA_MODULE="";

# Function build_script()
build_script() {
	if [ "$MATLAB_CD" != "" ]; then
		echo "cd $MATLAB_CD;";
	fi

	if [ "$MATLAB_STARTUP" != "" ]; then
		echo "run $MATLAB_STARTUP;";
	fi

	if [ "$ARABICA_MODULE" != "" ]; then
		printf "arabica_wrapper('%s','%s','%s'%s);\n" "$ARABICA_TYPE" "$ARABICA_PACKAGE" "$ARABICA_MODULE" "$ARABICA_ARGS";
	fi

	return 0;
}

if [ "$ARABICA_STARTUP" != "" ]; then
	source "$ARABICA_STARTUP";
fi

tempcmd=`basename "$0"`;
tempfun="${tempcmd%%.*}";
if [ "$tempfun" != "arabica_wrapper" ]; then
	ARABICA_MODULE=$tempfun;
	tempfun=`dirname "$0"`;
	temppkg=`basename "$tempfun"`;
	if [ "$temppkg" != "." ]; then
		ARABICA_PACKAGE=$temppkg;
	fi
	tempfun=`dirname "$tempfun"`;
	temptype=`basename "$tempfun"`;
	if [ "$temptype" = "-module" -o "$temptype" = "-wrap" -o "$temptype" = "-visualize" -o "$temptype" = "-wizard" ]; then
		ARABICA_TYPE=$temptype;
	elif [ "$1" = "-module" -o "$1" = "-wrap" -o "$1" = "-visualize" -o "$1" = "-wizard" ]; then
			ARABICA_TYPE=${1#-};
			shift
	fi
else
	if [ "$1" = "-module" -o "$1" = "-wrap" -o "$1" = "-visualize" -o "$1" = "-wizard" ]; then
		ARABICA_TYPE=${1#-};
		shift
		ARABICA_MODULE=`basename "$1"`;
		tempfun=`dirname "$1"`;
		temppkg=`basename "$tempfun"`;
		if [ "$temppkg" != "." ]; then
			ARABICA_PACKAGE=$temppkg;
		fi
		shift;
	fi
fi

ARABICA_ARGS="";
while [ $# -gt 0 ]; do
	ARABICA_ARGS="$ARABICA_ARGS,'$1'";
	shift;
done

if [ "$ARABICA_TYPE" = "visualize" -o "$ARABICA_TYPE" = "wizard" ]; then
	MATLAB_ARGS="$MATLAB_ARGS $MATLAB_ARGS_DISP";
else
	MATLAB_ARGS="$MATLAB_ARGS $MATLAB_ARGS_NODISP";
fi

exec 3>&1;
export MATLAB_EXITSTATUS=0;
materr=`build_script | eval exec $MATLAB_EXE $MATLAB_ARGS 2>&1 1>&3`;
exec 3>&-;

if [[ "$materr" =~ ^(.*)[[:cntrl:]]*MATLAB_EXITSTATUS=([[:digit:]]+)[[:cntrl:]]*(.*)$ ]]; then
	printf "%s\n%s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}" >&2;
	matreturn=${BASH_REMATCH[2]};
else
	echo "$materr" >&2;
	matreturn=1;
fi

exit ${matreturn:-1};
