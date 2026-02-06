#!/usr/bin/env zsh

# Shell-agnostic bootstrap functions and aliases for interactive shells.
# Functions defined here should not depend on any other startup files.
# No references to tick logging in this file.

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

shrc-wrapper() {
  local dot_fname='.sh_rc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-shrc() {
    unset "_DOT_MTIMES[.sh_rc]"
    eval-quiet source ~/.sh_rc
  }

  is-command .tick || safe-source ~/.tick.sh
  .tick-shrc() { .tick -s ".sh_rc" $@; }
  .tick-shrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.sh_rc)" #, \$PATH=[$PATH], \$PS1=[$PS1])"


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

  # Replace newlines, carriage-returns and tabs with \n, \r and \t.
  echo-unescape() {
    if [[ ! -t 0 ]]; then
      sed -E -n 'l;' \
      | join-lines '\\n' \
      | sed -E 's/\$(\\n)/\1/g; s/\$$//g;'
      return 0;
    fi
    [[ -z "$1" ]] && echo-stderr 'usage: echo-unescape text [...] or echo-unescape <<< text' && return 1
    echo-unescape <<< $@
  }
  #
  echo-variables() {
    [[ -z "$1" ]] && echo-stderr 'usage: echo-variables name [...]'
    local var value
    while [[ -n "$1" ]]; do
      var="$1"; shift 1
      is-zsh && value="${(P)var}" || value="${!var}"
      echo "$var: [$value]"
    done
  }
  alias echo-variable=echo-variables echo-vars=echo-variables echo-var=echo-variables
  #
  # List all variables matching $1 (globbing *, etc.) and their values.
  echo-glob() {
    local patt="$1"; [[ -z "$patt" ]] && echo-stderr "usage: echo-glob patt" && return 1
    [[ ! "$patt" =~ [*?]$ ]] && patt="${patt}*"
    if is-zsh; then
      typeset -m "$patt"
    else
      echo ${!patt}
    fi | sort
  }
  gecho() { echo-glob "$@"; }
  alias ge='gecho'


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
    [[ -z "$1" ]] && echo-stderr "usage: join-array delim [text ...]" && return 1
    local delim="$1" && shift
    local is_first=1
    for i in $@; do
      if ((is_first)); then
        printf "%s" "$i"
        unset is_first
      else
         printf "%s%s" "$delim" "$i"
       fi
    done
    printf '\n'
  }
  #
  uniq-array() {
    local is_first=1 buff=
    for i in $@; do
      if ((is_first)); then
        buff="$i"
        unset is_first
      else
          buff="$(printf '%s\n%s' "$buff" "$i")"
      fi
    done
    echo "$buff" | sort -s | uniq
  }
  #
  # Concatenate trimmed lines from stdin onto a single line, delimited by $1
  join-lines() {
      local delim="$1"
      local is_first=1
      sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do 
        if ((!is_first)) then
          printf "%s" "$delim"
        else
          unset is_first
        fi
        printf "%s" "$ln"
      done
      printf '\n'
  }
  # Split line(s) from stdin into separate lines, using $1 [,] as delimiter
  split-lines() {
      local delim="${1:-,}"
      sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
  }

  #
  ### path helpers
  #
  # List path variable's elements, 1 per line. Defaults to PATH.
  path-list() {
    local var=${1:-PATH} elems
    is-zsh && elems="${(P)var}" || elems="${!var}"
    split-lines ':' <<< "${elems}"
  }
  alias path-echo=path-list

  #
  ## string/list handling helpers
  #
  ends-with() {
    [[ -z "$2" ]] && echo-stderr "usage: ends-with text suffix_to_test" && return 1
    [[ "$1" =~ .*$2$ ]]
  }
  starts_with() {
    [[ -z "$2" ]] && echo-stderr "usage: starts_with text prefix_to_test" && return 1
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
  # Expand '~' to value of $HOME, or compress value of $HOME to ~
  tilde-compress() {
    [[ ! -t 0 ]] && _tilde-home-compress-expand 'tilde-compress' '${path//$HOME/\~}' $@ && return 0
    [[ -z "$1" ]] && echo-stderr "usage: tilde-compress path [...]" && return 1
    tilde-compress <<< $@
  }
  tilde-expand() {
    [[ ! -t 0 ]] && _tilde-home-compress-expand 'tilde-expand' '${path//\~/$HOME}' && return 0
    [[ -z "$1" ]] && echo-stderr "usage: tilde-expand path [...]" && return 1
    tilde-expand <<< $@
  }
  #
  # Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
  home-compress() {
    [[ ! -t 0 ]] && _tilde-home-compress-expand 'home-compress' '${path//$HOME/\$HOME}' $@ && return 0
    [[ -z "$1" ]] && echo-stderr "usage: home-compress path [...]" && return 1
    home-compress <<< $@
  }
  home-expand() {
    [[ ! -t 0 ]] && _tilde-home-compress-expand 'home-expand' '${path//\$HOME/$HOME}' $@ && return 0
    [[ -z "$1" ]] && echo-stderr "usage: home-expand path [...]" && return 1
    home-expand <<< $@
  }
  #
  # Convert stdin using the path_expr
  _tilde-home-compress-expand() {
    [[ -z "$2" ]] && echo-stderr "usage: _tilde-home-compress-expand ${1:-fn_name} path_expr" && return 1
    local fn_name="$1" path_expr="$2"
    local delim= path=
    while read path; do
      printf '%s%s' "$delim" "$(eval "echo $path_expr")"
      delim=' '
    done
    printf '\n'
  }


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-shrc "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
shrc-wrapper $@
unset -f shrc-wrapper .tick-shrc
