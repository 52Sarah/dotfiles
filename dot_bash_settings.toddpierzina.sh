#!/usr/bin/env bash

# All "shell settings" and options are placed here, to ba called by .bash_profile
# (or possible .bashrc).

unset TICK_BASH_SETTINGS_USER
if type -t .tick >&/dev/null && [[ -e "$HOME/.tick.bash_settings.$USER" ]]; then
  export TICK_BASH_SETTINGS_USER='~/.bash_settings.$USER'
  .tick_bsu() { .tick -s "$TICK_BASH_SETTINGS_USER" "$@"; }
  .tickeval_bsu() { .tickeval -s "$TICK_BASH_SETTINGS_USER" "$@"; }
else
  # .tick_bsu() { >&2 echo "STDERR> @$"; }
  # .tickeval_bsu() { local p="$1" && shift; >&2 printf "$p" "$(eval "$@")"; }
  .tick_bsu() { :; }
  .tickeval_bsu() { :; }
fi


_bash_settings_set() {

  .tick_bsu "... START set ..."
  .tickeval_bsu 'printf "... set: %d options\n" "$(split-lines ':' <<<"$SHELLOPTS" | wc -l)"'
  .tick_bsu "... SHELLOPTS = $SHELLOPTS" 
  .tick_bsu "... - = $-"

  # Usage: 'set -o name' enables "name" and 'set +o name' disables it. 
  # Some have a single letter equivalent following the same pattern.
  # The list below shows letter and name.
  #
  # Default enabled shell options/variables:
  #   $SHELLOPTS = braceexpand:emacs:hashall:histexpand:history:interactive-comments:monitor
  #   $- = himBH
  #
  # set -B -o braceexpand
    set    +o emacs
  # set +e +o errexit
  # set +E +o errtrace
  # set +T +o functrace
  # set -h -o hashall     # remember command location in history
  # set -H -o histexpand  # !-style history substitution
  # set    -o history
    set    -o ignoreeof   # ctrl-d won't close session
  # set    -o interactive-comments
  # set -m -o monitor     # job control enabled
  # set +C +o noclobber   # "noclobber"--files cannot be overwritten by redirection
  # set +n +o noexec      # read commands but don't execute
  # set +u +o nounset     # treat unset variable substitution as error
  # set +t +o onecmd      # exit after executing one command
  # set +v +o verbose     # print shell lines as they are read
    set    -o vi          # vi-style line editing
  # set +x +o xtrace      # print commands and args as they are executed
  # set -i                # indicates shell is interactive; read-only

  .tick_bsu "... FINISH set ..."
  .tickeval_bsu 'printf "... set: %d options\n" "$(split-lines ':' <<<"$SHELLOPTS" | wc -l)"'
  .tick_bsu "... SHELLOPTS = $SHELLOPTS" 
  .tick_bsu "... - = $-"

}
_bash_settings_set "@"


_bash_settings_shopt() {
  .tick_bsu "... START shopt ..."
  .tickeval_bsu 'printf "... set: %d options\n" "$(shopt -s | wc -l)"'
  .tickeval_bsu 'printf "... set: %s\n" "$(shopt -s | cut -f1 | join-lines ':')"'
  
  # Usage: 'shopt -s optname' enables (SETS) the option; -u (UNSET) disables it.
  # Default enabled options: cdspell:checkwinsize:cmdhist:expand_aliases:extglob:
  #                          extquote:force_fignore:histappend:hostcomplete:interactive_comments:
  #                          login_shell:progcomp:promptvars:sourcepath
  # See: https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
  #
  # shopt -s cdspell                # automatically fix minor typos in dir names
  # shopt -s checkwinsize           # update LINES and COLUMNS after external commands
  # shopt -s cmdhist                # save multi line commands as one history entry
  # shopt -s expand_aliases         # in a non-interactive shell, expand aliases 
  # shopt -s extglob                # use extended pattern matching (https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html)
  # shopt -s extquote               # $'string' and $"string" quoting is performed within ${parameter} expansions
  # shopt -s force_fignore          # even if FIGNORE words are only options, ignore them
  # shopt -s histappend             # history list is appended when shell exits, not overwritten
  # shopt -s hostcomplete
  # shopt -s interactive_comments   
  # shopt -s login_shell            # indicates shell is interactive; read-only
  # shopt -s progcomp               # programmable completion enabled [on by default]
  # shopt -s promptvars             # prompt strings undergo param expansion, etc. [on by default]
  # shopt -s sourcepath             # . uses PATH to find file [on by default]
  #
  # shopt -u cdable_vars            # if cd's arg is not a directory, try it as a variable
    shopt -s checkhash              # check hash table before a normal path search
  # shopt -u compat31               # see https://www.gnu.org/software/bash/manual/html_node/Shell-Compatibility-Mode.html
    shopt -s dotglob                # include files starting with . in glob expansion
  # shopt -u execfail               # a non-interactive shell will not exit if it cannot execute the file given to 'exec'; interactive shells do not exist in this case
  # shopt -u extdebug
  # shopt -u failglob               # patterns matching 0 files result in error
  # shopt -u gnu_errfmt
  # shopt -u histreedit
  # shopt -u histverify
  # shopt -u huponexit              # send SIGHUP to all jobs when shell exits
  # shopt -u lithist                # delimit multi-line commands with \n in history
  # shopt -u mailwarn
  # shopt -u no_empty_cmd_completion
  # shopt -u nocaseglob             # case-insensitive matching during globbing
  # shopt -u nocasematch            # case-insensitive case and [[ commands
  # shopt -u nullglob               # matchless patterns expand to null string, not the pattern
  # shopt -u restricted_shell       # indicates shell is restricted; read-only 
  # shopt -u shift_verbose          # shifting too far results in an error
  # shopt -u xpg_echo               # expand backslash-escape sequences

    .tick_bsu "... FINISH shopt ..."
    .tickeval_bsu 'printf "... set: %d options\n" "$(shopt -s | wc -l)"'
    .tickeval_bsu 'printf "... set: %s\n" "$(shopt -s | cut -f1 | join-lines ':')"'
}
_bash_settings_shopt "$@"


_bash_settings_env() {
  .tick_bsu "... START env ..."
  .tickeval_bsu 'printf "... %d variables\n" "$(env | grep -E '^[A-Za-z_.-].*' | wc -l)"'

  export EDITOR=vim
  export CLICOLOR=1 CLICOLOR_FORCE=1

  # See: https://ss64.com/bash/less.html
  export LESS='--quit-at-eof --quit-if-one-screen --hilite-search --LONG-PROMPT --RAW --squeeze --HILITE-UNREAD --no-init --shift=.25'
  export LESSEDIT='subl --new-window --wait --stay %f\:%lm'


  # Ignore repeated lines and lines starting with ' '
  export HISTCONTROL=ignoreboth
  export HISTSIZE=100000
  export HISTFILESIZE=$HISTSIZE
  export HISTTIMEFORMAT=' %F %T  '

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'

  .tick_bsu "... FINISH env ..."
  .tickeval_bsu 'printf "... %d variables\n" "$(env | grep -E '^[A-Za-z_.-].*' | wc -l)"'
}

alias .reload-bash-settings-user='. "$HOME/.bash_settings.$USER"'
alias .rlbsu='.reload-bash-settings-user'

_bash_settings_env "$@"
