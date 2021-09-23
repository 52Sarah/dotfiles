#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Non-interactive shells read the $BASH_ENV file, if any (this file).

# Simple login file debugging, enabled if caller checks that ~/.tick.LOGINSCRIPT exists 
# and sets prefix accordingly.
type -t .tick >&/dev/null || . ~/.bashrc_tick

# Usage: .tick_bru -s script_name [message [...]]
if type -t .tick >&/dev/null && [[ -e "$HOME/.tick.bashrc.$USER" ]]; then
  TICK_BASHRC_USER='~/.bashrc.$USER'
  .tick_bru() { .tick -s "$TICK_BASHRC_USER" "$@"; }
  .tickeval_bru() { .tickeval -s "$TICK_BASHRC_USER" "$@"; }
else
  unset TICK_BASHRC_USER
  .tick_bru() { :; }
  .tickeval_bru() { :; }
fi

.bashrc_USER() {

  # reduce the number of "start" messages
  if [[ "$PID_PPID_BRU" != "$$,$PPID" ]]; then
    export PID_PPID_BRU="$$,$PPID"
    .tickeval_bru 'printf -- "START PID,PPID=%s \$SHLVL=%s \$_=[%s] \$-=[%s]\n" "$PID_PPID_BRU" "$SHLVL" "$_" "$-"'
  fi

  export TODAY_YYYYMMDD="$(date +'%Y%m%d')"
  export TODAY_MMDD="$(date +'%m%d')"

  # conditional echoes, used for debugging all over
  vecho() { ((SH_VERBOSE)) && echo "$@"; return 0; }
  qecho() { ((! SH_QUIET)) && echo "$@"; return 0; }
  eecho() { >&2 echo "$@"; return 0; }  # to stderr

  # echo command before executing it via eval
  eeval() {
    [[ -z "$1" ]] && return 1
    echo ">\$ $*"
    eval $*
  }

  # Add given path element to the beginning of the variable, unless already present.
  prepend-path() {
    local var=PATH
    [[ -n "$2" ]] && var="$1" && shift
    [[ ! "${!var}" =~ $1[:$] ]] && export $var="$1:${!var}"
  }

  # List path variable's elements, one per line
  echo-path() {
    local var=${1:-PATH}
    split-lines ':' <<< "${!var}" | tilde-compress
  }
  alias pecho=echo-path

  # List all variables and values matching $1.
  echo-glob() {
    local patt="$1" && [[ -z "$patt" ]] && >&2 echo "usage: echo-glob patt" && return 1
    for v in $(eval "echo $(printf "\${!%s}" "$patt")"); do
      printf "%s: %s\n" "$v" "${!v}"
    done
  }
  alias gecho=echo-glob


  # The following functions operate on stdin OR $*; [[ -t 0 ]] is true if stdin is a terminal
  # from: https://stackoverflow.com/a/30520299
  #
  # Compress '~' to value of $HOME, or vice versa.
  tilde-compress() {
    [[ ! -t 0 ]] && sed -E -e "s:\\$HOME:\\~:g" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: tilde-compress path [...], or ... | tilde-compress" && return 1
    tilde-compress <<< "$*"
  }
  tilde-expand() {
    [[ ! -t 0 ]] && sed -E -e "s:\\~:$HOME:g" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: tilde-expand path [...], or ... | tilde-expand" && return 1
    tilde-expand <<< "$*"
  }
  #
  trim() {
    [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: trim str [...], or ... | trim" && return 1
    trim <<< "$*"
  }
  rtrim() {
    [[ ! -t 0 ]] && sed -E -e 's/(.*)[[:space:]]*/\1/g' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: rtrim str [...], or ... | rtrim" && return 1
    rtrim <<< "$*"
  }
  ltrim() {
    [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)/\1/g' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: ltrim str [...], or ... | ltrim" && return 1
    ltrim <<< "$*"
  }
  #
  upper() {
    [[ ! -t 0 ]] && tr '[:lower:]' '[:upper:]' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: upper word [...], or ... | upper" && return 1
    upper <<< "$*"
  }
  lower() {
    [[ ! -t 0 ]] && tr '[:upper:]' '[:lower:]' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: lower word [...], or ... | lower" && return 1
    lower <<< "$*"
  }

  # Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
  join-lines() {
    local delim="${1:-, }" && shift
    local not1st=0
    sed -E -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/;' | \
      while read -r ln; do
        ((not1st)) && printf "$delim" || not1st=1
        printf "%s" "$ln"
      done && \
      printf '\n'
  }
  # Split line(s) from stdin into separate lines, using $1 [,] as delimiter
  split-lines() {
      local delim="${1:-,}"
      sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
  }

  # Usage: [ms places] [format]
  datetime-plus-ms() {
    local places="${1:-3}" && shift
    local format="${1:-%D %T}" && shift
    local ms="$(perl - <<-'EOF'
      use Time::HiRes qw(time);
      my $t = time;
      printf "%06d\n", ($t - int($t)) * 1000000;
  EOF
  )00000"
    date +"$format.${ms:0:$places}"
  }

  # Put Ruby 3 in front of system's 2.6
  # Put my homemade scripts and other miscellany here at the start of the classpath.
  .tick_bru 'adding ruby/bin, ~/bin and ~ to PATH'
  prepend-path PATH "/usr/local/opt/gnu-tar/libexec/gnubin"
  prepend-path PATH "/usr/local/opt/ruby/bin"
  prepend-path PATH "$HOME/bin"
  prepend-path PATH "$HOME"


  alias .reload-bashrc-user='. $HOME/.bashrc.$USER'
  alias .rlbru='.reload-bashrc-user'

  # .tickeval_bru 'printf -- "FINISH PID,PPID=[%s]\n" "$PID_PPID_BRU"'
}
.bashrc_USER "$@" && unset -f .bashrc_USER
