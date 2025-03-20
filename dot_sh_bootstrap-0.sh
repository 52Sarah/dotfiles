#!/usr/bin/env zsh

# Shell-agnostic pre-bootstrap functions for all login scripts.
# Functions defined here should not depend on any other startup files.
# No references to tick logging in this file.

# Do not execute this script if it has already been run this session and is not modified since.
if [[ -z "$_DOT_SH_MTIMES" ]]; then
  typeset -A _DOT_SH_MTIMES 2>/dev/null || declare -a _DOT_SH_MTIMES
fi
#
# If sh_file has been executed and has not been changed since, echo true.
# Else echo false (not okay to skip).
sh-ok-to-skip() {
  [[ -z "$1" ]] && >&2 echo 'usage: sh-ok-to-skip SH_FILE' && echo 'false' && return 1
  local sh_file="$1"; shift
  [[ ! -e "$sh_file" ]] && >&2 echo "sh-ok-to-skip: $sh_file: No such file" && echo 'false' && return 1

  # TODO: figure out bash map handling here and in sh-store-mtime
  [[ ! "$SHELL" =~ /zsh$ ]] && echo 'false' && return

  local sh_mtime="$_DOT_SH_MTIMES[$sh_file]"
  [[ -z "$sh_mtime" ]] && echo 'false' && return
  [[ $(stat -L -f '%m' "$sh_file") > sh_mtime ]] && echo 'false' && return
  
  echo 'true'
}
#
sh-store-mtime() {
  [[ -z "$1" ]] && >&2 echo 'usage: sh-store-mtime SH_FILE' && return 1
  local sh_file="$1"; shift
  # TODO: figure out bash map handling here and in sh-store-mtime
  [[ ! "$SHELL" =~ /zsh$ ]] && return
  _DOT_SH_MTIMES+=($sh_file $(stat -L -f '%m' "$sh_file"))
}

if [[ "$(sh-ok-to-skip ~/.sh_bootstrap-0)" != 'true' ]]; then

  is-zsh() {
    [[ "$SHELL" =~ /zsh$ ]]
  }

  # Environment variables used to enable verbose or debug "log" output, or quiet "normal" info output.
  _debug()   { ((_DEBUG)); }
  _verbose() { ((_VERBOSE || _DEBUG)); }
  _quiet()   { ((_QUIET && !(_VERBOSE || _DEBUG))); }

  #
  ### 'echo/printf' helpers
  #   d* = only print to stderr if _DEBUG is set
  #   v* = only print to stderr if _VERBOSE or _DEBUG is set
  #   q* = always print to stderr unless _QUIET is set
  #   e* = always print to stderr
  # usage, e.g.: echo-verbose [--prefix 'line prefix'] text
  #
  echo-stderr()   { >&2 echo $@; }
  echo-error()    { >&2 echo $@; }
  alias eecho=echo-stderr 
  #
  echo-debug()    { _debug && echo-stderr $@; }
  echo-verbose()  { _verbose && echo-stderr $@; }
  echo-quiet()    { _quiet || echo-stderr $@; }
  alias decho=echo-debug vecho=echo-verbose qecho=echo-quiet
  #
  #
  printf-stderr()  { >&2 printf $@; }
  alias eprintf=printf-stderr
  #
  printf-debug()    { _debug && printf-stderr $@; }
  printf-verbose()  { _verbose && printf-stderr $@; }
  printf-quiet()    { _quiet || printf-stderr $@; }
  alias dprintf=printf-debug vprintf=printf-verbose qprintf=printf-quiet

  #
  ### 'echo' / 'eval' helpers
  #
  # Conditionally echo the expression to stderr before executing it, using
  # similar logic as echo-* and printf-*.
  : ${_EVAL_ECHO_PREFIX:=\>$ }
  eval-echo() { 
    local prefix="$_EVAL_ECHO_PREFIX"
    matches "$1" '^-p|--prefix$' ]] && prefix="$2 " && shift 2
    echo-stderr "$prefix$@"
    eval "$@"
  }
  alias eeval=eval-echo
  #
  eval-debug()    { if _debug; then eval-echo $@; else eval "$@"; fi; }
  eval-verbose()  { if _verbose; then eval-echo $@; else eval $@; fi; }
  eval-quiet()    { if _quiet; then eval $@; else eval-echo $@; fi; }
  alias deval=eval-debug veval=eval-verbose qeval=eval-quiet

  # True if $1 is any kind of executable: alias, keyword, function, builtin, file
  is-defined() {
    [[ -z "$1" ]] && echo-stderr "usage: is-defined command" && return 1
    type $1 >&/dev/null
  }

  # Source given file(s). If a file does not exist, echo a non-quiet warning and ignore.
  safe-source() {
    [[ -z "$1" ]] && echo-stderr "usage: safe-source file [...]" && return 1
    while [[ -n "$1" ]]; do
      local script_path="$1"; shift
      if [[ ! -e "$script_path" ]]; then
        _quiet || echo-stderr "safe-source: $script_path: No such file"
      else
        eval-quiet source "$script_path"
      fi
    done
  }

  #
  # Add given path element to the end of the variable, or move it there if already present.
  # usage: path-append [--prepend] [var] path
  path-append() {
    local opt_prepend=; [[ "$1" =~ -p ]] && opt_prepend='--prepend' && shift
    local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
    [[ -z "$1" ]] && echo-stderr "usage: path-append [var] path" && return 1
    
    local elem="$1" && shift
    local elements
    is-zsh && elements="${(P)var}" || elements="${!var}"
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

  # Does $1 match regex $2? Quoting here works for both Zsh and Bash.
  matches() {
    [[ -z "$2" ]] && eecho "usage: matches text pattern" && return 1
    local text="$1" && shift
    local pattern="$*" && shift
    [[ "$text" =~ $pattern ]]
  }

  ### globbing functions
  #
  glob-path-count() {
    [[ -z "$1" ]] && echo-error "usage: glob-path-count patt [...]" && return 1
    local count=0
    if is-zsh; then
      setopt no__NOMATCH
      for p in ${~@}; do
        [[ -e "$p" ]] && ((count++))
      done
    else
      for p in $@; do
        [[ -e "$p" ]] && ((count++))
      done
    fi
    echo $count
  }
  #
  glob-path-exists() {
    [[ -z "$1" ]] && echo-error "usage: glob-path-exists patt" && return 1
    local path_count=$(glob-path-count $@)
    ((path_count > 0)) && return 0 || return 1
  }
  #
  glob-path-first() {
    [[ -z "$1" ]] && echo-error "usage: glob-path-first patt [...]" && return 1
    if is-zsh; then
      setopt no__NOMATCH
      for p in ${~@}; do
        [[ -e "$p" ]] && echo "$p" && return 0
      done
    else
      for p in $@; do
        [[ -e "$p" ]] && echo "$p" && return 0
      done
    fi
    return 1
  }
  
  .reload-bootstraprc() {
    unset "_DOT_SH_MTIMES[sh_bootstraprc]"
    eval-quiet source ~/.sh_bootstraprc
  }

  .reload-shell() {
    unset "_DOT_SH_MTIMES"
    eval-quiet exec $SHELL -l
  }
  alias .rs='eval-verbose .reload-shell'


  .source-extra-start-files() {
    [[ -z "$1" ]] && echo-error "usage: .source-extra-start-files PREFIX" && return 1
    if glob-path-exists "$HOME/$1.*"; then
      for f in $HOME/$1.*; do
        # echo-error ".source-extra-start-files: reading $f"
        [[ "$f" =~ \.zshrc\.bck$ ]] || source "$f"
      done
    fi
  }
  .source-extra-start-files '.sh_bootstrap-0'

  sh-store-mtime ~/.sh_bootstrap-0
fi
