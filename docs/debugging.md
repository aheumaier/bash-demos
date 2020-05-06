# Debugging

Sometimes you want to be able to debug a bash script. 
Follow the following general paragraphs helps to structure and improve readablility. 
Bash is not very easy to debug. There's no built-in debugger like you have with other programming languages. By default, undefined variables are interpreted as empty strings, which can cause problems further down the line. A few tips that may help:

## Writing robust scripts and debugging

- Always check for syntax errors by running the script with `bash -n myscript.sh`
- Use [ShellCheck](https://www.shellcheck.net/) and fix all warnings. This is a static code analyzer that can find a lot of common bugs in shell scripts. Integrate ShellCheck in your text editor (e.g. Syntastic plugin in Vim)
- Abort the script on errors and undbound variables. Put the following code at the beginning of each script.

    ```bash
    set -o errexit   # abort on nonzero exitstatus
    set -o nounset   # abort on unbound variable
    set -o pipefail  # don't hide errors within pipes
    ```

    A shorter version is shown below, but writing it out makes the script more readable.

    ```bash
    set -euo pipefail
    ```

- Use Bash's debug output feature. This will print each statement after applying all forms of substitution (parameter/command substitution, brace expansion, globbing, etc.)
    - Run the script with `bash -x myscript.sh`
    - Put `set -x` at the top of the script
    - If you only want debug output in a specific section of the script, put `set -x` before and `set +x` after the section.
- Write lots of log messages to stdout or stderr so it's easier to drill down to what part of the script contains problematic code. I have defined a few functions for logging, you can find them [in my dotfiles repository](https://github.com/bertvv/dotfiles/blob/master/.vim/UltiSnips/sh.snippets#L52).
- Use [bashdb](http://bashdb.sourceforge.net/)

#### Don't use echo at all 
Instead use set -xv to set debug mode which will echos each and every command. You can set PS4 to the desired prompt: for example PS4='$LINENO: ' will print out the line number on each line. Then, you don't have to clean up your script. To shut off, use set +xv.

#### Use a function
Define a function instead of using echo: 
``` bash 
foo=7
bar=7
PS4='$LINENO: '
set -xv   #Begin debugging
if [ $foo = $bar ]
then
    echo "foo certainly does equal bar"
fi

set +xv   #Debugging is off

if [ $bar = $foo ]
then
    echo "And bar also equals foo"
fi
```

Usually [the `-x` option](http://tldp.org/LDP/abs/html/options.html)
will suffice but sometimes something more sophisticated is needed.

In such instances using [the DEBUG trap](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html) is often a good choice.

Attached to this gist is a example script to demonstrate how such a thing would
work.

To easily demonstrate it's working, the `DEBUG_LEVEL` has been set as a parameter.
In real live situations it would more likely be set as an environmental variable
rather than passed in as a parameter.

## Example output

Below is the output of the script when the script is run with various debug levels:

### Error Output

    $ bash /path/to/debug-example.sh
    
    Errors occurred:
    
     Wrong parameter count
    
    ==============================================================================
                                DEBUG EXAMPLE SCRIPT
    ------------------------------------------------------------------------------
    Usage: debug-example.sh <name> <debug-level>
    
    This script gives an example of how built-in debugging can be implemented in
    a bash script. It offers the infamous "Hello world!" functionality to
    demonstrate it's workings.
    
    This script requires at least one parameter: a string that will be output.
    An optional second parameter can be given to set the debug level.
    The default is set to 0, see below for other values:
    
    DEBUG_LEVEL 0 = No Debugging
    DEBUG_LEVEL 1 = Show Debug messages
    DEBUG_LEVEL 2 = " and show Application Calls
    DEBUG_LEVEL 3 = " and show called command
    DEBUG_LEVEL 4 = " and show all other commands (=set +x)
    DEBUG_LEVEL 5 = Show All Commands, without Debug Messages or Application Calls
    ==============================================================================


### Debug Level 0 (the default)

     $ bash /path/to/debug-example.sh World
    # Hello World!
    # Done.

### Debug Level 1

     $ bash /path/to/debug-example.sh World 1
    # Debugging on - Debug Level : 1
    # Hello World!
    # Done.

### Debug Level 2

     $ bash /path/to/debug-example.sh World 2
    #[DEBUG] [debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]
    #[DEBUG] [debug-example.sh:181] run ${@:-}
    # Debugging on - Debug Level : 2
    # Hello World!
    #[DEBUG] [debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]
    #[DEBUG] [debug-example.sh:186] message 'Done.'
    # Done.
    #[DEBUG] [debug-example.sh:192] echo -e "# ${@}" 1>&1

### Debug Level 3

     $ bash /path/to/debug-example.sh World 3
    + declare -a g_aErrorMessages
    + declare -i g_iExitCode=0
    + declare -i g_iErrorCount=0
    + registerTraps
    + trap finish EXIT
    + '[' 3 -gt 1 ']'
    + '[' 3 -lt 5 ']'
    + trap '(debugTrapMessage "$(basename ${BASH_SOURCE[0]})" "${LINENO[0]}" "${BASH_COMMAND}");' DEBUG
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 179 '[ ${g_iExitCode} -eq 0 ]'
    ++ debug '[debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]'
    ++ echo -e '#[DEBUG] [debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]'
    #[DEBUG] [debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]
    + '[' 0 -eq 0 ']'
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 181 'run ${@:-}'
    ++ debug '[debug-example.sh:181] run ${@:-}'
    ++ echo -e '#[DEBUG] [debug-example.sh:181] run ${@:-}'
    #[DEBUG] [debug-example.sh:181] run ${@:-}
    + run World 3
    + '[' 3 -gt 0 ']'
    + message 'Debugging on - Debug Level : 3'
    + echo -e '# Debugging on - Debug Level : 3'
    # Debugging on - Debug Level : 3
    + '[' 2 -ne 1 ']'
    + '[' 2 -ne 2 ']'
    + message 'Hello World!'
    + echo -e '# Hello World!'
    # Hello World!
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 183 '[ ${#g_aErrorMessages[*]} -ne 0 ]'
    ++ debug '[debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]'
    ++ echo -e '#[DEBUG] [debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]'
    #[DEBUG] [debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]
    + '[' 0 -ne 0 ']'
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 186 'message '\''Done.'\'''
    ++ debug '[debug-example.sh:186] message '\''Done.'\'''
    ++ echo -e '#[DEBUG] [debug-example.sh:186] message '\''Done.'\'''
    #[DEBUG] [debug-example.sh:186] message 'Done.'
    + message Done.
    + echo -e '# Done.'
    # Done.
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 192 'echo -e "# ${@}" 1>&1'
    ++ debug '[debug-example.sh:192] echo -e "# ${@}" 1>&1'
    ++ echo -e '#[DEBUG] [debug-example.sh:192] echo -e "# ${@}" 1>&1'
    #[DEBUG] [debug-example.sh:192] echo -e "# ${@}" 1>&1
    + finish
    + '[' '!' 0 -eq 0 ']'
    + exit 0

### Debug Level 4

     $ bash /path/to/debug-example.sh World 4
    + declare -a g_aErrorMessages
    + declare -i g_iExitCode=0
    + declare -i g_iErrorCount=0
    + registerTraps
    + trap finish EXIT
    + '[' 4 -gt 1 ']'
    + '[' 4 -lt 5 ']'
    + trap '(debugTrapMessage "$(basename ${BASH_SOURCE[0]})" "${LINENO[0]}" "${BASH_COMMAND}");' DEBUG
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 179 '[ ${g_iExitCode} -eq 0 ]'
    ++ debug '[debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]'
    ++ echo -e '#[DEBUG] [debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]'
    #[DEBUG] [debug-example.sh:179] [ ${g_iExitCode} -eq 0 ]
    + '[' 0 -eq 0 ']'
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 181 'run ${@:-}'
    ++ debug '[debug-example.sh:181] run ${@:-}'
    ++ echo -e '#[DEBUG] [debug-example.sh:181] run ${@:-}'
    #[DEBUG] [debug-example.sh:181] run ${@:-}
    + run World 4
    + '[' 4 -gt 0 ']'
    + message 'Debugging on - Debug Level : 4'
    + echo -e '# Debugging on - Debug Level : 4'
    # Debugging on - Debug Level : 4
    + '[' 2 -ne 1 ']'
    + '[' 2 -ne 2 ']'
    + message 'Hello World!'
    + echo -e '# Hello World!'
    # Hello World!
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 183 '[ ${#g_aErrorMessages[*]} -ne 0 ]'
    ++ debug '[debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]'
    ++ echo -e '#[DEBUG] [debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]'
    #[DEBUG] [debug-example.sh:183] [ ${#g_aErrorMessages[*]} -ne 0 ]
    + '[' 0 -ne 0 ']'
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 186 'message '\''Done.'\'''
    ++ debug '[debug-example.sh:186] message '\''Done.'\'''
    ++ echo -e '#[DEBUG] [debug-example.sh:186] message '\''Done.'\'''
    #[DEBUG] [debug-example.sh:186] message 'Done.'
    + message Done.
    + echo -e '# Done.'
    # Done.
    +++ basename /path/to/debug-example.sh
    ++ debugTrapMessage debug-example.sh 192 'echo -e "# ${@}" 1>&1'
    ++ debug '[debug-example.sh:192] echo -e "# ${@}" 1>&1'
    ++ echo -e '#[DEBUG] [debug-example.sh:192] echo -e "# ${@}" 1>&1'
    #[DEBUG] [debug-example.sh:192] echo -e "# ${@}" 1>&1
    + finish
    + '[' '!' 0 -eq 0 ']'
    + exit 0

### Debug Level 5

     $ bash /path/to/debug-example.sh World 5
    + declare -a g_aErrorMessages
    + declare -i g_iExitCode=0
    + declare -i g_iErrorCount=0
    + registerTraps
    + trap finish EXIT
    + '[' 5 -gt 1 ']'
    + '[' 5 -lt 5 ']'
    + '[' 0 -eq 0 ']'
    + run World 5
    + '[' 5 -gt 0 ']'
    + message 'Debugging on - Debug Level : 5'
    + echo -e '# Debugging on - Debug Level : 5'
    # Debugging on - Debug Level : 5
    + '[' 2 -ne 1 ']'
    + '[' 2 -ne 2 ']'
    + message 'Hello World!'
    + echo -e '# Hello World!'
    # Hello World!
    + '[' 0 -ne 0 ']'
    + message Done.
    + echo -e '# Done.'
    # Done.
    + finish
    + '[' '!' 0 -eq 0 ']'
    + exit 0
