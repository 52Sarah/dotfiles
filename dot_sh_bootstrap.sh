#!/usr/bin/env zsh

# Shell-agnostic mimimal bootstrap functions for all login scripts.
# Functions defined here do not depend on any other startup files.
# No references to tick logging in this file.
#
# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

is-zsh() {
  [[ "$SHELL" =~ /zsh$ ]]
}

dot-ok-to-skip() {
  [[ -z "$1" ]] && >&2 echo 'usage: dot-ok-to-skip dot_file' && return 1
  
  local dot_file="$1"
  [[ ! -e "$dot_file" ]] && >&2 echo "dot-ok-to-skip: $dot_file: No such file" && return 1

  (( _DOT_MTIMES_IGNORE )) && return 1

  # TODO: figure out bash map handling here and in dot-store-mtime
  is-zsh || return 1

  local sh_mtime="$_DOT_MTIMES[$dot_file]"
  [[ -z "$sh_mtime" ]] && return 1
  (( $(stat -L -f '%m' "$dot_file") > $sh_mtime )) && return 1
}
dot-store-mtime() {
  [[ -z "$1" ]] && >&2 echo 'usage: dot-store-mtime dot_file' && return 1

  local dot_file="$1"
  [[ ! -e "$dot_file" ]] && >&2 echo "dot-ok-to-skip: $dot_file: No such file" && return 1

  # TODO: figure out bash map handling here and in dot-store-mtime
  is-zsh || return 1

  _DOT_MTIMES+=($(basename $dot_file) $(stat -L -f '%m' "$dot_file"))
}
dot-reset-mtimes() {
  typeset -g -A _DOT_MTIMES
}
[[ -z "$_DOT_MTIMES" ]] && dot-reset-mtimes

sh-bootstrap-wrapper() {
  local dot_fname='.sh_bootstrap'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-bootstrap() {
    unset "_DOT_MTIMES[.sh_bootstrap]"
    eval-quiet source ~/.sh_bootstrap
  }


  #
  # Environment variables used to enable verbose or debug "log" output, or quiet "normal" info output.
  #
  _debug()   { ((_DEBUG)); }
  _verbose() { ((_VERBOSE || _DEBUG)); }
  _quiet()   { ((_QUIET && !(_VERBOSE || _DEBUG))); }

  #
  ### 'echo/printf' helpers
  #   d* = only print to stderr if _DEBUG is set
  #   v* = only print to stderr if _VERBOSE or _DEBUG is set
  #   q* = always print to stderr unless _QUIET is set
  #   e* = always print to stderr
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
  printf-stderr()  { >&2 printf $@; }
  alias eprintf=printf-stderr
  #
  printf-debug()    { _debug && printf-stderr $@; }
  printf-verbose()  { _verbose && printf-stderr $@; }
  printf-quiet()    { _quiet || printf-stderr $@; }
  alias dprintf=printf-debug vprintf=printf-verbose qprintf=printf-quiet

  #
  # Does $1 match regex $2? Quoting here works for both Zsh and Bash.
  #
  matches() {
    [[ -z "$2" ]] && echo-stderr "usage: matches text pattern" && return 1
    [[ "$1" =~ $2 ]]
  }

  #
  ### 'eval[/echo]' helpers
  #
  # Conditionally echo the expression to stderr before executing it, using
  # similar logic as echo-* and printf-*.
  eval-echo() { 
    local prefix='>$ '
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

  #
  ### string helpers
  #
  # Modeled after jakarta-commons-lang's human-readable function names.
  # See: https://commons.apache.org/proper/commons-lang/apidocs/org/apache/commons/lang3/StringUtils.html
  #
  substring() {
    [[ -z "$2" ]] && >&2 echo "usage: substring text start_inclusive [end_exclusive]" && return 1
    if [[ -z "$3" ]]; then
      echo "${1:$2}"
    else
      echo "${1:$2:$(($3 - 1))}"
    fi
  }
  #
  substring-before-first() {
    echo "${1%%$2*}"
  }
  substring-before-last() {
    [[ -z "$2" ]] && >&2 echo "usage: substring-before-last text delim" && return 1
    echo "${1%$2*}"
  }
  #
  substring-after-first() {
    [[ -z "$2" ]] && >&2 echo "usage: substring-after-first text delim" && return 1
    echo "${1#*$2}"
  }
  substring-after-last() {
    [[ -z "$2" ]] && >&2 echo "usage: substring-after-last text delim" && return 1
    echo "${1##*$2}"
  }

  # True if $1 is any kind of executable command: alias, keyword, function, builtin, file
  is-command() {
    [[ -z "$1" ]] && echo-stderr "usage: is-command name" && return 1
    whence $1 >&/dev/null
  }

  # Source given file(s). If a file does not exist, echo a non-quiet warning but ignore the error.
  safe-source() {
    [[ -z "$1" ]] && echo-stderr "usage: safe-source file [...]" && return 1
    while [[ -n "$1" ]]; do
      local script_path="$1"; shift
      if [[ ! -e "$script_path" ]]; then
        _quiet || echo-stderr "safe-source: $script_path: No such file"
      else
        eval-verbose source "$script_path"
      fi
    done
  }

  #
  # Add given path element to the end of the PATH variable, or move it there if already present.
  # usage: path-append [--prepend] elem
  path-append() {
    local opt_prepend=; [[ "$1" =~ ^(-p|--prepend)$ ]] && opt_prepend=1 && shift
    [[ -z "$1" ]] && echo-stderr "usage: path-append [--prepend] elem" && return 1
    
    local elem="$1" && shift
    local elements="$PATH"
    if [[ -z "$elements" ]]; then
      export PATH="$elem"
      return 0
    elif [[ "$elements" = "$elem" ]]; then
      return 0
    fi
    elems_minus_elem="$(sed -e 's!:'"$elem"':!:!g' <<< ":$elements:")"
    if ((opt_prepend)); then
      export PATH="$elem${elems_minus_elem:0:((${#elems_minus_elem}-1))}"
    else
      export PATH="${elems_minus_elem:1}$elem"
    fi
  }
  path-prepend() { path-append --prepend "$@"; }

  #
  ### shell-agnostic globbing functions
  #
  glob-path-count() {
    [[ -z "$1" ]] && echo-stderr "usage: glob-path-count patt [...]" && return 1
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
    [[ -z "$1" ]] && echo-stderr "usage: glob-path-exists patt" && return 1
    local path_count=$(glob-path-count $@)
    ((path_count > 0))
  }
  #
  glob-path-first() {
    [[ -z "$1" ]] && echo-stderr "usage: glob-path-first patt [...]" && return 1
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

  # Source any files starting with the given prefix, excluding backup files.
  source-extra-dot-files() {
    [[ -z "$1" ]] && echo-stderr "usage: source-extra-dot-files PREFIX" && return 1
    if glob-path-exists "$HOME/$1.*"; then
      for f in $HOME/$1.*; do
        _verbose && echo-stderr "source-extra-dot-files: reading $f"
        [[ "$f" =~ \.(bck|bak|BAK)$ ]] || source "$f"
      done
    fi
  }

  .reload-shell() {
    dot-clear-mtimes
    eval-quiet exec $SHELL -l
  }
  alias .rs='eval-verbose .reload-shell'


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname
}
sh-bootstrap-wrapper $@
unset -f sh-bootstrap-wrapper
