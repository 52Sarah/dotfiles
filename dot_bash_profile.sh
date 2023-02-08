#!/usr/bin/env bash

# For interactive/login shells, Bash reads, in order:
#   - ~/.bash_profile || ~/.bash_login || ~/.profile
#   - once it finds one it stops looking
# For non-interactive shells, Bash reads the $BASH_ENV file (usually ~/.bashrc).
# For any shells invoked as 'sh', Bash reads the $ENV file (usually ~/.profile).

# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# TICK_x variables control its behavior; all default to false/0/off.
# export TICK_DISABLED= TICK_ENABLED=
# export TICK_STDERR= TICK_STDOUT=
export TICK__INDENT=
. ~/.tick.sh
.tick-bash-profile() { .tick -s '.bash_profile' "$@"; }

.tick-bash-profile "[START-FILE] (\$\$=[$$], \$PATH=[$PATH], \$PS1=[$PS1])"

export BASH_ENV=~/.bashrc
export ENV=~/.profile

[[ -e "$BASH_ENV" ]] && . "$BASH_ENV"

export EDITOR=vim
export CLICOLOR=1

# Uncomment to color output even when being piped.
# Turning this on has an adverse interaction with a few tools.
export CLICOLOR_FORCE=1

# See: https://ss64.com/bash/less.html
# -#, --shift               Percent of screen to scroll right and left for wide files
# -A, --SEARCH-SKIP-SCREEN  Search just after current line, not visible page
# -F, --quit-if-one-screen  Do not display prompt for short files
# -g, --hilite-search       Only hilite one search result
# -i, --ignore-case         Ignore case unless pattern contains uppercase letters
# -J, --status-column       Displays column at left for search matches
# -m, --long-prompt         Prompts like 'more'; -M even more verbose
# -n, --line-numbers        Suppress line numbers in prompt
# -N, --LINE-NUMBERS        Show line numbers at start of each line
# -q, --quit-at-eof         Exit second time at eof, not just with 'q'; -Q quits first time
# -r, --raw-control-chars   Render all escape sequences properly; -R renders only colors
# -s, --squeeze-blank-lines Consecutive blank lines shown as one
# -S, --chop-long-lines     Truncate long lines, do not wrap
# -w, --hilite-unread       Highlight "new" line after 1+ pages forward movement; -W after any 1+ lines
# -X, --no-init             Do not clear screen when loading
export LESS='--shift=.33 --SEARCH-SKIP --quit-if-one --status-col --LONG-PR --quit-at-eof --raw --squeeze --HILITE-UNREAD --no-init'
export LESSEDIT='subl --new-window --wait --stay %f\:%lm'

# Ignore repeated lines and lines starting with ' '
export HISTCONTROL=ignoreboth
export HISTSIZE=100000
export HISTFILESIZE=$HISTSIZE
export HISTTIMEFORMAT='%m/%d %H:%M:%S  '

# Exclude from tab completion
export FIGNORE='DS_Store:Icon?'

#
### 'cd' helpers
#
# Change directory to the given link's target, either the file's parent or the directory itself.
cd-ln() {
  local link="$1" target
  [[ -z "$link" ]] && eecho "usage: cd-ln link_to_dir | link_to_file" && return 1
  [[ ! -e "$link" ]] && eecho "cd-ln: $link: no such symlink" && return 1
  [[ ! -L "$link" ]] && eecho "cd-ln: $link: not a symlink" && return 1
  local target="$(readlink "$link")"
  veval cd "$link"
  if [[ -d "$target" ]]; then
      veval cd "$target"
  else
      veval cd "$(dirname "$target")"
  fi
}

#
### 'chmod' helpers
#
# Make specified, or all in PWD, shell scripts executable.
chx() {
  local opt_verbose=$((SH_VERBOSE))
  [[ "$1" =~ ^(-v|--verbose)$ ]] && shift && opt_verbose=1
  
  local files=($@)
  [[ ! "$1" ]] && files=(*.sh) && opt_verbose=1

  ((opt_verbose)) && opt_verbose="-vv" || opt_verbose=
  qeval chmod $opt_verbose +x "${files[@]}"
}

#
### 'find' helpers
#
# -L = follow symlinks
# -E = use extended (modern) regexes
# alias nfind='qeval find -L -E . -name'
alias pfind='qeval find -L -E . -path'
alias rfind='qeval find -L -E . -regex'
nfind() {
  local usage="usage: nfind [path ...] glob_pattern [find_expr ...]"
  [[ -z "$1" ]] && eecho "$usage" && return 1
  local paths=
  while [[ -e "$1" ]]; do
    paths="$paths $1"; shift
  done
  [[ -z "$paths" ]] && paths="."
  qeval find -L -E $paths -name $@
}

#
### 'history' helpers
#
history-grep() {
  local USAGE='Usage: history-grep [--dates] [--num-lines lines] [--unique] [pattern]'
  local opt_dates=0 opt_num_lines=0 opt_unique=0 pattern='.*'
  while [[ -n "$1" ]]; do case "$1" in
    -d|--date*)     opt_dates=1; shift;;
    -n|--num-lines) opt_num_lines=$2; shift 2;;
    -u|--unique)    opt_unique=1; shift;;
    *)              pattern="$@";;
  esac; done
  [[ -z "$opt_num_lines" ]] && eprintf "history-grep: option requires a numeric argument: --num-lines\n$USAGE\n"
  local htf=; ((opt_dates)) && htf="$HISTTIMEFORMAT"
  
  local c="HISTTIMEFORMAT='$htf' history"
  ((opt_unique)) 
  [[ -n "$@" ]] && c="c | egrep $@"
  ((opt_num_lines > 0)) && c="$c $opt_num_lines"
  qeval "$c | less"
}
alias hg='qeval history-grep'

#
### 'less' helpers:
# 
alias l='less'
#
# Lines will NOT wrap, but CTRL-C, arrow keys can scroll left and right. Press 'F' to resume "tailing".
alias tl='qeval less --chop-long-lines +F'

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
alias l1='qeval ls -1F'
alias l1r='qeval l1 -r'
#
alias ll='ls -oghF'
alias llt='qeval ll -t'
alias lltr='qeval ll -tr'
alias lls='qeval ll -S'
alias llsr='qeval ll -Sr'
#
alias la='ls -AlhF'
alias lat='qeval la -t'
alias latr='qeval la -tr'
alias las='qeval la -S'
alias lasr='qeval la -Sr'
#
alias l1d='qeval l1 -d'
alias lad='qeval la -d'
#
# Think "ll and la but narrower": cut out permissions, link count and owner.
#   $ ls -ohF
#   total 520
#   -rw-r--r--  1 toddpierzina   1.2K Mar 10 11:33 README.md
# $1: permissions, $2: inode count, $3: owner, $4: size, $5: date/time, $6: filename
lln() {
  ls -oF $@ \
  | sed -E \
    -e '/^total .+$/d' \
    -e 's/^([^ ]{9,}) +([[:digit:]]+) +([^ ]+) +([^ ]+) ([^ ]+ +[^ ]+ +[^ ]+) +(.+)$/\4'$'\t''\5'$'\t''\6/' \
    -e "s:\\$HOME:\\~:g" \
  | awk -F$'\t' \
    '{printf "%12'$'\'''d  %s  %s\n", $1, $2, $3}'
}
alias lan='lln -A'
#
# Display permissions in octal, from: http://askubuntu.com/a/152005
# I've tried to figure out how this works but have no fucking clue.
lso() {
  ls -ohF $@ \
  | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' \
  | sed -E -e "s:\\$HOME:\\~:g"
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
  line_width=$COLUMNS; ((line_width < 100)) && line_width=100
  ps_cmd="ps -e -o user,pid,ppid,start,time,%cpu,%mem,command"
  if [[ -n "$1" ]]; then
    ps_cmd="$ps_cmd | egrep -e 'USER\s+PID\s+PPID'"
    while [[ -n "$1" ]]; do
      ps_cmd="$ps_cmd -e '$1'" && shift
    done
  fi
  ps_cmd="$ps_cmd | cut -c 1-12,19-$line_width | egrep -v -e '$$ .+ egrep -e USER'"
  qeval $ps_cmd
}

### 'rm' helpers
#
# Delete the target of a symlink, then the symlink.
rm-ln() {
  local cmd="rm"
  while [[ "$1" =~ ^- ]]; do cmd="$cmd $1" && shift; done

  local link="$1" && shift
  [[ -z "$link" ]] && eecho "usage: rmln [rm opts] symlink" && return 1
  [[ ! -L "$link" ]] && eecho "rmln: $link: no such symlink" && return 1

  local dest="$(readlink "$link")"
  [[ ! -e "$dest" ]] && eecho "rmln: $link -> $dest: no such file or directory" && return 1
  qeval "$cmd '$dest'"
}

#
### 'tail' helpers
#
alias t='tail'
alias tf='tail -f'

#
### terminal helpers
#
# toggle wrap/truncate
alias term-wrap='qeval tput smam'
alias term-trunc='qeval tput rmam'

#
### 'touch' helpers
#
# Update mtime of folders with latest mtime of its contents
touchd() {
  [[ -z "$1" ]] && eecho "usage: touchd dir [...]" && return 1
  local SH_VERBOSE=$((SH_VERBOSE))
  local count=0 arg
  for arg in $@; do
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
      qeval touch -r "$dir/$newest" "$dir"
      [[ -L "$dir" ]] && qeval touch -h -r "$dir/$newest" "$dir"
      
      ((count++))
  done
  ((!count)) && return 1
  vecho "touchd: updated $count directories"
}
#
touchd-R() {
  local dirs=($@)
  [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
  for dir in "${dirs[@]}"; do
      [[ "$dir" =~ ^(-v|--verbose)$ ]] && [[ -n "$SH_VERBOSE" ]] && continue
      find "$dir" -depth ! -type f -print |\
      while read -r subdir; do
          qeval touchd "$subdir"
      done
      qeval touchd "$dir"
  done
}


#
# glob/symlink helpers
#
glob-path-count() {
    [[ -z "$1" ]] && eecho "usage: glob-path-count patt [...]" && return 1
    ls -1d $@ 2> /dev/null | wc -l
}
# Convenience version of [[ -e "file*" [&& ...] ]] since test won't take wildcards/globs.
glob-path-exists() {
    [[ -z "$1" ]] && eecho "usage: glob-path-exists patt" && return 1
    ls -1d $1 >& /dev/null
}
# First matching path for given pattern
glob-path-first() {
    [[ -z "$1" ]] && eecho "usage: glob-path-first patt" && return 1

    local save_clicolor_force=${CLICOLOR_FORCE}
    unset CLICOLOR_FORCE

    if local paths="$(ls -1d $1 2> /dev/null)"; then
      head -n 1 <<< "$paths"
      export CLICOLOR_FORCE=$save_clicolor_force
      return 0
    else
      export CLICOLOR_FORCE=$save_clicolor_force
      return 1
    fi
}
#
is-valid-symlink() {
    [[ -z "$1" ]] && eecho "usage: is-valid-symlink file" && return 1
    [[ -L "$1" && -e "$1" ]] 
}

# Inspect $1 and, using javascript-like truthy rules, return status 0 (true) or 1 (false).
# Usage: parse-bool [--echo] value
# If --echo is specified, 1 or nothing is echoed to stdout; else just the status is returned.
# Examples, in each case leaving some_var == 1 (if value is true) or empty (false).
# - parse-bool "true" && some_var=1
# - some_var=$(parse-bool --echo "true")
# Truthiness:
# - false: <unset>, "", "0", "false", "no", "null" or "undefined"
# - true:  any non-blank that doesn't evaluate to false is true
parse-bool() {
    [[ "$1" =~ -?-e(cho)? ]] && do_echo=1 && shift
    val="$1"; shift

    # ret=0: true; ret=1: false; but echo 1 for true, nothing for false. Nice.
    ret=0
    [[ -z "$val" || "$val" =~ ^(0|false|no|null|undefined)$ ]] && ret=1

    [[ -n "$do_echo" && $ret == 0 ]] && echo "1"
    return $ret
}

#
### fixed-width file helpers
#
# Record lengths along with count of each length, in the same sequence as file.
record-lengths() {
  [[ -z "$1" ]] && >&2 echo "usage: record-lengths file [...]" && return 1
  local files=$@
  for f in $files; do
    printf "%s\n  %s\n" "$f" "$(awk '{print length($0)}' "$f" | sort -n | uniq -c)"
  done
}
alias recl='qeval record-lengths'
#
# View a fix-width file in a more human-readable format.
fwf-nice() {
  local USAGE="usage: fwf-nice [-d delim] file [col-expr [...]"
  local delim='|'; [[ "$1" =~ ^-d|--delim$ ]] && delim="$2" && shift 2
  local is_pipe=; [[ ! -t 0 ]] && is_pipe=1
  
  local fwf=; ((! is_pipe)) && fwf="$1" && shift
  # [[ -z "$fwf" ]] && eecho "$USAGE" && return 1
  ((! is_pipe)) && [[ ! -f "$fwf" ]] && eecho "fwf-nice: $fwf: No such file" && return 1
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

# # Used by profile badge to show pwd (lowercase) via user.tildePath variable.
# # From: https://iterm2.com/documentation-scripting-fundamentals.html
#
# Disabled since it doesn't play so well w git-prompt.
#
# iterm_print_vars() {
#   iterm_set_var 'tildePath' "$(tilde-compress "$PWD" | lower)"
# }

.bash_profile_sets() {
  # .tick-bash-profile -e 'printf "[start] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'

  # Usage: 'set -o name' enables "name" and 'set +o name' disables it. 
  # Some have a single letter equivalent following the same pattern.
  # The list below shows letter and name.
  #
  # Default enabled shell options/variables:
  #   $SHELLOPTS = braceexpand:emacs:hashall:histexpand:history:interactive-comments:monitor
  #   $- = himBH
  
  # toggled from defaults:
  set    +o emacs
  set    -o ignoreeof   # ctrl-d won't close session
  set    -o vi          # vi-style line editing

  # set -B -o braceexpand
  # set +e +o errexit
  # set +E +o errtrace
  # set +T +o functrace
  # set -h -o hashall     # remember command location in history
  # set -H -o histexpand  # !-style history substitution
  # set    -o history
  # set    -o interactive-comments
  # set -m -o monitor     # job control enabled
  # set +C +o noclobber   # "noclobber"--files cannot be overwritten by redirection
  # set +n +o noexec      # read commands but don't execute
  # set +u +o nounset     # treat unset variable substitution as error
  # set +t +o onecmd      # exit after executing one command
  # set +v +o verbose     # print shell lines as they are read
  # set +x +o xtrace      # print commands and args as they are executed
  # set -i                # indicates shell is interactive; read-only

  # .tick-bash-profile -e 'printf "[end] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'
}
.bash_profile_sets

.bash_profile_shopts() {
  # .tick-bash-profile -e 'printf "[start] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
  
  # Usage: 'shopt -s optname' enables (SETS) the option; -u (UNSET) disables it.
  # Default enabled options: cdspell:checkwinsize:cmdhist:expand_aliases:extglob:
  #                          extquote:force_fignore:histappend:hostcomplete:interactive_comments:
  #                          login_shell:progcomp:promptvars:sourcepath
  # See: https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html

  # toggled from defaults:
  shopt -u cdable_vars            # if cd's arg is not a directory, try it as a variable
  shopt -s checkhash              # check hash table before a normal path search
  shopt -s dotglob                # include files starting with . in glob expansion
  
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

  # shopt -u compat31               # see https://www.gnu.org/software/bash/manual/html_node/Shell-Compatibility-Mode.html
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

  # .tick-bash-profile -e 'printf "[end] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
}
.bash_profile_shopts


#
###  HOMEBREW
#
.setup-homebrew() {
  .tick-bash-profile '[start] .setup-homebrew'
  if ! type -t brew &>/dev/null; then
    .tick-bash-profile "... homebrew not installed"
    return 0
  fi

  ((SH_VERBOSE)) && printf "\$\$ .setup-homebrew: before 'brew shellenv':\n" && eeval path-list
  eval "$(brew shellenv 2>/dev/null)"
  ((SH_VERBOSE)) && printf "\$\$ .setup-homebrew: after 'brew shellenv':\n" && eeval path-list
  if [[ -z "$HOMEBREW_PREFIX" ]]; then
    .tick-bash-profile "... homebrew 'shellenv' did not set \$HOMEBREW_PREFIX"
    return 1
  fi
  # Let path-prepend de-dupe the /usr/local/... paths.
  path-prepend PATH /usr/local/sbin
  path-prepend PATH /usr/local/bin
  .tick-bash-profile "... \$HOMEBREW_PREFIX=$HOMEBREW_PREFIX"

  alias bs='qeval brew services'
  safe-source -q /usr/local/etc/bash_completion.d/brew && .tick-bash-profile '... loaded brew completion' || .tick-bash-profile '!!! failed to load brew completion'

  local gnu_getopt_home="$HOMEBREW_PREFIX/opt/gnu-getopt"
  if [[ -e "$gnu_getopt_home" ]]; then
    path-prepend PATH "$gnu_getopt_home/bin"
    .tick-bash-profile "... prepended gnu-getopt/bin to PATH"
  fi

  .tick-bash-profile "[end] .setup-homebrew, PATH=$PATH"
}
.setup-homebrew


#
###  ITERM window/tab titles
#
.setup-iterm() {
  .tick-bash-profile '[start] .setup-iterm'
  [[ "$TERM_PROGRAM" != "iTerm.app" ]] && .tick-bash-profile "... iTerm2 not installed" && return 1

  # From https://superuser.com/a/344397/17666
  # $1 = type; 0 - both, 1 - tab, 2 - window
  set-terminal-text () {
    [[ -z "$2" || ! "$1" =~ -b|-t|-w ]] && eecho "usage: set-terminal-text --both|--tab|--window text" && return 1
    local mode=0
    [[ "$1" =~ -t ]] && mode=1
    [[ "$1" =~ -w ]] && mode=2
    shift
    echo -ne "\033]$mode;$@\007"
  }

  .tick-bash-profile "[end] .setup-iterm, ITERM_PROFILE=$ITERM_PROFILE"
}
.setup-iterm


#
###  GIT
#
.setup-git() {
  .tick-bash-profile '[start] .setup-git'
  ! type -t git &>/dev/null && .tick-bash-profile "[end] .setup-git: git not installed" && return 0

  .tick-bash-profile "... using $(git --version)"

  alias g='git'

  # usage: g-alias [--raw] [num-items n] [pattern]
  git-alias() {
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
    ((opt_verbose)) && echo "git-alias: opt_raw: $opt_raw; opt_numitems: $opt_numitems; opt_patt: $opt_patt"

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

  # cd into each given directory and perform a git pull --ff-only
  # usage: git-pulld [dir ...]
  git-pulld() {
    local dirs="$@"
    [[ -z "$dirs" ]] && dirs="$(find . -maxdepth 1 -type d)"

    local f1=1
    for d in $dirs; do
      ((f1)) && f1= || printf '\n'
      [[ ! -e "$d" ]] && eecho "g-pulld: folder does not exist; aborting" && return 1
      [[ ! -e "$d/.git" ]] && eecho "g-pulld: folder is not a git repo; bypassing $d" && continue
      cd "$d"
      printf '== %s %s\n' "$d" "$(git branch --show-current)"
      qeval git pull --ff-only
      cd ..
    done
  }

  # update local mtime based on git log
  # from: https://stackoverflow.com/a/2038768/160955
  git-touch() {
    [[ -z "$1" ]] && eecho "usage: git-touch file [...]" && return 1
    while [[ -n "$1" ]]; do
      local f="$1"; shift
      local rev="$(git rev-list -n 1 "HEAD" "$f")"
      local commit_sec="$(git show --pretty=format:%at --abbrev-commit "$rev" | head -n 1)"
      local commit_ts="$(date -r $commit_sec '+%Y%m%d%H%M.%S')"
      ((!SH_QUIET)) && printf 'before: ' && ls -oghF "$f"
      qeval touch -h -t "$commit_ts" "$f"
      ((!SH_QUIET)) && printf 'after:  ' && ls -oghF "$f"
    done      
  }

  .tick-bash-profile "... checking for ~/.git-completion"
  safe-source -q ~/.git-completion
  complete -p | grep -E -q 'git$' && .tick-bash-profile "... loaded git cli completion" || .tick-bash-profile "... not using git completion"

  .tick-bash-profile '... checking for git-flow'
  if type -t git-flow &>/dev/null; then
    # https://github.com/aleksandr-m/gitflow-maven-plugin

    .tick-bash-profile "... checking for ~/.git-flow-completion"
    safe-source -q ~/.git-flow-completion
    complete -p | grep -E -q 'git-flow$' && .tick-bash-profile "... loaded git-flow cli completion" || .tick-bash-profile "... not using git-flow completion"

    # Usage: gf-feature-start featureName [mvn_opts] [gitflow_opts]
    gf-feature-start() {
      local gitbr="$(git branch --show-current 2> /dev/null)"
      [[ -z "$gitbr" ]] && eecho "gf-feature-start: not in a git repository" && return 1
      local featureName="${1#*feature/}"; shift  # everything after "feature/", else entire string
      local mvn_opts="$1"; shift
      local gitflow_opts="$1"; shift
      qeval mvn --batch-mode "$mvn_opts" gitflow:feature-start -Dverbose=true -DfeatureName="$featureName" -DpushRemote=true "$gitflow_opts"
    }
  
    # Usage (from feature branch): gf-feature-finish -m [mvn_opts] -g [gitflow_opts]
    gf-feature-finish() {
      local gitbr="$(git branch --show-current 2> /dev/null)"
      [[ -z "$gitbr" ]] && eecho "gf-feature-finish: not in a git repository" && return 1
      local featureName="${gitbr#*feature/}"
      local mvn_opts="$1"; shift
      local gitflow_opts="$1"; shift
      qeval mvn --batch-mode "$mvn_opts" gitflow:feature-finish -Dverbose=true -DkeepBranch=true -DfeatureName="$featureName" -DfeatureSquash=true -DincrementVersionAtFinish=true "$gitflow_opts"
    }
  fi
    
  .setup-git-prompt() {
    .tick-bash-profile "[start] .setup-git-prompt, PROMPT_COMMAND=[$PROMPT_COMMAND]"

    export __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
    local gitprompt_sh="$__GIT_PROMPT_DIR/gitprompt.sh"
    [[ ! -e "$gitprompt_sh" ]] && .tick-bash-profile "[end] .setup-git-prompt: $gitprompt_sh: No such file" && return 0

    # results in prefixing setLastCommandState; to PROMPT_COMMAND, which sets GIT_PROMPT_LAST_COMMAND_STATE=$?
    # and calls setGitPrompt which calls updatePrompt to override any prior PS1
    .tick-bash-profile "... loading $gitprompt_sh"
    export GIT_PROMPT_ONLY_IN_REPO=
    export GIT_PROMPT_SHOW_UPSTREAM=1
    export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
    export GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=1
    export GIT_PROMPT_THEME='Custom'
    . "$gitprompt_sh" 
    
    .tick-bash-profile "[end] .setup-git-prompt"
  }
  .setup-git-prompt 

  .tick-bash-profile '[end] .setup-git'
}
.setup-git


#
### SDKMAN/JAVA
#
.setup-java-sdkman() {
  .tick-bash-profile '[start] .setup-java-sdkman'
  [[ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && .tick-bash-profile "[end] SDKMAN not installed" && return 0

  export SDKMAN_DIR="$HOME/.sdkman"

  if [[ "$(type -t sdk &>/dev/null)" == "function" ]]; then
    .tick-bash-profile 'sdkman already initialized'
  else
    .tick-bash-profile '... initializing sdkman'
    . "$SDKMAN_DIR/bin/sdkman-init.sh"
    path-prepend "$SDKMAN_DIR/bin"
    .tick-bash-profile "... initialized sdkman"
  fi
  # .tick-bash-profile -e 'echo "... using $(sdkman version)"'
  # .tick-bash-profile -e 'echo "... $ which javac: $(2>&1 which javac)"'
  # .tick-bash-profile -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
  
  if [[ -z "$JAVA_HOME" ]]; then
    .tick-bash-profile "sdkman left a blank JAVA_HOME"
  elif [[ ! -d "$JAVA_HOME" ]]; then
    .tick-bash-profile "sdkman left a non-directory JAVA_HOME: $JAVA_HOME"
  elif [[ ! -d "$JAVA_HOME/bin" ]]; then
    .tick-bash-profile "sdkman non-directory JAVA_HOME/bin: $JAVA_HOME/bin"
  fi

  sdk-set-java-home() {
    [[ -z "$1" ]] && eecho "usage: sdk-set-java-home version_glob" && return 1
    local version_glob="$1*"; shift
    local java_cand_dir="$(glob-path-first $SDKMAN_DIR/candidates/java/$version_glob)"
    echo "java_cand_dir=$java_cand_dir"
    # qeval export JAVA_HOME="$(cd-ln "$java_cand_dir/bin"; cd "$(pwd -P)/.."; pwd)"
    qeval export JAVA_HOME="$(cd "$java_cand_dir/bin"; cd "$(pwd -P)/.."; pwd)"
  }

  .tick-bash-profile -e tilde-compress "[end] .setup-java-sdkman, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
}
.setup-java-sdkman


#
### JENV/JAVA
#
if ! type -t sdk &>/dev/null; then
  .setup-java-jenv() {
    .tick-bash-profile '[start] .setup-java-jenv'
    ! type -t jenv &>/dev/null && .tick-bash-profile "[end] .setup-java-jenv, jenv not installed" && return 0

    if [[ "$(type -t jenv &>/dev/null)" == "function" ]]; then
      .tick-bash-profile 'jenv already initialized'
    else
      .tick-bash-profile '... initializing jenv'
      eval "$(jenv init --no-rehash -)"
      path-prepend "$HOME/.jenv/bin"
      .tick-bash-profile "... initialized jenv"
    fi
    # .tick-bash-profile -e 'echo "... using $(jenv --version)"'
    # .tick-bash-profile -e 'echo "... using java $(jenv version)"'
    # .tick-bash-profile -e 'echo "... $ which javac: $(2>&1 which javac)"'
    # .tick-bash-profile -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
    
    local javahome="$(jenv javahome)"
    if [[ -z "$javahome" ]]; then
      .tick-bash-profile "jenv reports a blank JAVA_HOME"
    elif [[ ! -d "$javahome" ]]; then
      .tick-bash-profile "jenv reports a non-directory JAVA_HOME: $javahome"
    elif [[ ! -d "$javahome/bin" ]]; then
      .tick-bash-profile "jenv non-directory JAVA_HOME/bin: $javahome/bin"
    else
      export JAVA_HOME="$javahome"
    fi

    .tick-bash-profile -e tilde-compress "[end] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
  }
  .setup-java-jenv
fi


#
### POSTGRESQL
#
.setup-pg() {
  .tick-bash-profile '[start] .setup-pg'
  export HOMEBREW_POSTGRESQL_SERVICE="$(readlink /usr/local/opt/postgresql)"
  [[ ! -e "$HOMEBREW_POSTGRESQL_SERVICE" ]] && .tick-bash-profile '[end] .setup-pg, no /usr/local/opt/postgresql, pg not installed' && return 1
  path-append '/usr/local/opt/postgresql/bin'
  alias pg-restart='qeval brew services restart $HOMEBREW_POSTGRESQL_SERVICE'
  alias pg-start='qeval brew services start $HOMEBREW_POSTGRESQL_SERVICE'
  alias pg-stop='qeval brew services stop $HOMEBREW_POSTGRESQL_SERVICE'
  .tick-bash-profile '[end] .setup-pg, PATH=$PATH"'
}
.setup-pg


#
### VIRTUAL BOX general helpers
#
.setup-vbox() {
  ! type -t VBoxManage &>/dev/null && .tick-bash-profile '[end] .setup-vbox, VirtualBox not installed' && return 1

  export VBOX_VMS_HOME="$HOME/VirtualBox VMs"

  alias vb='qeval VBoxManage'
  alias vb-ls='qeval VBoxManage list'
  #
  vb-status() {
    printf '\n'
    qeval "vb-ls --long --sorted vms | egrep '^(Name|State|UUID):\s{2,}'" \
      | sed -E -e 's/^(State:.+\))/\1\n/'
    
    qeval "vb-ls runningvms"
    printf '\n'
    
    qeval "vb-ls hostonlynets" \
      | egrep '.+'
    printf '\n'
  }

  # Lookup full vm name given a pattern; if not found, return pattern with error status.
  vb-vm-name() {
    [[ -z "$1" ]] && eecho "usage: vb-vm-name patt" && return 1
    local patt="$1" && shift
    local save_clicolor_force=${CLICOLOR_FORCE}
    unset CLICOLOR_FORCE
    if ls -1A "$VBOX_VMS_HOME/" | egrep -i "$patt"; then
      export CLICOLOR_FORCE=$save_clicolor_force
      return 0
    else
       echo "$patt"
       export CLICOLOR_FORCE=$save_clicolor_force
       return 1
    fi
  }

  vb-start() {
    [[ -z "$1" ]] && eecho "usage: vb-start vm_name [startvm options]" && return 1
    local vm_name="$1" && shift
    qeval VBoxManage startvm \"$vm_name\" $@
  }
  vb-controlvm() {
    [[ -z "$2" ]] && eecho "usage: vb-controlvm vm_name_patt cmd [controlvm cmd options]" && return 1
    local vm_name_patt="$1" && shift
    local cmd="$1" && shift
    qeval VBoxManage controlvm \"$(vb-vm-name $vm_name_patt)\" $cmd $@
  }
  vb-reboot() {
    [[ -z "$1" ]] && eecho "usage: vb-reboot vm_name" && return 1
    local vm_name_patt="$1" && shift
    vb-controlvm "$(vb-vm-name $vm_name_patt)" reboot $@
  }
  vb-shutdown() {
    [[ -z "$1" ]] && eecho "usage: vb-shutdown vm_name_patt [--force]" && return 1
    local vm_name_patt="$1" && shift
    vb-controlvm "$(vb-vm-name $vm_name_patt)" shutdown $@
  }
  vb-poweroff() {
    [[ -z "$1" ]] && eecho "usage: vb-poweroff vm_name_patt [--type=gui|headless|..., other startvm options]" && return 1
    local vm_name_patt="$1" && shift
    vb-controlvm "$(vb-vm-name $vm_name_patt)" poweroff $@
  }

  vb-tail() {
    [[ -z "$1" ]] && eecho "usage: vb-tail vm_name_patt [-f or other tail options]" && return 1
    local vm_name_patt="$1" && shift
    qeval tail $@ '"$VBOX_VMS_HOME/$(vb-vm-name $vm_name_patt)/Logs/VBox.log"'
  }
}
.setup-vbox


#
### MAPR (client)
#
.setup-mapr() {
  .tick-bash-profile '[start] .setup-mapr'
  [[ ! -e "/opt/mapr" ]] && .tick-bash-profile '[end] .setup-mapr, no such directory: /opt/mapr' && return 1

  export MAPR_HOME="/opt/mapr"
  path-append PATH "$MAPR_HOME/bin"

  .tick-bash-profile "[end] .setup-mapr, MAPR_HOME=$MAPR_HOME, PATH=$PATH"
}
.setup-mapr


#
### HADOOP (client & server, not embedded in MapR)
#
.setup-hadoop() {
  .tick-bash-profile '[start] .setup-hadoop'
  [[ ! -e "/opt/hadoop" ]] && .tick-bash-profile '[end] .setup-hadoop, no such directory: /opt/mapr' && return 1

  export HADOOP_HOME="/opt/hadoop"
  path-prepend PATH "$HADOOP_HOME/sbin"
  path-prepend PATH "$HADOOP_HOME/bin"

  export HADOOP_LIBEXEC_DIR="$HADOOP_HOME/libexec"
  export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
  export HADOOP_LOG_DIR="/var/log/hadoop"

  .tick-bash-profile "[end] .setup-hadoop, HADOOP_HOME=$HADOOP_HOME, PATH=$PATH"
}
.setup-hadoop


#
### GRADLE/GRADLEW
#
alias gw='qeval ./gradlew'
#
# -a, --no-rebuild                   Do not rebuild project dependencies.
# --build-cache                      Enables the Gradle build cache. Gradle will try to reuse outputs from previous builds.
# --configure-on-demand              Configure necessary projects only. Gradle will attempt to reduce configuration time for large multi-project builds. [incubating]
# --continue                         Continue task execution after a task failure.
# -D, --system-prop                  Set system property of the JVM (e.g. -Dmyprop=myvalue).
# -d, --debug                        Log in debug mode (includes normal stacktrace).
# --daemon                           Uses the Gradle daemon to run the build. Starts the daemon if not running.
# -I, --init-script                  Specify an initialization script.
# -i, --info                         Set log level to info.
# -m, --dry-run                      Run the builds with all task actions disabled.
# --no-build-cache                   Disables the Gradle build cache.
# --no-configure-on-demand           Disables the use of configuration on demand. [incubating]
# --no-daemon                        Do not use the Gradle daemon to run the build. Useful occasionally if you have configured Gradle to always run with the daemon by default.
# --no-parallel                      Disables parallel execution to build projects.
# --no-scan                          Disables the creation of a build scan. For more information about build scans, please visit https://gradle.com/build-scans.
# --no-watch-fs                      Disables watching the file system.
# --offline                          Execute the build without accessing network resources.
# -P, --project-prop                 Set project property for the build script (e.g. -Pmyprop=myvalue).
# -p, --project-dir                  Specifies the start directory for Gradle. Defaults to current directory.
# -q, --quiet                        Log errors only.
# --refresh-dependencies             Refresh the state of dependencies.
# --rerun-tasks                      Ignore previously cached task results.
# -s, --stacktrace                   Print out the stacktrace for all exceptions.
# --status                           Shows status of running and recently stopped Gradle daemon(s).
# --stop                             Stops the Gradle daemon if it is running.
# -w, --warn                         Set log level to warn.
# --warning-mode                     Specifies which mode of warnings to generate. Values are 'all', 'fail', 'summary'(default) or 'none'
# --watch-fs                         Enables watching the file system for changes, allowing data about the file system to be re-used for the next build.
# --write-locks                      Persists dependency resolution for locked configurations, ignoring existing locking information if it exists
# -x, --exclude-task                 Specify a task to be excluded from execution.
gw-task() {
  local USAGE='Usage: gw-task [wrapper_opt... --] task [opt...]'
  local wrapper_opts= task_opts=
  while [[ -n "$1" ]]; do
    case "$1" in
      --) shift 1; task_opts="$@"; break;;
       *) wrapper_opts="$wrapper_opts $1"; shift 1
    esac
  done
  qeval gw $wrapper_opts $task_opts
}
# gw-task() {
#   local USAGE='Usage: gw-task [-w wrapper_option... --] task [args...]'
#   local wrapper_opts=
#   [[ "$1" == "-w" ]] && wrapper_opts="$2" && shift 2
#   qeval gw $wrapper_opts $@
# }

#
### PS1 COMMAND LINE PROMPT
#
# - if unset, leave unset (non-interactive shell)
# - if last command was in error, display "!" prefix before "$" and before line sep
# - history -a explicitly flushes the session history to the history file
# __git_ps1 shows the current git branch, if any, and is configured below
# - \u = user, \h = hostname, \w = working dir
#
# .setup-ps1() {
#   .tick-bash-profile "[start] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"  #  PS1=[\h:\W \u\[\]\$\[\] ]
#   [[ -z "$PS1" ]] && .tick-bash-profile '[end] .setup-ps1: non-interactive shell' && return 0

#   export PROMPT_COMMAND='.ps1-set-last-command-state;_prompt_command'

#   # Hijack git prompt's saved status from prior command
#   .ps1-set-last-command-state() {
#     export GIT_PROMPT_LAST_COMMAND_STATE=$?
#   }

#   _prompt_command() {
#     # .tick-bash-profile "[start] _prompt_command: on entry, PROMPT_COMMAND=[$PROMPT_COMMAND], \$\?=$GIT_PROMPT_LAST_COMMAND_STATE, PS1=[$PS1]"

#     history -a 

#     local ps1_suffix='$'; ((GIT_PROMPT_LAST_COMMAND_STATE>0)) && ps1_suffix='!$'

#     # if type -t kube_ps1 &>/dev/null && [[ "$KUBE_PS1_ENABLED" = on ]]; then
#     #   _kube_ps1_update_cache
#     #   local k_ps1_text="$(kube_ps1)"
#     #   local len_k_ps1_text=${#k_ps1_text}
#     #   ((len_k_ps1_text>0)) && k_ps1_text="$k_ps1_text\\n"
#     #   # .tick-bash-profile "... k_ps1_text=[$k_ps1_text], len(k_ps1_text)=[$len_k_ps1_text]"
#     # fi

#     local g_ps1_text=
#     if type -t setGitPrompt &>/dev/null; then
#       export GIT_PROMPT_START=
#       export GIT_PROMPT_END=
#       export GIT_PROMPT_LEADING_SPACE=0
#       setGitPrompt
#       g_ps1_text="$PS1"
#     fi
#     g_ps1_text="$g_ps1_text\\n${LAST_COMMAND_INDICATOR}${ResetColor} $(tilde-compress \\w) $ps1_suffix "
#     # .tick-bash-profile "... g_ps1_text=[$g_ps1_text]"

#     export PS1="$(printf '%s%s' "${k_ps1_text}" "${g_ps1_text}")"

#     # .tick-bash-profile "[end] _prompt_command: on exit, PS1=[$PS1]"
#   }

#   .tick-bash-profile "[end] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"
# }
# .setup-ps1


.source-extra-bash-profiles() {
  .tick-bash-profile '[start] .source-extra-bash-profiles'
  if glob-path-exists ~/.bash_profile.*; then
    for f in ~/.bash_profile.*; do
      .tick-bash-profile "... sourcing $f"
      . $f
    done
  fi
  .tick-bash-profile '[end] .source-extra-bash-profiles'
}
.source-extra-bash-profiles


alias .reload-shell='qeval exec $SHELL -l'
alias .reload-bash-profile='qeval . ~/.bash_profile' .rbp='.reload-bash-profile'
alias .rlbp='qeval .reload-bash-profile'

#? # Make sure prompt show success first time thru
#? ((1)) && eval "$PROMPT_COMMAND"

.tick-bash-profile "[END-FILE] (\$\$=[$$], \$PATH=[$PATH], \$PS1=[$PS1])"

