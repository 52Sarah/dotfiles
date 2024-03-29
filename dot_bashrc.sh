#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Our stuff is mainly in .bash_profile since this file is executed for every process.

# Optional pre-script hook.
[[ -e ~/.bashrc_pre ]] && . ~/.bashrc_pre

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# _TICK_x variables control its behavior; all default to false/0/off.
# export _TICK_OFF= _TICK_ON=
# export _TICK_STDERR= _TICK_STDOUT=
type -t .tick >&/dev/null || . ~/.tick.sh
.tick-bashrc() { .tick -s '.bashrc' $@; }

.tick-bashrc "[START-FILE] (\$\$=$$, \$PATH=[$PATH]"

# Private env vars, etc. can be in the optional file ~/.secrets.
[[ -e ~/.secrets ]] && . ~/.secrets

# Put my homemade scripts and other miscellany here at the start of the classpath.
[[ ! "$PATH" =~ $HOME/bin(:|$) ]] && export PATH="$HOME/bin:$PATH"

#
### Define come convenience directories
#
export TTPP_DIR="$HOME/ttpp"
export DOTFILES_DIR="$TTPP_DIR/dotfiles"
export BIN_DIR="$TTPP_DIR/bin"

#
### 'echo/printf' helpers
#   d* = only print to stderr if _DEBUG is set
#   v* = only print to stderr if _VERBOSE or _DEBUG is set
#   q* = always print to stdout unless _QUIET is set
#   e* = always print to stderr
# usage, e.g.: echo-verbose [--prefix 'line prefix'] text
echo-with-prefix() { 
  local prefix=; [[ "$1" =~ ^-p|--prefix$ ]] && prefix="$2" && shift 2
  echo "$prefix$@"
}
echo-prefix() { echo-with-prefix $@; }
#
_debug()   { ((_DEBUG)); }
_verbose() { ((_DEBUG || _VERBOSE)); }
_quiet()   { ((_QUIET && !(_DEBUG || _VERBOSE))); }
_unquiet() { ((! _QUIET)); }
#
echo-stderr() { >&2 echo-with-prefix $@; }
echo-error()  { >&2 echo-with-prefix $@; }
echo-stdout() { echo-with-prefix $@; }
#
echo-debug()    { _debug && echo-with-prefix $@; }
echo-verbose()  { _verbose && echo-with-prefix $@; }
echo-quiet()    { _quiet || echo-with-prefix $@; }
echo-unquiet()  { _quiet || echo-with-prefix $@; }
#
eecho() { echo-error $@; }
decho() { echo-debug $@; }
vecho() { echo-verbose $@; }
qecho() { echo-quiet $@; }
#
decho-stderr() { >&2 echo-debug $@; }
vecho-stderr() { >&2 echo-verbose $@; }
qecho-stderr() { >&2 echo-quiet $@; }
#
eecho-debug()   { >&2 echo-debug $@; }
eecho-verbose() { >&2 echo-verbose $@; }
eecho-quiet()   { >&2 echo-quiet $@; }
eecho-unquiet() { eecho-quiet $@; }
#
#
printf-with-prefix() {
  local prefix=; [[ "$1" =~ -p ]] && prefix="$2" && shift 2
  printf "$prefix$@"
}
#
printf-error()  { >&2 printf-with-prefix $@; }
printf-stderr() { >&2 printf-with-prefix $@; }
printf-stdout() { printf-with-prefix $@; }
#
printf-debug()    { _debug && printf-with-prefix $@; }
printf-verbose()  { _verbose && printf-with-prefix $@; }
printf-quiet()    { ! _quiet && printf-with-prefix $@; }
printf-unquiet()  { printf-quiet $@; }
#
eprintf() { printf-error $@; }
dprintf() { printf-debug $@; }
vprintf() { printf-verbose $@; }
qprintf() { printf-quiet $@; }
#
dprintf-stderr()  { >&2 printf-debug $@; }
eprintf-debug()   { >&2 printf-debug $@; }
vprintf-stderr()  { >&2 printf-verbose $@; }
eprintf-verbose() { >&2 printf-verbose $@; }
qprintf-stderr()  { >&2 printf-quiet $@; }
eprintf-quiet()   { >&2 printf-quiet $@; }

#
### Echo (and bubble) return status ($?) as-is, or use $1 for 0, $2 for non-0.
echo-status() {
  local status=$?
  _debug && eecho-var status
  if ((status == 0)); then
    echo "${1:-0}"
  else
    echo "${2:-$status}"
  fi
  return $status
}
secho()        { echo-status $@; }
eecho-status() { >&2 echo-status $@; }

#
### List all variables on stdout matching $1 (globbing *, etc.) and their values.
#   Return error status if no such variable (as-is or glob expanded) is defined.
echo-glob() {
  [[ -z "$1" ]] && echo-stderr "usage: echo-glob patt [...]" && return 1
  local ret=1
  for patt in $@; do
    [[ ! "$patt" =~ \* ]] && patt="${patt}*"
    local indirect_vars="$(eval echo $(printf "\${!%s}" "$patt"))"
    [[ -z "$indirect_vars" ]] && printf '%s=\n' "$patt" && continue
    local IFS=' '
    for var in $indirect_vars; do
      printf "%s=%s\n" "$var" "${!var}"
      ret=0
    done
  done
  return $ret
}
gecho() { echo-glob $@; }
eecho-glob() { >&2 echo-glob $@; }
decho-glob() { _debug && echo-glob $@; }
vecho-glob() { _verbose && echo-glob $@; }
qecho-glob() { _quiet || echo-glob $@; }
#
# Replace newlines, carriage-returns and tabs with \n, \r and \t.
echo-unescape() {
  if [[ ! -t 0 ]]; then
    sed -E -n 'l;' \
    | join-lines '\\n' \
    | sed -E 's/\$(\\n)/\1/g; s/\$$//g;'
    return 0;
  fi
  [[ -z "$1" ]] && eecho 'usage: echo-unescape text [...] or echo-unescape <<< text' && return 1
  echo-unescape <<< $@
}
#
echo-var() {
  [[ -z "$1" ]] && echo-error usage: echo-var varname [...]
  local var value
  while [[ -n "$1" ]]; do
    var="$1"; shift 1
    value="${!var}"
    echo "$var: $value"
  done
}
eecho-var() { >&2 echo-var $@; }
decho-var() { _debug && echo-var $@; }
vecho-var() { _verbose && echo-var $@; }
qecho-var() { _quiet || echo-var $@; }


#
### 'echo' / 'eval' helpers
#
# Always ECHO the given expression; but do not EVAL if _EVAL_WHATIF is set.
: ${_WHATIF_PREFIX:=#$}
eval-whatif() { ((_EVAL_WHATIF)) && echo "$_WHATIF_PREFIX" $@ || eval-echo $@; }
weval() { eval-whatif $@; }
#
# Conditionally echo the expression to stderr before executing it, using
# similar logic as echo-* and printf-*.
: ${_EVAL_ECHO_PREFIX:=\>$}
eval-echo() { 
  local _EVAL_ECHO_PREFIX=$_EVAL_ECHO_PREFIX
  [[ "$1" =~ ^-p|--prefix$ ]] && _EVAL_ECHO_PREFIX="$2" && shift 2
  >&2 echo "$_EVAL_ECHO_PREFIX $@"; 
  eval "$@"
}
eval-stderr()   { eval-echo $@; }
eval-error()    { eval-echo $@; }
eval-debug()    { if _debug; then eval-echo $@; else eval "$@"; fi; }
eval-verbose()  { if _verbose; then eval-echo $@; else eval $@; fi; }
eval-quiet()    { if _quiet; then eval $@; else eval-echo $@; fi; }
eval-unquiet()  { eval-quiet $@; }
#
eeval() { eval-echo $@; }
deval() { eval-debug $@; }
veval() { eval-verbose $@; }
qeval() { eval-quiet $@; }


# Source given file(s). If a file does not exist, echo-unquiet a warning and ignore.
safe-source() {
  local _QUIET=$_QUIET; [[ "$1" =~ ^-q|--quiet$ ]] && _QUIET=1 && shift 1
  [[ -z "$1" ]] && echo-stderr "usage: safe-source [--quiet] file [...]" && return 1

  while [[ -n "$1" ]]; do
    local script_path="$1"; shift
    if [[ ! -e "$script_path" ]]; then
      ! ((_quiet)) && echo-stderr "safe-source: $script_path: No such file"
    else
      eval-quiet . "$script_path"
    fi
  done
}

#
### du helpers
#
du-dir() {
  local USAGE="usage: du-dir [--depth n] [--units h|k|m|:properties :start  --info  --no-build-cache --no-configuration-cache --no-configure-on-demand] [dir]"
  local depth=1 units='h' dir='.'
  while [[ "$1" ]]; do case "$1" in
    -d|--depth) depth="$2" && shift 2;;
    -u|--units) units="$2" && shift 2;;
    *)          dir="${1:-$dir}" && shift 1 && break;;
  esac; done
  [[ ! -d "$dir" ]] && printf-stderr "du-dir: %s: no such directory\n%s\n" "$dir" "$USAGE" && return 1
  find -L "$dir" -type dir -d $depth -exec du -s -$units {} \;
}

#
### array/lines helpers
#
join-array() {
  local delim="$1" && shift
  local i_first=1
  decho-var delim i_first $@
  for i in $@; do
    vecho-var i
    [[ -n "$i_first" ]] && printf "%s" "$i" && unset i_first || printf "%s%s" "$delim" "$i"
  done
  printf '\n'
}
#
uniq-array() {
  local i_first=1
  decho-var delim i_first $@
  local buff=
  for i in $@; do
    vecho-var i
    if (( i_first )); then
      buff="$i"
      unset i_first
    else
        bu  ff="$(printf '%s\n%s' "$buff" "$i")"
    fi
  done
  echo "$buff" | sort -s | uniq
}
#
# Concatenate trimmed lines from stdin onto a single line, delimited by $1 (or '')
join-lines() {
    delim="${1:-}"
    sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
}
# Split line(s) from stdin into separate lines, using $1 [,] as delimiter
split-lines() {
    local delim="${1:-,}"
    sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
}


#
### path helpers
#
# List path variable's elements, 1 per line.
path-list() {
  local var=${1:-PATH}
  split-lines ':' <<< "${!var}"
}
path-echo() { qeval path-list $@; }
#
# Add given path element to the end of the variable, or move it there if already present.
# usage: path-append [--prepend] [var] path
path-append() {
  local opt_prepend=; [[ "$1" =~ -p ]] && opt_prepend='--prepend' && shift
  local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
  [[ -z "$1" ]] && echo-stderr "usage: path-append [var] path" && return 1
  
  local elem="$1" && shift
  local elements="${!var}"
  if [[ -z "$elements" ]]; then
    export $var="$elem"
    return 0
  elif [[ "$elements" = "$elem" ]]; then
    return 0
  fi

  elems_minus_elem="$(sed -e 's!:'"$elem"':!:!g' <<< ":$elements:")"
  echo-debug "elems_minus_elem=[$elems_minus_elem]"
  printf-debug "$_EVAL_ECHO_PREFIX path-append %s %s %s\n" "$opt_prepend" "$var" "$elem" && eeval path-list elems_minus_elem
  if ((opt_prepend)); then
    eval-debug export $var="$elem${elems_minus_elem:0:((${#elems_minus_elem}-1))}"
  else
    eval-debug export $var="${elems_minus_elem:1}$elem"
  fi
}
path-prepend() { path-append --prepend $@; }


# The following functions operate on stdin OR $@; [[ -t 0 ]] is true if stdin is a terminal
# from: https://stackoverflow.com/a/30520299
#
ends_with() {
  [[ -z "$2" ]] && echo-error "usage: ends_with [--verbose] text suffix_to_test" && return 1
  [[ "$1" =~ .*$2$ ]]
}
starts_with() {
  [[ -z "$2" ]] && echo-error "usage: starts_with [--verbose] text prefix_to_test" && return 1
  [[ "$1" =~ ^$2.*$ ]]
}
trim() {
  [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g' && return 0
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
substring_before_first() {
  local delim='.'; [[ "$1" =~ --delim|-d ]] && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line%%${delim}*}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_before_first [--delim DELIM] text [DELIM], or ... | substring_before_first [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_before_first --delim "$delim" <<< "$1"
}
substring_before_last() {
  local delim='.'; [[ "$1" =~ --delim|-d ]] && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line%${delim}*}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_before_last [--delim DELIM] text [DELIM], or ... | substring_before_last [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_before_last --delim "$delim" <<< "$1"
}
substring_after_first() {
  local delim='.'; [[ "$1" =~ --delim|-d ]] && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line#*${delim}}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_after_first [--delim DELIM] text [DELIM], or ... | substring_after_first [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_after_first --delim "$delim" <<< "$1"
}
substring_after_last() {
  local delim='.'; [[ "$1" =~ --delim|-d ]] && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line##*${delim}}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_after_last [--delim DELIM] text [DELIM], or ... | substring_after_last [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_after_last --delim "$delim" <<< "$1"
}
#
# Expand '~' to value of $HOME, or compress value of $HOME to ~
tilde-compress() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'tilde-compress' '${path//$HOME/\~}' $@ && return 0
  [[ -z "$1" ]] && eecho "usage: tilde-compress path [...]" && return 1
  tilde-compress <<< $@
}
tilde-expand() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'tilde-expand' '${path//\~/$HOME}' && return 0
  [[ -z "$1" ]] && eecho "usage: tilde-expand path [...]" && return 1
  tilde-expand <<< $@
}
#
# Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
home-compress() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'home-compress' '${path//$HOME/\$HOME}' $@ && return 0
  [[ -z "$1" ]] && eecho "usage: home-compress path [...]" && return 1
  home-compress <<< $@
}
home-expand() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'home-expand' '${path//\$HOME/$HOME}' $@ && return 0
  [[ -z "$1" ]] && eecho "usage: home-expand path [...]" && return 1
  home-expand <<< $@
}
#
# Convert stdin using the path_expr
tilde-home-compress-expand() {
  [[ -z "$2" ]] && eecho "usage: tilde-home-compress-expand ${1:-fn_name} path_expr" && return 1
  local fn_name="$1" && shift
  local path_expr="$1" && shift

  local delim= path=
  while read path; do
    printf '%s%s' "$delim" "$(eval "echo $path_expr")"
    delim=' '
  done
  printf '\n'
}


alias .reload-bashrc='qeval . ~/.bashrc'
alias .rlbrc='qeval .reload-bashrc'
alias .rlbr='qeval .reload-bashrc'

# Optional post-script hook.
[[ -e ~/.bashrc_post ]] && . ~/.bashrc_post

.tick-bashrc "[END-FILE] (\$\$=$$, \$PATH=[$PATH])"
