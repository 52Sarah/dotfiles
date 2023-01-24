#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Our stuff is mainly in .bash_profile since this file is executed for every process.

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# TICK_x variables control its behavior; all default to false/0/off.
# export TICK_ENABLED= TICK_STDERR= TICK_STDOUT=
type -t .tick >&/dev/null || . ~/.tick.sh
.tick-bashrc() { .tick -s '.bashrc' "$@"; }

.tick-bashrc "[START-FILE] (\$\$=$$, \$PATH=[$PATH]"


# Put my homemade scripts and other miscellany here at the start of the classpath.
[[ ! "$PATH" =~ $HOME/bin(:|$) ]] && export PATH="$HOME/bin:$PATH"


#
### 'echo' helpers
#   v* = never print unless SH_VERBOSE is set
#   q* = always print unless SH_QUIET is set
#   e* = always print but also to error
echo-verbose()  { ((SH_VERBOSE)) || return 0; echo "$@"; }
echo-quiet()    { ((SH_QUIET)) && return 0; echo "$@"; }
echo-error()    { >&2 echo "$@"; }
#
vecho() { echo-verbose "$@"; }
qecho() { echo-quiet "$@"; }
eecho() { echo-error "$@"; }

#
### 'printf' helpers, same logic as 'echo' helpers above
#
printf-verbose()  { ((SH_VERBOSE)) || return 0; printf "$@"; }
printf-quiet()    { ((SH_QUIET)) && return 0; printf "$@"; }
printf-error()    { >&2 printf "$@"; }
#
vprintf() { printf-verbose "$@"; }
qprintf() { printf-quiet "$@"; }
eprintf() { printf-error "$@"; }

#
### 'echo'/'eval' helpers
#
# Conditionally echo the expression to stderr before executing it, using similar logic as echo-* and printf-*.
: ${EVAL_ECHO_PREFIX:=\>$}
eval-echo()     { >&2 echo "$EVAL_ECHO_PREFIX $@"; eval "$@"; }
eval-verbose()  { >&2 echo-verbose "$EVAL_ECHO_PREFIX $@"; eval "$@"; }
eval-quiet()    { >&2 echo-quiet "$EVAL_ECHO_PREFIX $@"; eval "$@"; }
eval-error()    { >&2 echo-error "$EVAL_ECHO_PREFIX $@"; eval "$@"; }
#
veval() { eval-verbose "$@"; }
qeval() { eval-quiet "$@"; }
eeval() { eval-error "$@"; }

#
### path helpers
#
# Add given path element to the beginning of the variable, or move it there if already present.
# usage: path-prepend [var] path
path-prepend() {
  local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
  local elem="$1" && shift
  local elements="${!var}"
  [[ -z "$elements" ]] && export $var="$elem" && return 0
  [[ "$elements" = "$elem" ]] && return 0
  deduped_elems="$(sed -e 's!:'"$elem"':!:!g' <<< ":$elements:")"
  # eprintf 'path-prepend:\n  var=%s\n  elem=%s\n  elements=%s\n  deduped_elems=%s\n' "$var" "$elem" "$elements" "$deduped_elems"
  export $var="$elem${deduped_elems:0:-1}"
}

# The following functions operate on stdin OR "$@"; [[ -t 0 ]] is true if stdin is a terminal
# from: https://stackoverflow.com/a/30520299
#
trim() {
  [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: trim str [...], or ... | trim" && return 1
  trim <<< $@
}
rtrim() {
  [[ ! -t 0 ]] && sed -E -e 's/(.*)[[:space:]]*/\1/g' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: rtrim str [...], or ... | rtrim" && return 1
  rtrim <<< $@
}
ltrim() {
  [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)/\1/g' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: ltrim str [...], or ... | ltrim" && return 1
  ltrim <<< $@
}
#
upper() {
  [[ ! -t 0 ]] && tr '[:lower:]' '[:upper:]' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: upper word [...], or ... | upper" && return 1
  upper <<< $@
}
lower() {
  [[ ! -t 0 ]] && tr '[:upper:]' '[:lower:]' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: lower word [...], or ... | lower" && return 1
  lower <<< $@
}

# Source given file(s). If a file does not exist, echo-quiet a warning and ignore.
# Usage: safe-source [--quiet] file [...]
safe-source() {
  local SH_QUIET=$SH_QUIET
  [[ "$1" =~ ^(-q|--quiet)$ ]] && SH_QUIET=1 && shift
  [[ -z "$1" ]] && echo-error "usage: safe-source [--quiet] file [...]" && return 1
  while [[ -n "$1" ]]; do
    local script_path="$1"; shift
    if [[ ! -e "$script_path" ]]; then
      ((! SH_QUIET)) && echo-error "safe-source: $script_path: No such file"
    else
      eval-quiet . "$script_path"
    fi
  done
}


# Expand '~' to value of $HOME, or compress value of $HOME to ~
tilde-compress() {
  [[ -z "$1" ]] && eecho "usage: tilde-compress path [...]" && return 1
  tilde-home-compress-expand 'tilde-compress' '${path/$HOME/\~}' $@
}
tilde-expand() {
  [[ -z "$1" ]] && eecho "usage: tilde-expand path [...]" && return 1
  tilde-home-compress-expand 'tilde-expand' '${path/\~/$HOME}' $@
}
#
# Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
home-compress() {
  [[ -z "$1" ]] && eecho "usage: home-compress path [...]" && return 1
  tilde-home-compress-expand 'home-compress' '${path/$HOME/\$HOME}' $@
}
home-expand() {
  [[ -z "$1" ]] && eecho "usage: home-expand path [...]" && return 1
  tilde-home-compress-expand 'home-expand' '${path/\$HOME/$HOME}' $@
}
#
tilde-home-compress-expand() {
  local fn_name="$1" && shift
  local expr="$1" && shift
  [[ -z "$1" ]] && eecho "usage: ${fn_name:-fn_name} path [...]" && return 1
  local delim=
  while [[ -n "$1" ]]; do
    local path="$1" && shift
    printf '%s%s' "$delim" "$(eval "echo $expr")"
    delim=' '
  done
  printf '\n'
}


alias .reload-bashrc='qeval . ~/.bashrc'

.tick-bashrc "[END-FILE]   (\$\$=$$, \$PATH=[$PATH])"
