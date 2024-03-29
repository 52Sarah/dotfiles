#!/usr/bin/env bash

# For interactive/login shells, Bash reads, in order:
#   - ~/.bash_profile || ~/.bash_login || ~/.profile
#   - once it finds one it stops looking
# For non-interactive shells, Bash reads the $BASH_ENV file (usually ~/.bashrc).
# For any shells invoked as 'sh', Bash reads the $ENV file (usually ~/.profile).

# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1


#? # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
#? type -t .tick >&/dev/null || . ~/.tick
#? .tick-bash-profile() { .tick -s ".bash_profile" "$@"; }
#? .tick_bp() { .tick-bash-profile "$@"; }
#? export _TICK_STDERR= _TICK_STDOUT= TICK_INDENT= TICK_LAST_MS=
#? export SH_LOGIN_PYENV_REASH=0

# If debugging is not enabled, overwrite .tick-bp with a no-op.
if [[ -e ~/.tick.enabled ]]; then
  tick-bp() { 
    [[ "$1" != '-e' && echo "[.bash_profile] " "$@" && return 1;
    shift; eval "$@"; return 1
  }
else
  .tick-bp() { :; }
fi
# . $HOME/.__login.debug ".bash_profile" --reset-datetime || __echo() { :; }
# .tick-bash-profile-user -e 'printf "[START-FILE ] ~/.bash_profile.toddpierzina \$\$=$$ \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$- fns=%d\n" $(declare -F | wc -l)'
__echo "[.bash_profile] starting:  pid: $$, ppid: $PPID, -='$-', SHLVL=$SHLVL, PS1=[$PS1]"


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

### 'less' helpers:
# 
alias l='less'
#
# Lines will NOT wrap, but CTRL-C), arrow keys can scroll
# left and write. Press 'F' to resume "tailing".
alias tfl='less --chop-long-lines +F'

### terminal/iterm wrap/unwrap
alias term.trunc='tput rmam'
alias term.wrap='tput smam'

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
alias hg='history-grep'

### cd helpers
#
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

#
### chmod helpers
#
# Make specified, or all in PWD, shell scripts executable.
chx() {
  local opt_verbose=$((_ECHO_V))
  [[ "$1" =~ ^(-v|--verbose)$ ]] && shift && opt_verbose=1
  
  local files=($@)
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

# Updated mtime of folders with latest mtime of its contents.
touchd() {
  [[ -z "$1" ]] && eecho "usage: touchd dir [...]" && return 1
  local _ECHO_V="$((_ECHO_V))"
  local count=0 arg
  for arg in $@; do
      [[ "$arg" =~ ^(-v|--verbose)$ ]] && _ECHO_V=1 && continue
      
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
  local dirs=($@)
  [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
  for dir in "${dirs[@]}"; do
      [[ "$dir" =~ ^(-v|--verbose)$ ]] && [[ -n "$_ECHO_V" ]] && continue
      find "$dir" -depth ! -type f -print |\
      while read -r subdir; do
          touchd "$subdir"
      done
      touchd "$dir"
  done
}

# Record lengths along with count of each length, in the same sequence as file.
record-lengths() {
  [[ -z "$1" ]] && >&2 echo "usage: record-lengths file [...]" && return 1
  local files=$@
  for f in $files; do
    printf "%s\n  %s\n" "$f" "$(awk '{print length($0)}' "$f" | sort -n | uniq -c)"
  done
}
recl(){ record-lengths $@; }

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
fwf(){ fwf-nice $@; }

#?  #
#?  ### BASH COMPLETION
#?  # Load completions other than the ones handled explicitly above.
#?  safe-source /usr/local/etc/bash_completion.d/brew && .tick_bp 'loaded brew completion' || .tick_bp '!! failed to load brew completion'


# # Used by profile badge to show pwd (lowercase) via user.tildePath variable.
# # From: https://iterm2.com/documentation-scripting-fundamentals.html
#
# Disabled since it doesn't play so well w git-prompt.
#
# iterm2_print_vars() {
#   iterm2_set_var 'tildePath' "$(tilde-compress "$PWD" | lower)"
# }

.bash_profile_sets() {
  # .tick_bp -e 'printf "[start ] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'

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

  # .tick_bp -e 'printf "[finish] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'
}
.bash_profile_sets

.bash_profile_shopts() {
  # .tick_bp -e 'printf "[start ] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
  
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

  # .tick_bp -e 'printf "[finish] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
}
.bash_profile_shopts



#
###  GIT
#
.setup-git() {
  .tick_bp '[start ] .setup-git'
  ! type -t git &>/dev/null && .tick_bp "[finish] .setup-git: git not installed" && return 0

  .tick_bp "... using $(git --version)"

  .tick_bp "... checking for ~/.git-completion"
  safe-source -q ~/.git-completion
  complete -p | grep -E -q 'git$' && .tick_bp "... loaded git cli completion" || .tick_bp "... not using git completion"

  .tick_bp '... checking for git-flow'
  if type -t git-flow &>/dev/null; then
    # https://github.com/aleksandr-m/gitflow-maven-plugin

    .tick_bp "... checking for ~/.git-flow-completion"
    safe-source -q ~/.git-flow-completion
    complete -p | grep -E -q 'git-flow$' && .tick_bp "... loaded git-flow cli completion" || .tick_bp "... not using git-flow completion"

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

  # cd into each given directory and perform a git pull --ff-only
  # usage: g-pullr [dir ...]
  g-pullf() {
    local dirs="$@"
    [[ -z "$dirs" ]] && dirs="$(find . -maxdepth 1 -type d)"

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

  # update local mtime based on git log
  # from: https://stackoverflow.com/a/2038768/160955
  g-touch() {
    [[ -z "$1" ]] && eecho "usage: g-touch file [...]" && return 1
    while [[ -n "$1" ]]; do
      local f="$1"; shift
      local rev="$(git rev-list -n 1 "HEAD" "$f")"
      local commit_sec="$(git show --pretty=format:%at --abbrev-commit "$rev" | head -n 1)"
      local commit_ts="$(date -r $commit_sec '+%Y%m%d%H%M.%S')"
      # IFS=`printf '\t\n\t'`
      ((!_ECHO_UNLESS_Q)) && printf 'before: ' && ls -oghF "$f" | tilde-compress
      eval-quiet touch -h -t "$commit_ts" "$f"
      ((!_ECHO_UNLESS_Q)) && printf 'after:  ' && ls -oghF "$f" | tilde-compress
    done      
  }

  .setup-git-prompt() {
    .tick_bp "[start ] .setup-git-prompt, PROMPT_COMMAND=[$PROMPT_COMMAND]"

    export __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
    local gitprompt_sh="$__GIT_PROMPT_DIR/gitprompt.sh"
    [[ ! -e "$gitprompt_sh" ]] && .tick_bp "[finish] .setup-git-prompt: $gitprompt_sh: No such file" && return 0

    # results in prefixing setLastCommandState; to PROMPT_COMMAND, which sets GIT_PROMPT_LAST_COMMAND_STATE=$?
    # and calls setGitPrompt which calls updatePrompt to override any prior PS1
    .tick_bp "... loading $gitprompt_sh"
    export GIT_PROMPT_ONLY_IN_REPO=
    export GIT_PROMPT_SHOW_UPSTREAM=1
    export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
    export GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=1
    export GIT_PROMPT_THEME='Custom'
    . "$gitprompt_sh" 
    
    .tick_bp "[finish] .setup-git-prompt"
  }
  .setup-git-prompt 

  .tick_bp '[finish] .setup-git'
}
.setup-git


#
### JAVA/JENV
#
.setup-java-jenv() {
  .tick_bp '[start ] .setup-java-jenv'
  ! type -t jenv &>/dev/null && .tick_bp "[finish] jenv not installed" && return 0

  if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
    .tick_bp 'jenv already initialized'
  else
    .tick_bp '... initializing jenv'
    eval "$(jenv init --no-rehash -)"
    path-prepend "$HOME/.jenv/bin"
    .tick_bp "... initialized jenv"
  fi
  # .tick_bp -e 'echo "... using $(jenv --version)"'
  # .tick_bp -e 'echo "... using java $(jenv version)"'
  # .tick_bp -e 'echo "... $ which javac: $(2>&1 which javac)"'
  # .tick_bp -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
  
  local javahome="$(jenv javahome)"
  if [[ -z "$javahome" ]]; then
    .tick_bp "jenv reports a blank JAVA_HOME"
  elif [[ ! -d "$javahome" ]]; then
    .tick_bp "jenv reports a non-directory JAVA_HOME: $javahome"
  elif [[ ! -d "$javahome/bin" ]]; then
    .tick_bp "jenv non-directory JAVA_HOME/bin: $javahome/bin"
  else
    export JAVA_HOME="$javahome"
  fi

  .tick_bp -e tilde-compress "[finish] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME]"
}
.setup-java-jenv


#
### PS1 COMMAND LINE PROMPT
#
# - if unset, leave unset (non-interactive shell)
# - if last command was in error, display "!" prefix before "$" and before line sep
# - history -a explicitly flushes the session history to the history file
# __git_ps1 shows the current git branch, if any, and is configured below
# - \u = user, \h = hostname, \w = working dir
#
.setup-ps1() {
  .tick_bp "[start ] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"  #  PS1=[\h:\W \u\[\]\$\[\] ]
  [[ -z "$PS1" ]] && .tick_bp '[finish] .setup-ps1: non-interactive shell' && return 0

  export PROMPT_COMMAND='.ps1-set-last-command-state;_prompt_command'

  # Hijack git prompt's saved status from prior command
  .ps1-set-last-command-state() {
    export GIT_PROMPT_LAST_COMMAND_STATE=$?
  }

  _prompt_command() {
    # .tick_bp "[start ] _prompt_command: on entry, PROMPT_COMMAND=[$PROMPT_COMMAND], \$\?=$GIT_PROMPT_LAST_COMMAND_STATE, PS1=[$PS1]"

    history -a 

    local ps1_suffix='$'; ((GIT_PROMPT_LAST_COMMAND_STATE>0)) && ps1_suffix='!$'

    # if type -t kube_ps1 &>/dev/null && [[ "$KUBE_PS1_ENABLED" = on ]]; then
    #   _kube_ps1_update_cache
    #   local k_ps1_text="$(kube_ps1)"
    #   local len_k_ps1_text=${#k_ps1_text}
    #   ((len_k_ps1_text>0)) && k_ps1_text="$k_ps1_text\\n"
    #   # .tick_bp "... k_ps1_text=[$k_ps1_text], len(k_ps1_text)=[$len_k_ps1_text]"
    # fi

    local g_ps1_text=
    if type -t setGitPrompt &>/dev/null; then
      export GIT_PROMPT_START=
      export GIT_PROMPT_END=
      export GIT_PROMPT_LEADING_SPACE=0
      setGitPrompt
      g_ps1_text="$PS1"
    fi
    g_ps1_text="$g_ps1_text\\n${LAST_COMMAND_INDICATOR}${ResetColor} $(tilde-compress \\w) $ps1_suffix "
    # .tick_bp "... g_ps1_text=[$g_ps1_text]"

    export PS1="$(printf '%s%s' "${k_ps1_text}" "${g_ps1_text}")"

    # .tick_bp "[finish] _prompt_command: on exit, PS1=[$PS1]"
  }

  .tick_bp "[finish] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"
}
.setup-ps1


alias .reload-shell='qeval exec $SHELL -l'
alias .reload-bash-profile='qeval . ~/.bash_profile'

# Make sure prompt show success first time thru
((1)) && eval "$PROMPT_COMMAND"

.tick-bp -e 'printf "[FINISH-FILE] ~/.bash_profile \$\$=$$ \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$- fns=%d\n" $(declare -F | wc -l)'
