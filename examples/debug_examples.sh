#!/usr/bin/env bash

##==============================================================================
##                            DEBUG EXAMPLE SCRIPT
##------------------------------------------------------------------------------
#
# @NOTE: The variable naming scheme used in this code is an adaption of Systems 
# Hungarian which is explained at http://pother.ca/VariableNamingConvention/
#
# ------------------------------------------------------------------------------
##
## Usage: debug-example.sh <name> <debug-level>
##
## This script gives an example of how built-in debugging can be implemented in
## a bash script. It offers the infamous "Hello world!" functionality to
## demonstrate it's workings.
##
## This script requires at least one parameter: a string that will be output.
## An optional second parameter can be given to set the debug level.
##
## The default is set to 0, see below for other values:
##
# ==============================================================================

# ==============================================================================
#                               CONFIG VARS
# ------------------------------------------------------------------------------
## DEBUG_LEVEL 0 = No Debugging
## DEBUG_LEVEL 1 = Show Debug messages
## DEBUG_LEVEL 2 = " and show Application Calls
## DEBUG_LEVEL 3 = " and show called command
## DEBUG_LEVEL 4 = " and show all other commands (=set +x)
## DEBUG_LEVEL 5 = Show All Commands, without Debug Messages or Application Calls

readonly DEBUG_LEVEL=${2:-0}
## ==============================================================================


# ==============================================================================
#                                APPLICATION VARS
# ------------------------------------------------------------------------------
# For all options see http://www.tldp.org/LDP/abs/html/options.html
set -o nounset      # Exit script on use of an undefined variable, same as "set -u"
set -o errexit      # Exit script when a command exits with non-zero status, same as "set -e"
set -o pipefail     # Makes pipeline return the exit status of the last command in the pipe that failed

if [ "${DEBUG_LEVEL}" -gt 2 ];then
    set -o xtrace   # Similar to -v, but expands commands, same as "set -x"
fi

declare -a g_aErrorMessages
declare -i g_iExitCode=0
declare -i g_iErrorCount=0
# ==============================================================================


# ==============================================================================
# Displays all lines in main script that start with '##'
# ------------------------------------------------------------------------------
usage() {
    [ "$*" ] && echo "$(basename $0): $*"
    sed -n '/^##/,/^$/s/^## \{0,1\}//p' "$0"
} #2>/dev/null
# ==============================================================================


# ==============================================================================
# Store given message in the ErrorMessage array
# ------------------------------------------------------------------------------
function error() {
    if [ ! -z ${2:-} ];then
        g_iExitCode=${2}
    elif [ ${g_iExitCode} -eq 0 ];then
        g_iExitCode=64
    fi

    g_iErrorCount=$((${g_iErrorCount}+1))

    g_aErrorMessages[${g_iErrorCount}]="${1}\n"

    return ${g_iExitCode};
}
# ==============================================================================


# ==============================================================================
function message() {
# ------------------------------------------------------------------------------
    echo -e "# ${@}" >&1
}
# ==============================================================================


# ==============================================================================
# Output all given Messages to STDERR
# ------------------------------------------------------------------------------
function outputErrorMessages() {
    echo -e "\nErrors occurred:\n\n ${@}" >&2
}
# ==============================================================================


# ==============================================================================
# @see: http://www.tldp.org/LDP/Bash-Beginners-Guide/html/sect_02_03.html
# ------------------------------------------------------------------------------
function debug() {
    echo -e "#[DEBUG] ${1}" >&1
}
# ==============================================================================


# ==============================================================================
# ------------------------------------------------------------------------------
function debugMessage() {
    if [ "${DEBUG_LEVEL}" -gt 0 ] && [ "${DEBUG_LEVEL}" -lt 5 ];then
        debug "${1}"
    fi
}
# ==============================================================================


# ==============================================================================
# ------------------------------------------------------------------------------
function debugTrapMessage {
    debug "[${1}:${2}] ${3}"
}
# ==============================================================================


# ==============================================================================
# ------------------------------------------------------------------------------
function finish() {
    if [ ! ${g_iExitCode} -eq 0 ];then
        outputErrorMessages ${g_aErrorMessages[*]}

        if [ ${g_iExitCode} -eq 65 ];then
            usage
        fi
    fi

    exit ${g_iExitCode}
}

# ==============================================================================


# ==============================================================================
# ------------------------------------------------------------------------------
function registerTraps() {
    trap finish EXIT
    if [ "${DEBUG_LEVEL}" -gt 1 ] && [ "${DEBUG_LEVEL}" -lt 5 ];then
        # Trap function is defined inline so we get the correct line number
        #trap '(echo -e "#[DEBUG] [$(basename ${BASH_SOURCE[0]}):${LINENO[0]}] ${BASH_COMMAND}");' DEBUG
        trap '(debugTrapMessage "$(basename ${BASH_SOURCE[0]})" "${LINENO[0]}" "${BASH_COMMAND}");' DEBUG
    fi
}
# ==============================================================================


# ==============================================================================
# ------------------------------------------------------------------------------
function run() {

    if [ "${DEBUG_LEVEL}" -gt 0 ];then
        message "Debugging on - Debug Level : ${DEBUG_LEVEL}"
    fi

    # Your logic goes here
    if [ "$#" -ne 1 ] && [ "$#" -ne 2 ];then
        g_iExitCode=65
        error 'Wrong parameter count'
        usage
    else
        message "Hello ${1}!"
    fi

}
# ==============================================================================


# ==============================================================================
#                               RUN LOGIC
# ------------------------------------------------------------------------------
registerTraps

if [ ${g_iExitCode} -eq 0 ];then

    run ${@:-}

    if [ ${#g_aErrorMessages[*]} -ne 0 ];then
        outputErrorMessages "${g_aErrorMessages[*]}"
    else
        message 'Done.'
    fi
fi
# ==============================================================================

#EOF