#!/usr/bin/env zsh

# Shell-agnostic mimimal bootstrap functions for all login scripts.
# Functions defined here do not depend on any other startup files.
#
# Tick logging is loaded (lazily) in this file, but no logging calls are made from here.
#
# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -f ~/.tick ]] && source ~/.tick

is-zsh() {
  [[ "$0" =~ zsh ]]
}
is-bash() {
  [[ "$0" =~ bash ]]
}

#
### Minimize redundant startup file execution, based on whether script modified since last run.
#
file-mtime() {
  [[ -z "$1" || -n "$2" ]] && echo >&2 'usage: file-mtime path' && return 1
  stat -L -f '%m' "$1" # epoch seconds
}
.dot-ok-to-skip() {
  [[ -z "$1" ]] && echo >&2 'usage: .dot-ok-to-skip dot_file' && return 1
  local dot_file="$1"
  [[ ! -e "$dot_file" ]] && echo >&2 ".dot-ok-to-skip: $dot_file: No such file" && return 1

  (( _DOT_MTIMES_IGNORE )) && return 1

  # TODO: figure out bash map handling here and in .dot-store-mtime
  is-zsh || return 1

  local cached_mtime="$_DOT_MTIMES[$dot_file]"
  [[ -z "$cached_mtime" ]] && return 1
  (( $(file-mtime "$dot_file") == $cached_mtime ))
}
#
.dot-store-mtime() {
  [[ -z "$1" ]] && echo >&2 'usage: .dot-store-mtime dot_file' && return 1
  local dot_file="$1"
  [[ ! -e "$dot_file" ]] && echo >&2 ".dot-store-mtime: $dot_file: No such file" && return 1

  # TODO: figure out bash map handling here and in .dot-store-mtime
  is-zsh || return 1

  _DOT_MTIMES+=($dot_file $(file-mtime "$dot_file"))
}
#
.dot-reset-mtimes() {
  typeset -g -A _DOT_MTIMES=()
}
[[ -z "$_DOT_MTIMES" ]] && .dot-reset-mtimes


.sh-bootstrap-wrapper() {
  local dot_fname='.sh_bootstrap'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-bootstrap() {
    unset "_DOT_MTIMES[.sh_bootstrap]"
    eval-quiet source ~/.sh_bootstrap
  }


  #
  ### Environment variables used to enable verbose or debug "log" output, or quiet "normal" info output.
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

  # Does $1 match regex $2? Quoting here works for both Zsh and Bash.
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
  # Bash-friendly substitute for typeset -m name*; print variables (with globbing) and values.
  echo-variables() {
    [[ -z "$1" ]] && echo-stderr 'usage: echo-variables name[*] [...]'
    local name vars var
    while [[ -n "$1" ]]; do
      name="$1"; shift 1
      [[ "$name" =~ [^*?]$ ]] && name="${name}*"
      if is-zsh; then
        typeset -m $name
      else
        eval $(echo vars="\${!$name}")
        for var in $vars; do
          value="${!var}"
          echo "$var=${!var}"
        done
      fi
    done
  }
  alias ev=echo-variables echo-variable=echo-variables echo-vars=echo-variables echo-var=echo-variables
  alias eg=echo-variables echo-glob=echo-variables

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

#
  ### 'cd' helpers
  #
  # Change directory to the given link's target, either the file's parent or the directory itself.
  cd-ln() {
    local link="$1"
    [[ -z "$link" ]] && echo-error "usage: cd-ln link_to_dir | link_to_file" && return 1
    [[ ! -e "$link" ]] && echo-error "cd-ln: $link: no such symlink" && return 1
    [[ ! -L "$link" ]] && echo-error "cd-ln: $link: not a symlink" && return 1
    local target="$(readlink "$link")"
    if [[ -d "$target" ]]; then
        eval-quiet cd "$target"
    else
        eval-quiet cd "$(dirname "$target")"
    fi
  }

  #
  ### 'chmod' helpers
  #
  # Make specified, or all in PWD, shell scripts executable.
  chx() {
    local files=($@)
    [[ -z "$1" ]] && files=(*.sh) && _VERBOSE=1
    eval-quiet chmod ${_VERBOSE:+-vv} +x "${files[@]}"
  }

  #
  ### 'less' helpers:
  # 
  alias l='less'
  #
  # Lines will NOT wrap, but CTRL-C, arrow keys can scroll left and right. Press 'F' to resume "tailing".
  alias less-trunc='eval-quiet less --chop-long-lines +F'

  #
  ### 'ls' helpers
  #
  # -A  show .* files except for '.'' and '..'
  # -d  list directories as plain files, not recursed
  #
  # -H  follow only symlink arguments
  # -L  follow all symlinks
  # -P  follow no symlinks
  #
  # -1  ("one") 1-column output
  # -l  ("el") use long form, show owner and group
  # -g  use long form, suppress owner
  # -o  use long form, suppress group
  # -h  use human-readable file sizes
  # -F  add file suffix [/, @, *, ...]
  #
  # -tr sort by time modified, old to new
  # -Sr sort by size, ascending
  #
  alias ls1='ls -1 -F'
  alias lsa='ls -A -F'
  #
  alias ll='ls -og -hF'
  alias llt='ls -og -hF -t'
  alias lltr='ls -og -hF -tr'
  alias lls='ls -og -hF -S'
  alias llsr='ls -og -hF -Sr'
  #
  alias lA='ls -al -hF'
  alias la='ls -Al -hF'
  alias lat='ls -Al -hF -t'
  alias latr='ls -Al -hF -tr'
  alias las='ls -Al -hF -S'
  alias lasr='ls -Al -hF -Sr'
  #
  # Display permissions in octal, from: http://askubuntu.com/a/152005
  # I've tried to figure out how this works but have no clue.
  lso() {
    ls -ohF $@ \
    | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' \
    | sed -E -e "s:\\$HOME:\\~:g"
  }

  #
  ### 'nc' helpers:
  # 
  ncz() {
    [[ -z "$1" ]] && echo-error "Usage: ncz [host] port" && return 1
    local host= port=
    if [[ -n "$2" ]]; then
      host=$1
      port=$2
      shift 2
    else
      host=localhost
      port=$1
      shift 1
    fi
    
    eval-verbose nc -z $host $port $@
    
    local ret=$?
    if ! _quiet; then
      ((!ret)) && echo "Active" || echo "Inactive"
    fi
    return $ret
  }

  #
  ### 'ps/pgrep' helpers
  #
  # Tidy way to pgrep but (1) include header, (2) exclude the egrep itself.
  # ps options:
  #   -A  display all processes (same as -e)
  #   -m  sort by mem usage (instead of pid)
  #   -r  sort by cpu usage (instead of pid)
  #   -o  specify output fields:
  #         user -    username (18c wide so we cut it down to 12)
  #         pid
  #         ppid
  #         start
  #         time
  #         %cpu
  #         %mem
  #         command - very long, so we limit line length to window size
  ps-grep() {
    local USAGE='Usage: ps-grep [--long] [patt...]'
    local opt_long=; matches "$1" '-l|--long' && opt_long=1 && shift 1

    local ps_cmd="ps -e -o user,pid,ppid,start,time"
    ((opt_long)) && ps_cmd="${ps_cmd},%cpu,%mem,command" || ps_cmd="${ps_cmd},comm"
    if [[ -n "$1" ]]; then
      ps_cmd="$ps_cmd | egrep -e 'USER\s+PID\s+PPID'"
      while [[ -n "$1" ]]; do
        ps_cmd="$ps_cmd -e '$1'" && shift 1
      done
    fi
    # ! ((opt_long)) && ps_cmd="$ps_cmd | awk '{printf(\"%-10s %5s %5s %5s %s\n\", \$1,\$2,\$3,\$4,\$8)}'"
    # ps_cmd="$ps_cmd | egrep -v -e '$$ .+ egrep -e USER'"
    ps_cmd="$ps_cmd | egrep -v -e ' egrep '"
    ps_cmd="$ps_cmd | head -n 15"
    eval-quiet "$ps_cmd"
  }
  ps-java() {
    eval-verbose "ps-grep -l java | sed -E -n '/^USER/p; /^[[:alnum:]]+ +([[:digit:]]+ +){2}/ s/^([[:alnum:]]+ +([[:digit:]]+ +){2}([^[:space:]]+ +){4}([^[:space:]]+) +).*( ([a-z]+\.)+[A-Z][^.]+.*)$/\1 - \5/p;'" \
      | sed -E 's:\/Library\/Java\/JavaVirtualMachines\/::'
    # eval-quiet "ps-grep -l java | sed -E -n '/^USER/p; /^[[:alnum:]]+ +([[:digit:]]+ +){2}/ s/^([[:alnum:]]+ +(?:[[:digit:]]+ +){2} +(?:[^[:space:]]+ +){4} +([^[:space:]]+) +).+$/\1/; p;'" # + \d+ +\d+/p;' #' +\w+ +\w+ +\w+ +'
    # eval-quiet "ps-grep -l java | sed -E -n 's/^(USER.+)|([[:alnum:]]+ +([[:digit:]]+ +){2} +([[:digit:]]+ +){5} +.+)$/\2/; p;'" # + \d+ +\d+/p;' #' +\w+ +\w+ +\w+ +'
  }
  ps-java-pid-class() {
    [[ -z "$1" ]] && echo-error "Usage: ps-java-pid-class PID" && return 1
     eval-quiet "ps -p $1 | sed -E -n -e 's/.+ ([a-z]+\.)+([A-Z][A-Za-z]+).*/\2/p'"
  }
  #
  # Show active port info: command, pid, ports
  # lsof:
  # -b    avoid blocking kernel functions
  # +cn   COMMAND column width
  # -i4   IPv4 only
  # -n    use host numeric addresses, not names
  # -P    use port numbers, not names
  # -w    suppress warning messages
  ps-ports-1() {
    eval-quiet lsof -b +c 16 -i TCP -n -P -w $@
  }
  ps-ports-2() {
    ps-ports-1 $@ | egrep --color=never '^COMMAND [A-Z /]+$|(java|idea|pycharm|datagrip) .+ \((LISTEN|ESTABLISHED)\)$'
  }
  ps-ports-3() {
    ps-ports-2 $@ | awk '{printf("%-16s %5s  %s\n", $1, $2, $9);}'
    # | awk '{split($9,hostport,":"); printf("%s %s\n", $2, hostport[2]);}'
  }
  ps-ports() {
    ps-ports-3 $@ | sort -k2 -k3
  }
  ps-ports-java-class() {
    printf "%-16s  %5d  %s\n" "COMMAND" "PID" "PORTS"
    ps-ports $@ \
    | while read cmd pid ports; do
      class="$(ps-java-pid-class $pid)"
      printf "%-16s %5d %-16s %s\n" "$cmd" "$pid" "$class" "$ports"
    done
  }

  #
  ### terminal helpers
  #
  # toggle wrap/truncate
  alias term-wrap='eval-quiet tput smam'
  alias term-trunc='eval-quiet tput rmam'
  #
  # colored text, from https://www.shellhacks.com/bash-colors/
  echo-color() {
    local USAGE="Usage: echo-color [-n] black|red|green|brown|blue|purple|cyan|light-gray TEXT [...]"
    local opt_no_crlf=; [[ "$1" == "-n" ]] && opt_no_crlf='-n' && shift 1
    [[ -z "$2" ]] && echo-error "$USAGE" && return 1

    local color="$(lower $1)"; shift 1
    case "$color" in
      black)  code=30;;
      red)    code=31;;
      green)  code=32;;
      brown)  code=33;;
      blue)   code=34;;
      purple) code=35;;
      cyan)   code=36;;
      gray)   code=37;;
      *) echo-error "echo-color: invalid color: $color"; return 1;
    esac
    echo -e $opt_no_crlf "\e[${code}m$@\e[0m"
  }

  #
  ### 'touch' helpers
  #
  # Update mtime of folders with latest mtime of its contents
  touchd() {
    [[ -z "$1" ]] && echo-error "usage: touchd dir [...]" && return 1
    local count=0 arg
    for arg in $@; do
        local dir="$arg"
        local dir_tilde="${dir/$HOME/~}"
        [[ ! -e "$dir" ]] && echo-error "touchd: $dir_tilde: no such directory" && return 1
        [[ ! -d "$dir" ]] && echo-verbose "touchd: $dir_tilde: not a directory" && continue

        local newest="$(ls -A1t "$dir/" | head -n 1)"
        [[ -z "$newest" ]] && echo-verbose "touchd: empty directory: $dir_tilde" && continue

        local dir_time="$(stat -f %Sm "$dir")"; [[ -z "$dir_time" ]] && return 1
        local newest_time="$(stat -f %Sm "$dir/$newest")"; [[ -z "$newest_time" ]] && return 1
        [[ "$dir_time" == "$newest_time" ]] && echo-verbose "touchd: $dir_tilde: mtime already matches $newest: $newest_time" && continue
        echo "touchd: updating mtime of '$dir_tilde' ($dir_time) to match '$newest': $newest_time"

        # touch -h will update link's target instead of link
        eval-quiet touch -r "$dir/$newest" "$dir"
        [[ -L "$dir" ]] && eval-quiet touch -h -r "$dir/$newest" "$dir"
        
        ((count++))
    done
    ((!count)) && return 1
    echo-verbose "touchd: updated $count directories"
  }
  #
  touchd-R() {
    local dirs=$@
    [[ -z "$dirs" ]] && dirs="$PWD"
    for dir in $dirs; do
        find "$dir" -depth ! -type f -print |\
        while read -r subdir; do
            eval-quiet touchd "$subdir"
        done
        eval-quiet touchd "$dir"
    done
  }

  #
  ### symlink/ln helpers
  #
  ln-valid() {
    local ret=0 files
    if is-zsh; then
      files=(${@:-*})
    else
      files=${@:-*}
    fi
    _debug && echo-variables files
    for link in $files; do
      _debug && echo-variables link
      local target= ln_status="OK"
      if [[ ! -L "$link" ]]; then
        ! _verbose && continue
        ln_status="NON-LINK"
      else
        target="$(readlink "$link")"
        [[ ! -e "$target" ]] && ln_status="INVALID"
      fi
      local line="$(printf '%-9s %s -> %s\n' $ln_status $link $target)"
      if [[ "$ln_status" == "OK" ]]; then
        echo-quiet "$line"
      elif [[ "$ln_status" == "NON-LINK" ]]; then
        echo-color blue "$line"
      else
        ret=1
        echo-color red "$line"
      fi
    done
    return $ret
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
    .dot-reset-mtimes
    eval-quiet exec $SHELL -l
  }
  alias .rs='eval-verbose .reload-shell'


  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname
}
.sh-bootstrap-wrapper && unset -f .sh-bootstrap-wrapper
