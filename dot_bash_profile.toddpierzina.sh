#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# ch-bash-profile's .bash_profile runs this user-specific script if it exists


# Simple login file debugging. Enabled if ~/.tick.LOGINSCRIPT exists.
if [[ -z "$TICK_BASH_PROFILE_USER" && -e "$HOME/.tick.bash_profile.$USER" ]]; then
  type -t .tick >&/dev/null || . ~/.bashrc_tick
  
  TICK_BASH_PROFILE_USER='~/.bash_profile.$USER'
  .tick_bpu() { .tick -s "$TICK_BASH_PROFILE_USER" "$@"; }
  .tickeval_bpu() { .tickeval -s "$TICK_BASH_PROFILE_USER" "$@"; }
else
  unset TICK_BASH_PROFILE_USER
  .tick_bpu() { :; }
  .tickeval_bpu() { :; }
fi
# .tick_bpu 'defined .tick_bpu, .tickeval_bpu'

.bash_profile_USER() {
  # >&2 printf "STARTING .bash_profile_USER\n"

  # reduce the number of "start" messages
  if [[ "$PID_PPID_BPU" != "$$,$PPID" ]]; then
    export PID_PPID_BPU="$$,$PPID"
    .tickeval_bpu 'printf -- "==== START PID,PPID=%s \$SHLVL=%s \$_=[%s] \$-=[%s]\n" "$PID_PPID_BPU" "$SHLVL" "$_" "$-"'
  fi

  # Don't show the 'zsh is the default shell' message.
  export BASH_SILENCE_DEPRECATION_WARNING=1


  # Non-interactive shells read the $BASH_ENV file, if any.
  .tick_bpu "sourcing .bashrc.$USER"
  export BASH_ENV="$HOME/.bashrc.$USER"
  . "$BASH_ENV"
  .tick_bpu "sourced .bashrc.$USER"
  
  .tick_bpu "sourcing .bashrc.settings.$USER"
  [[ -e "$HOME/.bash_settings.$USER" ]] && . "$HOME/.bash_settings.$USER"
  .tick_bpu "sourced .bashrc.settings.$USER"
  
  
  ### 'ls' helpers:
  #
  # -A  show .* files except for '.'' and '..'
  # -d  list directories as plain files, not recursed
  #
  # -H  follow only symlink arguments
  # -L  follow all symlinks
  # -P  follow no symlinks
  #
  # -l  use long form, show owner and group
  # -g  use long form, suppress owner
  # -o  use long form, suppress group
  # -h  use human-readable file sizes
  # -F  add file suffix [/, @, *, ...]
  #
  # -tr sort by time modified, old to new
  # -Sr sort by size, ascending
  #
  ll()   { ls -oghF "$@" | tilde-compress; }
  llt() { ll -t "$@"; }
  lltr() { ll -tr "$@"; }
  lls() { ll -S "$@"; }
  llsr() { ll -Sr "$@"; }
  #
  la()   { ll -A "$@"; }
  lat() { la -t "$@"; }
  latr() { la -tr "$@"; }
  las() { la -S "$@"; }
  lasr() { la -Sr "$@"; }
  #
  lld()  { ll -d "$@"; }
  lad()  { la -d "$@"; }

  
  # Think "ll and la but narrower": cut out permissions, link count and owner.
  #   $ ls -ohF
  #   total 520
  #   -rw-r--r--  1 toddpierzina   1.2K Mar 10 11:33 README.md
  # $1: permissions, $2: inode count, $3: owner, $4: size, $5: date/time, $6: filename
  lln() {
    ls -oF "$@" |\
    sed -E \
      -e '/^total .+$/d' \
      -e 's/^([^ ]{9,}) +([[:digit:]]+) +([^ ]+) +([^ ]+) ([^ ]+ +[^ ]+ +[^ ]+) +(.+)$/\4'$'\t''\5'$'\t''\6/' \
      -e "s:\\$HOME:\\~:g" |\
    awk -F$'\t' \
      '{printf "%12'$'\'''d  %s  %s\n", $1, $2, $3}'
  }
  lan() { 
    lln -A "$@"
  }

  # Display permissions in octal, from: http://askubuntu.com/a/152005
  # I've tried to figure out how this works but have no fucking clue.
  lso() {
    ls -ohF "$@" |\
    awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' |\
    sed -E -e "s:\\$HOME:\\~:g"
  }

  ### 'find' helperrs
  alias nfind='find -L . -name '
  alias pfind='find -L . -path '
  alias rfind='find -L -E . -regex '

  ### 'less' helperrs
  alias l='less'

  ### 'mv' helpers
  alias mvv='mv -v'

  ### 'rm' helpers
  alias rmv='rm -v'
  #
  # Delete the target of a symlink, then the symlink.
  rmln() {
    local cmd="rm"
    while [[ "$1" =~ ^- ]]; do
      cmd="$cmd $1" && shift
    done
  
    local link="$1" && shift
    [[ -z "$link" ]] && eecho "usage: rmln [rm opts] symlink" && return 1
    [[ ! -L "$link" ]] && eecho "rmln: $link: no such symlink" && return 1
  
    local dest="$(readlink "$link")"
    [[ ! -e "$dest" ]] && eecho "rmln: $link -> $dest: no such file or directory" && return 1
    qeval "$cmd '$dest'" || return 1
  }

  ### 'tail' helpers
  alias t='tail'
  alias tf='tail -f'
  # Lines will not wrap on screen, BUT by interrupting (CTRL-C), arrow keys can scroll
  # left and write. Press 'F' to resume "tailing".
  alias tfl='less --chop-long-lines +F'

  #
  ### terminal/iterm wrap/unwrap
  #
  alias trunc='tput rmam'
  alias wrap='tput smam'

  # history-grep
  hg() {
    local HISTTIMEFORMAT="$HISTTIMEFORMAT"
    [[ "$1" =~ ^-d|--date$ ]] && shift || HISTTIMEFORMAT=
    if [[ -z "$1" ]]; then
      history
    else
      history | grep -E $*
    fi
  }

  #
  ### 'cd' helpers
  #
  # Oops, return to where I was one time, if possible.
  uncd() {
    [[ -z "$OLDPWD" ]] && >&2 echo 'uncd: cannot determine prior directory' && return 1
    [[ ! -d "$OLDPWD" ]] && >&2 echo 'uncd: $OLDPWD: prior directory no longer exists' && return 1
    cd "$OLDPWD"
  }
  # Change directory to the given link's target, either the file's parent or the directory itself.
  cdln() {
    local link="$1" target
    [[ -z "$link" ]] && eecho "usage: cdln link_to_dir | link_to_file" && return 1
    [[ ! -e "$link" ]] && eecho "cdln: $link: no such symlink" && return 1
    [[ ! -L "$link" ]] && eecho "cdln: $link: not a symlink" && return 1
    local target="$(readlink "$link")"
    if [[ -d "$target" ]]; then
        cd "$target"
    else
        cd "$(dirname "$target")"
    fi
  }


  # Make specified, or all in PWD, shell scripts executable.
  chx() {
    local opt_verbose=$((SH_VERBOSE))
    [[ "$1" =~ ^(-v|--verbose)$ ]] && shift && opt_verbose=1
    
    local files=("$@")
    [[ ! "$1" ]] && files=(*.sh) && opt_verbose=1

    ((opt_verbose)) && opt_verbose="-vv" || opt_verbose=
    chmod $opt_verbose +x "${files[@]}"
  }

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
    line_width=$COLUMNS; ((line_width < 100)) && line_width=100
    ps_cmd="ps -e -o user,pid,ppid,start,time,%cpu,%mem,command"
    if [[ -n "$1" ]]; then
      ps_cmd="$ps_cmd | egrep -e 'USER\s+PID\s+PPID'"
      while [[ -n "$1" ]]; do
        ps_cmd="$ps_cmd -e '$1'" && shift
      done
    fi
    ps_cmd="$ps_cmd | cut -c 1-12,19-$line_width | egrep -v -e '$$ .+ egrep -e USER'"
    eeval $ps_cmd
  }
  alias psg='ps-grep'

  # Print today's date in any format, defaulting to YYYYMMDD.
  today-formatted() {
    local opt_format="${1:-%Y%m%d}" && shift
    date +"$opt_format"
  }

  # Updated mtime of folders with latest mtime of its contents.
  touchd() {
    [[ -z "$1" ]] && eecho "usage: touchd dir [...]" && return 1
    local SH_VERBOSE="$((SH_VERBOSE))"
    local count=0 arg
    for arg in "$@"; do
        [[ "$arg" =~ ^(-v|--verbose)$ ]] && SH_VERBOSE=1 && continue
        
        local dir="$arg"
        local dir_tilde="${dir/$HOME/~}"
        [[ ! -e "$dir" ]] && eecho "touchd: $dir_tilde: no such directory" && return 1
        [[ ! -d "$dir" ]] && vecho "touchd: $dir_tilde: not a directory" && continue

        local newest="$(ls -A1t "$dir/" | head -n 1)"
        [[ -z "$newest" ]] && vecho "touchd: empty directory: $dir_tilde" && continue

        local dir_time="$(stat -f %Sm "$dir")"; [[ -z "$dir_time" ]] && return 1
        local newest_time="$(stat -f %Sm "$dir/$newest")"; [[ -z "$newest_time" ]] && return 1
        [[ "$dir_time" == "$newest_time" ]] && vecho "touchd: $dir_tilde: mtime already matches $newest: $newest_time" && continue
        echo "touchd: updating mtime of '$dir_tilde' ($dir_time) to match '$newest': $newest_time"

        # touch -h will update link's target instead of link
        touch -r "$dir/$newest" "$dir"
        [[ -L "$dir" ]] && touch -h -r "$dir/$newest" "$dir"
        
        ((count++))
    done
    ((!count)) && return 1
    vecho "touchd: updated $count directories"
  }
  touchd-R() {
    local dirs=("$@")
    [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
    for dir in "${dirs[@]}"; do
        [[ "$dir" =~ ^(-v|--verbose)$ ]] && [[ -n "$SH_VERBOSE" ]] && continue
        find "$dir" -depth ! -type f -print |\
        while read -r subdir; do
            touchd "$subdir"
        done
        touchd "$dir"
    done
  }

  # record lengths along with count of each length
  record-lengths() {
    [[ -z "$1" ]] && >&2 echo "usage: record-lengths file [...]" && return 1
    local files=$*
    for f in $files; do
      printf "%s\n  %s\n" "$f" "$(awk '{print length($0)}' "$f" | sort -n | uniq -c)"
    done
  }
  alias recl='record-lengths'

  fwf-less() {
    local is_pipe=; [[ ! -t 0 ]] && is_pipe=1
    vecho "is_pipe=$is_pipe"
    
    local delim='|'
    if [[ "$1" =~ -d|--delim ]]; then
      delim="$2"
      shift 2
    fi
    
    local fwf=; ((! is_pipe)) && fwf="$1" && shift
    # [[ -z "$fwf" ]] && eecho "usage: fwf-less [-d delim] file [col-expr [...]" && return 1
    ((! is_pipe)) && [[ ! -f "$fwf" ]] && eecho "fwf-less: $fwf: No such file" && return 1
    local c='print ' first=1
    while true; do
      local cr=0
      [[ "$1" = "CR" ]] && cr=1 && shift 1
      [[ -z "$1" || -z "$2" ]] && break
      local pos=$1 len=$2; shift 2
      if ((first)); then
        c="print substr(\$0, $pos, $len)"
        first=0
      elif ((cr)); then
        c="$c \"\n\" substr(\$0, $pos, $len)"
      else
        c="$c \"$delim\" substr(\$0, $pos, $len)"
      fi
    done
    ((is_pipe)) && awk "{$c}" || awk "{$c}" "$fwf"
  }
  alias fwf='fwf-less'
  fwf-hcsc-med-accum() {
    local delim="\t"
    if [[ "$1" =~ -d|--delim ]]; then
      delim="$2"
      shift 2
    fi
    vecho "fwf-less -d "$delim" $*"
    fwf-less -d "$delim" $* \
      1 9  10 4  14 9  23 8  31 1  32 15  47 10  57 1  58 15  73 2  75 2 \
      CR  77 8  85 8  93 1  94 1  95 64  159 2  161 3 164 3  167  16  183 12  195 12 \
      CR  207 8  215 8  223 1  224 1  225 64  289 2  291 3  294 3  297 16  313 12  325 12 \
      CR  337 8  345 8  353 1  354 1  355 64  419 2  421 3  424 3  427 16  443 12  455 12 \
      CR  467 8  475 8  483 1  484 1  485 64  549 2  551 3  554 3  557 16  573 12  585 12 \
      CR  597 8  605 8  613 1  614 1  615 64  679 2  681 3  684 3  687 16  703 12  715 12 \
      CR  727 8  735 8  743 1  744 1  745 64  809 2  811 3  814 3  817 16  833 12  845 12 \
      CR  857 8  865 8  873 1  874 1  875 64  939 2  941 3  944 3  947 16  963 12  975 12 \
      CR  987 8  995 8  1003 1  1004 1  1005 64  1069 2  1071 3  1074 3  1077 16  1093 12  1105 12 \
      CR  1117 8  1125 8  1133 1  1134 1  1135 64  1199 2  1201 3  1204 3  1207 16  1223 12  1235 12 \
      CR  1247 8  1255 8  1263 1  1264 1  1265 64  1329 2  1331 3  1334 3  1337 16  1353 12  1365 12 \
      CR  1377 8  1385 8  1393 1  1394 1  1395 64  1459 2  1461 3  1464 3  1467 16  1483 12  1495 12 \
      CR  1507 8  1515 8  1523 1  1524 1  1525 64  1589 2  1591 3  1594 3  1597 16  1613 12  1625 12 \
      CR  1637 8  1645 8  1653 1  1654 1  1655 64  1719 2  1721 3  1724 3  1727 16  1743 12  1755 12 \
      CR  1767 8  1775 8  1783 1  1784 1  1785 64  1849 2  1851 3  1854 3  1857 16  1873 12  1885 12 \
      CR  1897 8  1905 8  1913 1  1914 1  1915 64  1979 2  1981 3  1984 3  1987 16  2003 12  2015 12 \
      CR  2027 8  2035 8  2043 1  2044 1  2045 64  2109 2  2111 3  2114 3  2117 16  2133 12  2145 12 \
      CR  2157 8  2165 8  2173 1  2174 1  2175 64  2239 2  2241 3  2244 3  2247 16  2263 12  2275 12 \
      CR  2287 8  2295 8  2303 1  2304 1  2305 64  2369 2  2371 3  2374 3  2377 16  2393 12  2405 12 \
      CR  2417 8  2425 8  2433 1  2434 1  2435 64  2499 2  2501 3  2504 3  2507 16  2523 12  2535 12 \
      CR  2547 8  2555 8  2563 1  2564 1  2565 64  2629 2  2631 3  2634 3  2637 16  2653 12  2665 12 \
      CR  2677 8  2685 8  2693 1  2694 1  2695 64  2759 2  2761 3  2764 3  2767 16  2783 12  2795 12
  }


  #
  ### PS1 COMMAND LINE PROMPT
  #
  # - if unset, leave unset (non-interactive shell)
  # - if last command was in error, display "!" prefix before "$" and before line sep
  # - `history -a` explicitly flushes the session history to the history file
  # __git_ps1 shows the current git branch, if any, and is configured below
  # - \u = user, \h = hostname, \w = working dir
  .tick_bpu 'STARTING PS1/PROMPT_COMMAND'
  export PS1="\\w \$"
  _prompt_command() {
    local prev_status=$?
    .tick_bpu "starting _prompt_command, prev_status=$prev_status, PS1='$PS1'"

    history -a
    local ps1_suffix_new="\$"; ((prev_status)) && ps1_suffix_new="!\$"
    local ps1_old="${PS1##* }"
    export PS1="$ps1_old $ps1_suffix_new "
    # export PS1='--\n$(__git_ps1 "[%s]") \w $_pprefix '
    # export GIT_BRANCH="$(git branch --show-current 2> /dev/null)"
    # __git_ps1 "$_sep\n" " \w $_pprefix\$ " "[%s]"'
    .tick_bpu "finishing _prompt_command, PS1='$PS1'"
  }
  export PROMPT_COMMAND='_prompt_command'
  _prompt_command
  .tick_bpu 'FINISHED PS1/PROMPT_COMMAND'

  #
  ###  GIT
  #
  # Enable git prompt and completion if installed.
  #
  .setup_git() {
    .tick_bpu 'STARTING .setup_git'
    ! type -t git &>/dev/null && .tick_bpu "git not installed" && return 0

    .tick_bpu 'lookig up git version'
    local git_version="$(git --version)"
    .tick_bpu "using $git_version"

    alias g='git'

    # usage: g-alias [--raw] [num-items n] [pattern]
    g-alias() {
      local opt_patt= opt_numitems=999 opt_raw=0
      while [[ -n "$1" ]]; do
        case "$1" in
          -n|--numitems)
            shift; opt_numitems=$1;;
          -r|--raw)
            opt_raw=1;;
          *)
            opt_patt="$1";;
        esac
        shift
      done
      ((opt_verbose)) && echo "g.alias: opt_raw: $opt_raw; opt_numitems: $opt_numitems; opt_patt: $opt_patt"

      local regexp="^alias\.${opt_patt}.*"

      if ((opt_raw)); then
        git config --get-regexp "$regexp" |\
          head -n $opt_numitems
      else
        git config --get-regexp "$regexp" |\
          head -n $opt_numitems |\
          sed -E 's/^alias.([[:alnum:]]+)[[:blank:]]*(.{1,'$((COLUMNS-20))'}).*$/\1 '$'\t'' \2/'
      fi
    }

    # usage: g-pullr [dir ...]
    g-pullr() {
      local dirs="$*"
      [[ -z "$dirs" ]] && dirs="$(find . -depth 1 -type d)"

      local f1=1
      for d in $dirs; do
        ((f1)) && f1= || printf '\n'
        [[ ! -e "$d" ]] && eecho "g-pullr: folder does not exist; aborting" && return 1
        [[ ! -e "$d/.git" ]] && eecho "g-pullr: folder is not a git repo; bypassing $d" && continue
        cd "$d"
        printf '== %s %s\n' "$d" "$(git branch --show-current)"
        git pull --ff-only
        cd ..
      done
    }


    .tick_bpu 'checking for git-flow'
    if type -t git-flow &>/dev/null; then
      # Usage: gf-feature-finish [featureName] [mvn_opts] [gitflow_opts]
      gf-feature-finish() {
        local gitbr="$(git branch --show-current 2> /dev/null)"
        [[ -z "$gitbr" ]] && eecho "gf-feature-finish: not in a git repository" && return 1
        local featureName="${1:-${gitbr#*feature/}}"; [[ -n "$1" ]] && shift
        mvn --batch-mode $1 gitflow:feature-finish -Dverbose=true -DkeepBranch=true -DfeatureName=$featureName $2
      }
      # Usage: gf-feature-start [featureName] [mvn_opts] [gitflow_opts]
      gf-feature-start() {
        local gitbr="$(git branch --show-current 2> /dev/null)"
        [[ -z "$gitbr" ]] && eecho "gf-feature-start: not in a git repository" && return 1
        if [[ -n "$1" ]]; then
          local featureName="$1" && shift
        else
          [[ ! "$gitbr" =~ ^feature/.+ ]] && eecho "gf-feature-start: not in a feature branch and no feature name specified" && return 1
          local featureName="${gitbr#*feature/}"
        fi
        printf "mvn --batch-mode %s gitflow:feature-start -Dverbose=true -DfeatureName=%s %s\n" "$1" "$featureName" "$2"
        mvn --batch-mode $1 gitflow:feature-start -Dverbose=true -DfeatureName=$featureName $2
      }
    fi
    
    .tick_bpu "checking for ~/.git-completion"
    if [[ -e "$HOME/.git-completion" ]]; then
      .tick_bpu "loading git completion from $HOME"
      . "$HOME/.git-completion"
    fi
    complete -p | grep -E -q 'git$' && .tick_bpu "loaded git cli completion" || .tick_bpu "not using git completion"

    .tick_bpu "checking for ~/.git-flow-completion"
    if [[ -e "$HOME/.git-flow-completion" ]]; then
      .tick_bpu "loading git-flow completion from $HOME"
      . "$HOME/.git-flow-completion"
    fi
    .tick_bpu 'FINISHED .setup_git'
  }
  .setup_git && unset -f .setup_git

  .setup_git_prompt() {
    .tick_bpu "STARTING .setup_git_prompt, PS1=$PS1"
    ! type -t git &>/dev/null && .tick_bpu "git not installed" && return 0

    export __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
    .tick_bpu "checking for $__GIT_PROMPT_DIR/gitprompt.sh"
    [[ ! -e "$__GIT_PROMPT_DIR/gitprompt.sh" ]] && .tick_bpu "not using git-prompt" && return 0
    .tick_bpu "using git-prompt in $__GIT_PROMPT_DIR"
    export GIT_PROMPT_ONLY_IN_REPO=
    export GIT_PROMPT_SHOW_UPSTREAM=1
    export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
    export GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=1
    export GIT_PROMPT_THEME='Custom'
    . "$__GIT_PROMPT_DIR/gitprompt.sh"

    .tick_bpu "FINISHED .setup_git_prompt, PS1=$PS1"
  }
  .setup_git_prompt && unset -f .setup_git_prompt


  #
  ### JAVA/JENV
  #
  .setup_java() {
    .tick_bpu 'STARTING .setup_java'

    ! type -t jenv &>/dev/null && .tick_bpu "jenv not installed" && return 0

    .tick_bpu 'checking for jenv'
    if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
      .tick_bpu 'jenv already initialized'
    else
      .tick_bpu 'calling eval $(jenv init -)'
      eval "$(jenv init -)"
      prepend-path "$HOME/.jenv/bin"
      .tick_bpu "initialized jenv"
    fi
    .tickeval_bpu 'echo "using $(jenv --version), java version=$(jenv version)"'
    
    .tick_bpu "trying to set JAVA_HOME from jenv"
    local javahome="$(jenv javahome)"
    if [[ -z "$javahome" ]]; then
      .tick_bpu "jenv reports a blank JAVA_HOME"
    elif [[ ! -d "$javahome" ]]; then
      .tick_bpu "jenv reports a non-directory JAVA_HOME: $javahome"
    elif [[ ! -d "$javahome/bin" ]]; then
      .tick_bpu "jenv non-directory JAVA_HOME/bin: $javahome/bin"
    else
      .tick_bpu "changing JAVA_HOME from: $JAVA_HOME"
      export JAVA_HOME="$javahome"
    fi
    .tick_bpu "using JAVA_HOME: $(tilde-compress "$JAVA_HOME")"

    .tick_bpu 'FINISHED .setup_java'
  }
  .setup_java && unset -f .setup_java


  ### PYENV

  # manually rehash from install location; -v for extra output
  pyenv-rehash-ln() {
    local opt_verbose=; [[ "$1" =~ -v ]] && opt_verbose="v" && shift
    local py_bin="$BREW_PREFIX/Cellar/python@3.9/$(pyenv version-name)/bin"
    local py_shims="$PYENV_ROOT/shims"
    local dot_py_shims="$HOME/dotfiles/pyenv_shims"
    mkdir -p$opt_verbose "$py_shims"
    for f in "$py_bin"/*; do
      ln -sf$opt_verbose "$f" "$py_shims"
    done
    for f in "$dot_py_shims"/*; do
      local shim="$(sed -E 's/^pyenv_|_[^_]+_shiv\.sh$//g' <<< "$(basename $f)")"
      cp -p$opt_verbose "$f" "$py_shims/$shim"
    done
    if [[ -n "$opt_verbose" ]]; then
      eeval 'll $py_shims'
      eeval 'which python3; python3 -V'
      eeval 'which python; python -V'
      eeval 'which pip; pip -V'
    fi
  }

  .setup_pyenv() {
    .tick_bpu 'STARTING .setup_pyenv'

    ! type -t pyenv &>/dev/null && .tick_bpu "pyenv not installed" && return 0

    if [[ -n "$PYENV_ROOT" && "$(type -t pyenv &>/dev/null)" == "function" ]]; then
      .tick_bpu "pyenv already initialized"
    else
      .tick_bpu "initializing pyenv"
      export PYENV_ROOT="$HOME/.pyenv"
      eval "$(pyenv init --path)"
      eval "$(pyenv init -)"
      pyenv-rehash-ln
    fi
    .tickeval_bpu 'echo "using $(pyenv --version 2>/dev/null), python_version=$(pyenv version-name)"'

    .tick_bpu 'FINISHED .setup_pyenv'
  }
  .setup_pyenv && unset -f .setup_pyenv


  #
  ### PYTHON
  # Set up Python aliases, tools and completion if installed.
  .setup_python() {
    .tick_bpu 'STARTING .setup_python'
    ! type -t python &>/dev/null && .tick_bpu "python not installed" && return 0

    .tickeval_bpu 'echo "using python version: $(python --version)"'
    .tickeval_bpu 'echo "using pip version: $(pip --version)"'

    export VIRTUALENVWRAPPER_PYTHON="$(which python)"
    export VIRTUALENVWRAPPER_HOOK_DIR="$HOME/.virtualenvs"

    .tick_bpu "initializing pip completion: python -m pip completion --bash"
    if eval "$(python -m pip completion --bash)"; then
      .tick_bpu "...python -m pip success"
      complete -p | grep -E -q 'pip$' && .tick_bpu "loaded pip cli completion" || .tick_bpu "pip cli completion not loaded  "
    else
      .tick_bpu '...python -m pip FAILURE'
    fi

    .tick_bpu 'FINISHED .setup_python'
  }
  .setup_python && unset -f .setup_python


  #
  ### KUBECTL
  # Set up k8s aliases, tools and completion if installed.
  .setup_kubectl() {
    .tick_bpu 'STARTING .setup_kubectl'
    ! type -t kubectl &>/dev/null && .tick_bpu 'k8s not installed' && return 0

    alias k='kubectl'

    # list all kubectl aliases and functions
    k?() {
      alias \
        | grep -E "^alias k.*='k(ubectl)?" \
        | sed -E "s/^alias //; s/='/=/; s/'$//" \
        | awk -F= '{printf("%-6s \t%s\n", $1, $2);}'
      declare -F \
        | sed -E 's/^declare -f //;' \
        | grep -E '^k-'
    }
    
    alias kc='k config'
    alias kdp='k describe pod'
    alias ke='k explain'
    alias kg='k get'
    alias kgns='k get namespaces'
    alias kgp='k get pods -L alt-name -L app -L version'
    alias kgpa='k get pods --all-namespaces'
    alias kl='k logs --tail -1'
    
    alias ukh='k --help | less'
    alias ugh='k get --help | less'
    alias urh='k run --help | less'
    

    eval "$(kubectl completion bash)"

    .tick_bpu 'FINISHED .setup_kubectl'
  }
  .setup_kubectl && unset -f .setup_kubectl

  .setup_kube-ps1() {
    .tick_bpu "STARTING .setup_kube-ps1, PS1=$PS1"
    ! type -t kubectl &>/dev/null && .tick_bpu "k8s not installed" && return 0

    local kube_ps1_sh="/usr/local/opt/kube-ps1/share/kube-ps1.sh"
    [[ ! -e "$kube_ps1_sh" ]] && .tick_bpu "not using kube-ps1" && return 0

    source "$kube_ps1_sh"
    PS1='$(kube_ps1)'$PS1

    .tick_bpu "FINISHED .setup_kube-ps1, PS1=$PS1"
  }
  .setup_kube-ps1 && unset -f .setup_kube-ps1


  #
  ### CH-Specific
  #
  vault-token-refresh() {
    vault login -method=ldap -no-print username=todd.pierzina password=$SECRET_OKTA_CRED && echo Vault token refreshed.
  }
  

  # get $1 resources (pods/deployments/etc.) for $2 ns, $3 app, [$4 kubectl options/switches]
  k-getres--ns-app() {
    [[ -z "$6" ]] && eecho 'usage: k-getres--ns-app -r res -n ns -a app [kubectl_opts ...]' && return 0
    local k_res k_ns k_app
    
    while [[ -n "$1" ]]; do
      [[ "$1" = "-r" ]] && k_res="$2" && shift 2
      [[ "$1" = "-n" ]] && k_ns="$2" && shift 2
      [[ "$1" = "-a" ]] && k_app="$2" && shift 2
    done
    eeval kubectl -n $k_ns get $k_res -l "app=$k_app" -L 'alt-name,app,version' $*
  }
  
  # get aq-status-reset pods for $1 ns, [$2 kubectl options/switches]
  k-getpods--aq-status-rest() {
    [[ -z "$1" ]] && eecho 'usage: k-getpods--aq-status-rest ns [kubectl_opts ...]' && return 0
    local k_ns="$1"; shift 1
    eeval k-getres--ns-app -r 'pods' -n $k_ns -a 'aq-status-rest' $*
  }
  

  k-logs--ns-app() {
    [[ -z "$1" ]] && eecho "usage: k-logs--app app ns" && return 0
    local k_app="$1"; shift 1
    local k_ns="${1:-prod}"; shift 1
    eeval "kubectl -n $k_ns logs -l app=$k_app --tail -1" \
      "| grep -E '^\{'" \
      "| tee $k_app-$k_ns-${TODAY_YYYYMMDD}.FULL.log.json" \
      "| jq '{timestamp, logger, thread, level, message}'" \
      " > $k_app-$k_ns-${TODAY_YYYYMMDD}.log.json"
    ls -pghF "$k_app-$k_ns-${TODAY_YYYYMMDD}"*
  }
  k-logs--canal-sftp-out-rx-optum-accum() {
    local k_ns="${1:-prod}"; shift 1
    eeval k-logs--ns-app "canal-sftp-out-rx-optum-accum" "$k_ns"
  }
  k-logs--aq-status() {
    local k_ns="${1:-prod}"; shift 1
    eeval k-logs--ns-app "aq-status" "$k_ns"
    eeval k-logs--ns-app "aq-status-rest" "$k_ns"
  }
  k-logs--is-deploy() {
    local k_ns="${1:-claims-pit}"; shift 1
    eeval kubectl -n "$k_ns" exec "intersystems-${k_ns}-0" -- tail -n 20 /data/deploy_logs/intersystems.log
  }
  
  k-pf--aq-status-rest() {
    local k_ns="${1:-prod}"; shift 1
    local k_service='aq-status-rest'
    local k_port='8103'
    eeval kubectl -n $k_ns port-forward services/$k_service $k_port:$k_port
  }
  k-pf--claim-api() {
    local k_ns=${1:-prod}; shift 1
    local k_service='ingenuity-claim-api'
    local k_port='8087'
    eeval kubectl -n $k_ns port-forward services/$k_service $k_port:$k_port
  }
  k-pf--rabbitmq() {
    local k_ns="${1:-prod}"; shift 1
    eeval kubectl -n $k_ns port-forward service/rabbitmq 15672:15672
  }
  
  ssh-airflow-test1() {
    eeval ssh_uswest2 172.31.19.25
  }
  
  ssh-is-prod() { eeval ssh_uswest2 intersystems.prod.cchh.local; }
  ssh-is-preprod() { eeval ssh_uswest2 intersystems.preprod.cchh.local; }
  ssh-is-pit() { eeval kubectl -n claims-pit exec -it -c intersystems intersystems-claims-pit-0 bash; }
  
  scp-from() {
    [[ -z "$2" ]] && eecho "usage: scp-from remote_host remote_file_spec [local_path] [scp_switches ...]" && return 1
    local remote_host="$1" && shift
    local remote_file="$1" && shift
    local local_path="${1:-.}" && shift
    local scp_switches="$*"
    eeval scp_uswest2 -p -r $scp_switches "$remote_host:$remote_file" "$local_path"
  }
  scp-from--is-preprod() {
    [[ -z "$1" ]] && eecho "usage: scp-from--is-preprod remote_file_spec [local_path] [scp_switches ...]" && return 1
    eeval scp-from intersystems.preprod.cchh.local $*
  }
  scp-from--ibmmq-prod() {
    [[ -z "$1" ]] && eecho "usage: scp-from--ibmmq-prod remote_file_spec [local_path] [scp_switches ...]" && return 1
    eeval scp-from root@192.168.1.1 $*
  }

  scp-to() {
    [[ -z "$2" ]] && eecho "usage: scp-to remote_host [local_file_spec ...] [remote_path] [scp_switches ...]" && return 1
    local remote_host="$1" && shift
    local local_file="$1" && shift
    local remote_path="${1:-.}" && shift
    local scp_switches="$*"
    eeval scp_uswest2 -p -r $scp_switches "$local_file" "$remote_host:$remote_path"
  }
  scp-to--is-preprod() {
    [[ -z "$1" ]] && eecho "usage: scp-to--is-preprod local_file_spec [remote_path] [scp_switches ...]" && return 1
    eeval scp-to intersystems.preprod.cchh.local $*
  }

  scp-to-airflow-test1() {
    [[ -z "$2" ]] && eecho "usage: scp-to-airflow-test1 local_dir_or_name remote_file_spec" && return 1
    local local_path="$1" && shift
    [[ ! -e "$local_path" ]] && eecho "scp-to-airflow-test1: '$local_path': No such file or directory" && return 1
    local remote_file="$1" && shift
    # [[ ! "$remote_file" =~ ^/ ]] && remote_file="/opt/airflow/$remote_file"
    eeval scp_uswest2 -p -r "$local_path" "172.31.19.25:$remote_file"
  }
  scp-sql-file-to-airflow-test1() {
    [[ -z "$1" ]] && eecho "usage: scp-airflow-sql-file sql_file_name" && return 1
    local local_path="$1" && shift
    # scp-to-airflow-test1 "$local_path" "airflow@/opt/airflow/dags/cchh_dags/fileflow/claims_reports/sql_files/$(basename '$local_path')"
    scp-to-airflow-test1 "$local_path" "$(basename "$local_path")"
  }

  ssh-ibmmq() {
    cat <<-EOF

IBM MQ Runbook: https://github.com/collectivehealth/runbooks/tree/master/ibm-mq#connecting

$ sudo su - mqm

$ runmqsc PCCHH01  # no prompt will appear

dis ql(*) all   # or qlocal
dis chs(*) where (STATUS eq RUNNING)
dis chs(*) where (STATUS ne RUNNING)
dis chs(*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME
dis chs(INTERSYSTEMS.*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME
dis chs(CANAL.*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME

dis qstatus(*) where (CURDEPTH gt 100)
dis qstatus(*) where (CURDEPTH gt 0)

dis chs(CCHH.ESI.CDH)
dis qstatus(CCHH.ESI.CDH.TQ)
stop channel(CCHH.ESI.CDH)
start channel(CCHH.ESI.CDH)

dis chs(PCCHH01.TO.CVS.ZQM1)
dis qstatus(CCHH.CVS.TQ)
stop channel(PCCHH01.TO.CVS.ZQM1)
start channel(PCCHH01.TO.CVS.ZQM1)

dis chs(CVS.ZQM1.TO.PCCHH01)
stop channel(CVS.ZQM1.TO.PCCHH01)
dis chs(CVS.ZQM1.TO.PCCHH01)
start channel(CVS.ZQM1.TO.PCCHH01)

dis chs(ESI.CDH.CCHH)
stop channel(ESI.CDH.CCHH)
dis chs(ESI.CDH.CCHH)
start channel(ESI.CDH.CCHH)

# bounce mq
$ endmqm PCCHH01
$ strmqm PCCHH01

EOF
    # cchh arrow ssh root@ibm_mq_uswest2_01
    eeval ssh_uswest2 root@192.168.1.1
  }
  #
  export CCHH_AUG_HOME="$HOME/cchh-extra/canal-aqueduct-tools/aug"
  export CCHH_AUG_VENV="$VIRTUALENVWRAPPER_HOOK_DIR/aug"
  aug() {
    [[ "$VIRTUAL_ENV" != "$CCHH_AUG_VENV" ]] && . "$CCHH_AUG_VENV/bin/activate"
    command aug "$@"
  }
  #


  # # Used by profile badge to show pwd (lowercase) via user.tildePath variable.
  # # From: https://iterm2.com/documentation-scripting-fundamentals.html
  #
  # Disabled since it doesn't play so well w git-prompt.
  #
  # iterm2_print_user_vars() {
  #   iterm2_set_user_var 'tildePath' "$(tilde-compress "$PWD" | lower)"
  # }

  alias .reload-shell='exec $SHELL -l'
  alias .rls='.reload-shell'

  alias .reload-bash-profile='. $HOME/.bash_profile'
  alias .rlbp='.reload-bash-profile'

  alias .reload-bash-profile-user='. $HOME/.bash_profile.$USER'
  alias .rlbpu='.reload-bash-profile-user'

  .tickeval_bpu 'printf -- "FINISH PID,PPID=%s \$SHLVL=%s \$_=[%s] \$-=[%s]\n" "$PID_PPID_BPU"'
  # >&2 echo "FINISHED .bash_profile_USER"
}
# .tick_bpu 'Calling bash_profile_USER'
.bash_profile_USER "$@" && unset -f .bashrc_profile_USER
