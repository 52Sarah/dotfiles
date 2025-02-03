#!/usr/bin/env bash

# Shell-agnostic bootstrap functions and aliases for interactive shells.

# if [[ -z "$_DOT_SHBOOTSTRAPRC_MTIME" ]] || (( $(stat -L -f '%m' ~/.sh_bootstrap) > _DOT_SHBOOTSTRAPRC_MTIME )); then

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
  ### Echo (and bubble) return status ($?) as-is, or use $1 for 0, $2 for non-0.
  echo-status() {
    local st=$?
    printf-debug "st=%d\n" $st
    if ((st == 0)); then
      echo "${1:-0}"
    else
      echo "${2:-$st}"
    fi
    return $st
  }

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
  echo-variables() {
    [[ -z "$1" ]] && echo-stderr 'usage: echo-var varname [...]'
    local var value
    while [[ -n "$1" ]]; do
      var="$1"; shift 1
      if [[ "$SHELL" =~ /zsh$ ]]; then
        local value="${(P)var}"
      else
        local value="${!var}"
      fi
      echo "$var: $value"
    done
  }
  alias echo-vars=echo-variables

  #
  ### 'echo' / 'eval' helpers
  #
  # Conditionally echo the expression to stderr before executing it, using
  # similar logic as echo-* and printf-*.
  : ${_EVAL_ECHO_PREFIX:=\>$}
  eval-echo() { 
    local _EVAL_ECHO_PREFIX=$_EVAL_ECHO_PREFIX
    matches "$1" '^-p|--prefix$' ]] && _EVAL_ECHO_PREFIX="$2" && shift 2
    echo-stderr "$_EVAL_ECHO_PREFIX $@"; 
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
    if [[ "$SHELL" =~ /zsh$ ]]; then
      local elems="${(P)var}"
    else
      local elems="${!var}"
    fi
    split-lines ':' <<< "${elems}"
  }
  alias path-echo=path-list
  #
  # Add given path element to the end of the variable, or move it there if already present.
  # usage: path-append [--prepend] [var] path
  path-append() {
    local opt_prepend=; [[ "$1" =~ -p ]] && opt_prepend='--prepend' && shift
    local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
    [[ -z "$1" ]] && echo-stderr "usage: path-append [var] path" && return 1
    
    local elem="$1" && shift
    if [[ "$SHELL" =~ /zsh$ ]]; then
      local elements="${(P)var}"
    else
      local elements="${!var}"
    fi
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
  alias path-prepend='path-append --prepend'

  #
  ## string/list handling helpers
  #
  # Does $1 match regex $2? Quoting works for Zsh and Bash.
  matches() {
    [[ -z "$2" ]] && eecho "usage: matches text pattern" && return 1
    local text="$1" && shift
    local pattern="$*" && shift
    [[ "$text" =~ $pattern ]]
  }
  #
  ends_with() {
    [[ -z "$2" ]] && echo-stderr "usage: ends_with [--verbose] text suffix_to_test" && return 1
    [[ "$1" =~ .*$2$ ]]
  }
  starts_with() {
    [[ -z "$2" ]] && echo-stderr "usage: starts_with [--verbose] text prefix_to_test" && return 1
    [[ "$1" =~ ^$2.*$ ]]
  }
  #
  # The following functions operate on stdin OR $@; [[ -t 0 ]] is true if stdin is a terminal
  # from: https://stackoverflow.com/a/30520299
  #
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
  #
  substring_before_first() {
    local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
    [[ ! -t 0 ]] && read line && printf "%s\n" "${line%%${delim}*}" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: substring_before_first [--delim DELIM] text [DELIM], or ... | substring_before_first [--delim DELIM]" && return 1
    [[ -n "$2" ]] && delim="$2"
    substring_before_first --delim "$delim" <<< "$1"
  }
  substring_before_last() {
    local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
    [[ ! -t 0 ]] && read line && printf "%s\n" "${line%${delim}*}" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: substring_before_last [--delim DELIM] text [DELIM], or ... | substring_before_last [--delim DELIM]" && return 1
    [[ -n "$2" ]] && delim="$2"
    substring_before_last --delim "$delim" <<< "$1"
  }
  substring_after_first() {
    local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
    [[ ! -t 0 ]] && read line && printf "%s\n" "${line#*${delim}}" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: substring_after_first [--delim DELIM] text [DELIM], or ... | substring_after_first [--delim DELIM]" && return 1
    [[ -n "$2" ]] && delim="$2"
    substring_after_first --delim "$delim" <<< "$1"
  }
  substring_after_last() {
    local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
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


  export _DOT_SHBOOTSTRAPRC_MTIME="$(stat -L -f '%m' ~/.sh_bootstraprc)"
# fi
