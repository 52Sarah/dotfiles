#!/usr/bin/env bash

# For interactive/login shells, Bash reads, in order:
#   - ~/.bash_profile || ~/.bash_login || ~/.profile
#   - once it finds one it stops looking
# For non-interactive shells, Bash reads the $BASH_ENV file (usually ~/.bashrc).
#
# For any shells invoked as 'sh', Bash reads the $ENV file (usually ~/.profile).

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
type -t .tick >&/dev/null || . ~/.tick.sh
.tick-bash-profile-user() { .tick -s ".bash_profile.$USER" "$@"; }
.tick_bpu() { .tick-bash-profile-user "$@"; }
export TICK_STDERR= TICK_STDOUT= TICK_INDENT= TICK_LAST_MS=
export SH_LOGIN_PYENV_REASH=0

.tick-bash-profile-user -e 'printf "[START-FILE ] ~/.bash_profile.toddpierzina \$\$=$$ \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$- fns=%d\n" $(declare -F | wc -l)'

.bash_profile_user_wrapper() {

  # Don't show the 'zsh is the default shell' message.
  export BASH_SILENCE_DEPRECATION_WARNING=1

  if [[ -e ${BASH_ENV:=~/.bashrc} ]]; then
    .tick_bpu "sourcing $BASH_ENV"
    . "$BASH_ENV"
  fi
  export BASH_ENV
  export ENV=~/.profile


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
    local opt_verbose=$((SH_VERBOSE))
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
    local SH_VERBOSE="$((SH_VERBOSE))"
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
        [[ "$dir" =~ ^(-v|--verbose)$ ]] && [[ -n "$SH_VERBOSE" ]] && continue
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

  #
  ### BASH COMPLETION
  # Load completions other than the ones handled explicitly above.
  safe-source /usr/local/etc/bash_completion.d/brew && .tick_bpu 'loaded brew completion' || .tick_bpu '!! failed to load brew completion'


  # # Used by profile badge to show pwd (lowercase) via user.tildePath variable.
  # # From: https://iterm2.com/documentation-scripting-fundamentals.html
  #
  # Disabled since it doesn't play so well w git-prompt.
  #
  # iterm2_print_user_vars() {
  #   iterm2_set_user_var 'tildePath' "$(tilde-compress "$PWD" | lower)"
  # }

  .bash_profile_sets() {
    # .tick_bpu -e 'printf "[start ] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'

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

    # .tick_bpu -e 'printf "[finish] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'
  }
  .bash_profile_sets

  .bash_profile_shopts() {
    # .tick_bpu -e 'printf "[start ] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
    
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

    # .tick_bpu -e 'printf "[finish] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
  }
  .bash_profile_shopts


  #
  ### DOCKER
  #
  .setup-docker() {
    .tick_bpu '[start ] .setup-docker'
    ! type -t docker >&/dev/null && .tick_bpu "[finish] .setup-docker: docker not installed" && return 0
    alias d='docker'
    d-lsc() { qeval docker container ls --all --format "'table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}\t{{.Networks}}\\t{{.Ports}}'" $@; }
    d-lsi() { qeval docker image ls --all --format "'table {{.ID}}\\t{{.Image}}\\t{{.CreatedAt}}\\t{{.Size}}\\t{{.Networks}}\\t{{.Ports}}'" $@; }
  }
  .setup-docker


  #
  ###  GIT
  #
  .setup-git() {
    .tick_bpu '[start ] .setup-git'
    ! type -t git &>/dev/null && .tick_bpu "[finish] .setup-git: git not installed" && return 0

    .tick_bpu "... using $(git --version)"

    .tick_bpu "... checking for ~/.git-completion"
    safe-source -q ~/.git-completion
    complete -p | grep -E -q 'git$' && .tick_bpu "... loaded git cli completion" || .tick_bpu "... not using git completion"

    .tick_bpu '... checking for git-flow'
    if type -t git-flow &>/dev/null; then
      # https://github.com/aleksandr-m/gitflow-maven-plugin

      .tick_bpu "... checking for ~/.git-flow-completion"
      safe-source -q ~/.git-flow-completion
      complete -p | grep -E -q 'git-flow$' && .tick_bpu "... loaded git-flow cli completion" || .tick_bpu "... not using git-flow completion"

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
        ((!SH_QUIET)) && printf 'before: ' && ls -oghF "$f" | tilde-compress
        eval-quiet touch -h -t "$commit_ts" "$f"
        ((!SH_QUIET)) && printf 'after:  ' && ls -oghF "$f" | tilde-compress
      done      
    }

    .setup-git-prompt() {
      .tick_bpu "[start ] .setup-git-prompt, PROMPT_COMMAND=[$PROMPT_COMMAND]"

      export __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
      local gitprompt_sh="$__GIT_PROMPT_DIR/gitprompt.sh"
      [[ ! -e "$gitprompt_sh" ]] && .tick_bpu "[finish] .setup-git-prompt: $gitprompt_sh: No such file" && return 0

      # results in prefixing setLastCommandState; to PROMPT_COMMAND, which sets GIT_PROMPT_LAST_COMMAND_STATE=$?
      # and calls setGitPrompt which calls updatePrompt to override any prior PS1
      .tick_bpu "... loading $gitprompt_sh"
      export GIT_PROMPT_ONLY_IN_REPO=
      export GIT_PROMPT_SHOW_UPSTREAM=1
      export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
      export GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=1
      export GIT_PROMPT_THEME='Custom'
      . "$gitprompt_sh" 
      
      .tick_bpu "[finish] .setup-git-prompt"
    }
    .setup-git-prompt 

    .tick_bpu '[finish] .setup-git'
  }
  .setup-git


  #
  ### JAVA/JENV
  #
  .setup-java-jenv() {
    .tick_bpu '[start ] .setup-java-jenv'
    ! type -t jenv &>/dev/null && .tick_bpu "[finish] jenv not installed" && return 0

    if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
      .tick_bpu 'jenv already initialized'
    else
      .tick_bpu '... initializing jenv'
      eval "$(jenv init --no-rehash -)"
      path-prepend "$HOME/.jenv/bin"
      .tick_bpu "... initialized jenv"
    fi
    # .tick_bpu -e 'echo "... using $(jenv --version)"'
    # .tick_bpu -e 'echo "... using java $(jenv version)"'
    # .tick_bpu -e 'echo "... $ which javac: $(2>&1 which javac)"'
    # .tick_bpu -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
    
    local javahome="$(jenv javahome)"
    if [[ -z "$javahome" ]]; then
      .tick_bpu "jenv reports a blank JAVA_HOME"
    elif [[ ! -d "$javahome" ]]; then
      .tick_bpu "jenv reports a non-directory JAVA_HOME: $javahome"
    elif [[ ! -d "$javahome/bin" ]]; then
      .tick_bpu "jenv non-directory JAVA_HOME/bin: $javahome/bin"
    else
      export JAVA_HOME="$javahome"
    fi

    .tick_bpu -e tilde-compress "[finish] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME]"
  }
  .setup-java-jenv


  #
  ### PYENV
  #
  .setup-pyenv() {
    .tick_bpu '[start ] .setup-pyenv'
    ! type -t pyenv &>/dev/null && .tick_bpu "[finish] .setup-pyenv: pyenv not installed" && return 0
    [[ -n "$PYENV_ROOT" && "$(type -t pyenv &>/dev/null)" == "function" ]] && .tick_bpu "[finish] .setup-pyenv: pyenv already initialized" && return 0

    export PYENV_ROOT="$HOME/.pyenv"
    path-prepend "$PYENV_ROOT/bin"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    # .tick_bpu -e 'echo "... using $(2>&1 pyenv -v)"'
    # .tick_bpu -e 'echo "... using python version $(2>&1 pyenv version)"'
    # .tick_bpu -e 'echo "... $ which python: $(2>&1 which python)"'
    # .tick_bpu -e 'echo "... $ python -V: $(2>&1 python -V)"'

    # manually rehash from install location; -v for extra output
    pyenv-rehash-ln() {
      local opt_verbose=; [[ "$1" =~ -v ]] && opt_verbose='v' && shift
      ((SH_VERBOSE)) && opt_verbose='v'

      local py_bin="$(brew --prefix)/Cellar/python@3.9/$(pyenv version-name)/bin"
      local py_shims="$PYENV_ROOT/shims"
      local dot_py_shims="$HOME/dotfiles/pyenv_shims"
      mkdir -p$opt_verbose "$py_shims"
      for f in "$py_bin"/*; do veval ln -sf$opt_verbose "$f" "$py_shims"; done
      for f in "$dot_py_shims"/*; do
        local shim="$(sed -E 's/^pyenv_|_[^_]+_shiv\.sh$//g' <<< "$(basename $f)")"
        cp -p$opt_verbose "$f" "$py_shims/$shim"
      done
      if [[ -n "$opt_verbose" ]]; then
        eeval ll $py_shims/
        echo 'python3 ...'; which python3; python3 -V
        echo 'python ...'; which python; python -V
        echo 'pip ...'; which pip; pip -V
      fi
    }
    ((SH_LOGIN_PYENV_REASH)) && .tick_bpu '... calling pyenv-rehash-ln'
    pyenv-rehash-ln
    # .tick_bpu -e 'echo "... $ which python: $(2>&1 which python)"'
    # .tick_bpu -e 'echo "... $ python -V: $(2>&1 python -V)"'

    .tick_bpu '[finish] .setup-pyenv'
  }
  .setup-pyenv

  #
  ### PYTHON
  #
  .setup-python-pip() {
    .tick_bpu '[start ] .setup-python-pip'
    ! type -t python &>/dev/null && .tick_bpu '[finish] .setup-python-pip: python not installed' && return 0

    # .tick_bpu -e 'echo "... using pip version $(2>&1 pip --version)"'

    export VIRTUALENVWRAPPER_PYTHON="$(which python)"
    export VIRTUALENVWRAPPER_HOOK_DIR="$HOME/.virtualenvs"

    # ! eval "$(python -m pip completion --bash)" && .tick_bpu '[finish] !!! .setup-python-pip: failed to load pip completion' && return 1
    # complete -p | grep -E -q 'pip$' && .tick_bpu "... loaded pip cli completion" || .tick_bpu "!!! pip cli completion not loaded"

    .tick_bpu '[finish] .setup-python-pip'
  }
  .setup-python-pip

  #
  ### KUBECTL
  #
  .setup-kubectl() {
    .tick_bpu '[start ] .setup-kubectl'
    ! type -t kubectl &>/dev/null && .tick_bpu '[finish] .setup-kubectl: k8s/kubectl not installed' && return 0

    .tick_bpu '... loading kubectl bash completion'
    if ! eval "$(kubectl completion bash)"; then
      .tick_bpu '!!! failed to load kubectl completion'
    elif complete -p | grep -E -q 'kubectl$'; then
      .tick_bpu "... loaded kubectl bash completion"
    else
      .tick_bpu "... not using kubectl completion"
    fi

    # list all kubectl aliases and functions
    k?() {
      alias \
        | grep -E "^alias k.*='k" \
        | sed -E "s/^alias //; s/='/=/; s/'$//" \
        | awk -F= '{printf("%-6s \t%s\n", $1, $2);}'
      declare -F \
        | sed -E 's/^declare -f //;' \
        | grep -E '^k-'
      declare -F \
        | egrep '^k\-'
    }
    
    k-less()      { qeval kubectl -n "$(kubens --current)" "$@" | less; }
    
    k-help()      { k-less "$@" --help; }
    k-config()    { k-less config "$@"; }
    k-get()       { k-less get "$@"; }
    k-describe()  { k-less describe "$@"; }
    k-explain()   { k-less explain "$@"; }
    k-logs()      { k-less logs "$@"; }
    alias k='k-less' kh='k-help' kc='k-config' kg='k-get' kd='k-describe' ke='k-explain' kl='k-logs'
    
    # get $1 resources (pods/deployments/etc.) for $2 app
    k-get-resource-for-app() {
      local res= app=
      while [[ -n "$1" ]]; do
        [[ "$1" = "-r" ]] && res="$2" && shift 2
        [[ "$1" = "-a" ]] && app="$2" && shift 2
      done
      [[ -z "$res" && -z "$app" ]] && eecho 'usage: k-get-resource-for-app -r res -a app [kubectl_opts ...]' && return 1
      eeval k-get $res -l "app=$app" -L 'alt-name,app,version' "$@"
    }
    alias kg-res-app='k-get-resource-for-app'

    kg-ns() { qeval k-get namespaces "$@"; }

    kg-pods() { qeval k-get pods -L alt-name,app,version "$@"; }
    alias kgp='kg-pods'

    # get pods for app $1      
    kg-pods-app() {
      [[ -z "$1" ]] && eecho 'usage: kg-pods-app app [kubectl_opts ...]' && return 1
      qeval k-getres--app -r pods -a "$1"
    }
    kgp-app() { k-getpods--app "$@"; }
    
    kg-pods-grep() {
      [[ -z "$1" ]] && echo-stderr 'usage: kg-pods-grep pattern [...]' && return 1
      local patterns=
      while [[ -n "$1" ]]; do patterns="$patterns|$1"; shift; done
      qeval "kg-pods | egrep '^NAME $patterns' | egrep -v 'Completed'"
    }
    alias kgp-grep='kg-pods-grep'

    
    # delete all pods for app $1      
    k-deletepods--app() {
      [[ -z "$1" ]] && eecho 'usage: k-deletepods--app app [kubectl_opts ...]' && return 1
      local app="$1" && shift
      eeval kubectl delete pods -l "app=$app" "$@"
    }
    
    k-logs--app() {
      [[ -z "$1" ]] && eecho "usage: k-logs--app app [kubectl_opts ...]" && return 1
      local app="$1" && shift
      local now="$(date +'%Y%m%d_%H%M%S')"
      local ns="$(kubens --current)"
      eeval "kubectl logs -l app=$app --tail -1 $@" \
        "| grep -E '^\{'" \
        "| tee $ns-$app.$now.FULL.log.json" \
        "| jq '{timestamp, logger, thread, level, message}'" \
        " > $ns-$app.$now.log.json"
      ls -pghF "$ns-$app.${now:0:8}_"*
    }

    .setup-kube-prompt() {
      .tick_bpu "[start ] .setup-kube-prompt"
      if [[ ! -e "${kube_ps1_sh:=/usr/local/opt/kube-ps1/share/kube-ps1.sh}" ]]; then
        .tick_bpu "[finish] .setup-kube-prompt: $kube_ps1_sh: File not found" && return 0
      else
        . "$kube_ps1_sh" || .tick_bpu "!!! failed to source $kube_ps1_sh"
      fi
      .tick_bpu "[finish] .setup-kube-prompt"
    }
    .setup-kube-prompt

    .tick_bpu '[finish] .setup-kubectl'
  }
  .setup-kubectl


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
    .tick_bpu "[start ] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"  #  PS1=[\h:\W \u\[\]\$\[\] ]
    [[ -z "$PS1" ]] && .tick_bpu '[finish] .setup-ps1: non-interactive shell' && return 0

    export PROMPT_COMMAND='.ps1-set-last-command-state;_prompt_command'

    # Hijack git prompt's saved status from prior command
    .ps1-set-last-command-state() {
      export GIT_PROMPT_LAST_COMMAND_STATE=$?
    }

    _prompt_command() {
      # .tick_bpu "[start ] _prompt_command: on entry, PROMPT_COMMAND=[$PROMPT_COMMAND], \$\?=$GIT_PROMPT_LAST_COMMAND_STATE, PS1=[$PS1]"

      history -a 

      local ps1_suffix='$'; ((GIT_PROMPT_LAST_COMMAND_STATE>0)) && ps1_suffix='!$'

      if type -t kube_ps1 &>/dev/null && [[ "$KUBE_PS1_ENABLED" = on ]]; then
        _kube_ps1_update_cache
        local k_ps1_text="$(kube_ps1)"
        local len_k_ps1_text=${#k_ps1_text}
        ((len_k_ps1_text>0)) && k_ps1_text="$k_ps1_text\\n"
        # .tick_bpu "... k_ps1_text=[$k_ps1_text], len(k_ps1_text)=[$len_k_ps1_text]"
      fi

      local g_ps1_text=
      if type -t setGitPrompt &>/dev/null; then
        export GIT_PROMPT_START=
        export GIT_PROMPT_END=
        export GIT_PROMPT_LEADING_SPACE=0
        setGitPrompt
        g_ps1_text="$PS1"
      fi
      g_ps1_text="$g_ps1_text\\n${LAST_COMMAND_INDICATOR}${ResetColor} $(tilde-compress \\w) $ps1_suffix "
      # .tick_bpu "... g_ps1_text=[$g_ps1_text]"

      export PS1="$(printf '%s%s' "${k_ps1_text}" "${g_ps1_text}")"

      # .tick_bpu "[finish] _prompt_command: on exit, PS1=[$PS1]"
    }

    .tick_bpu "[finish] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"
  }
  .setup-ps1


  #
  ### CH-Specific
  #
  .setup-ch_specific() {
    .tick_bpu '[start ] .setup-ch_specific'

    export CCHH_HOME="$HOME/cchh"

    export CCHH_AUG_HOME="$HOME/cchh-extra/canal-aqueduct-tools/aug"
    export CCHH_AUG_VENV="$VIRTUALENVWRAPPER_HOOK_DIR/aug"
    aug() { [[ "$VIRTUAL_ENV" != "$CCHH_AUG_VENV" ]] && . "$CCHH_AUG_VENV/bin/activate"; command aug "$@"; }

    export CH_TICKETS="$HOME/ch-tickets"
    mk-ch-ticket() {
      [[ -z "$2" ]] && eecho "usage: mk-ch-ticket JIRA-ID 'title'" && return 1
      local jira_id="$(upper $1)"; shift
      local title="${1// /-}"; shift
      local ticket_name="$jira_id-$title"
      local ticket_dir="$CH_TICKETS/$ticket_name"
      local notes_file="$ticket_dir/$ticket_name.md"
      [[ -e "$notes_file" ]] && return 0
      [[ ! -e "$ticket_dir" ]] && mkdir -v "$ticket_dir"
      printf '# %s %s\n\n' "$jira_id" "$title" > "$notes_file"
    }

    alias cd-CI-715='cd $CH_TICKETS/CI-715-hcsc-med-accum-add-synthetics'
    alias cd-CH-62846='cd $CH_TICKETS/CH-62846-hcsc-add-rx'

    vault-token-refresh() {
      vault login -method=ldap -no-print username=todd.pierzina password=$SECRET_OKTA_CRED && echo Vault token refreshed.
    }

    # Convert logsearch/kibana's json response to streamlined tab-separated-values file.
    jq-logsearch-to-tsv() {
      # local json_file="$1"; shift
      # [[ -z "$json_file" ]] && eecho "usage: jq-logsearch-to-tsv json_file" && return 1
      # [[ -e "$json_file" ]] && eecho "jq-logsearch-to-tsv: $json_file: No such file" && return 1
      printf 'timestamp\tnamespace\tlevel\tthread\tmessage\tsort\n'
      jq -j '.hits[]|._source.timestamp,"\t",._source.namespace,"\t",._source.level,"\t",._source.thread,"\t",._source.message,"\t",.sort[0],"\n"'
    }
    
    fwf-hcsc-med-accum() {
      local delim="\t"
      if [[ "$1" =~ -d|--delim ]]; then
        delim="$2"
        shift 2
      fi
      vecho "fwf-nice -d "$delim" $@"
      fwf-nice -d "$delim" $@ \
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

    ssh-airflow-test1() {
      eval-echo ssh_uswest2 172.31.19.25
    }
    
    ssh-is-prod() { eeval ssh_uswest2 intersystems.prod.cchh.local; }
    ssh-is-preprod() { eeval ssh_uswest2 intersystems.preprod.cchh.local; }
    ssh-is-pit() { eeval kubectl -n claims-pit exec -it -c intersystems intersystems-claims-pit-0 bash; }
    
    scp-from() {
      [[ -z "$2" ]] && eecho "usage: scp-from remote_host remote_file_spec [local_path] [scp_switches ...]" && return 1
      local remote_host="$1" && shift
      local remote_file="$1" && shift
      local local_path="${1:-.}" && shift
      local scp_switches="$@"
      eeval scp_uswest2 -p -r $scp_switches "$remote_host:$remote_file" "$local_path"
    }
    scp-from--is-preprod() {
      [[ -z "$1" ]] && eecho "usage: scp-from--is-preprod remote_file_spec [local_path] [scp_switches ...]" && return 1
      eeval scp-from intersystems.preprod.cchh.local $@
    }
    scp-from--ibmmq-prod() {
      [[ -z "$1" ]] && eecho "usage: scp-from--ibmmq-prod remote_file_spec [local_path] [scp_switches ...]" && return 1
      eeval scp-from root@192.168.1.1 $@
    }

    scp-to() {
      [[ -z "$2" ]] && eecho "usage: scp-to remote_host [local_file_spec ...] [remote_path] [scp_switches ...]" && return 1
      local remote_host="$1" && shift
      local local_file="$1" && shift
      local remote_path="${1:-.}" && shift
      local scp_switches="$@"
      eeval scp_uswest2 -p -r $scp_switches "$local_file" "$remote_host:$remote_path"
    }
    scp-to--is-preprod() {
      [[ -z "$1" ]] && eecho "usage: scp-to--is-preprod local_file_spec [remote_path] [scp_switches ...]" && return 1
      eeval scp-to intersystems.preprod.cchh.local $@
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

  #   ssh-ibmmq() {
  #     cat <<-EOF

  # IBM MQ Runbook: https://github.com/collectivehealth/runbooks/tree/master/ibm-mq#connecting

  # $ sudo su - mqm

  # $ runmqsc PCCHH01  # no prompt will appear

  # dis ql(*) all   # or qlocal
  # dis chs(*) where (STATUS eq RUNNING)
  # dis chs(*) where (STATUS ne RUNNING)
  # dis chs(*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME
  # dis chs(INTERSYSTEMS.*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME
  # dis chs(CANAL.*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME

  # dis qstatus(*) where (CURDEPTH gt 100)
  # dis qstatus(*) where (CURDEPTH gt 0)

  # dis chs(CCHH.ESI.CDH)
  # dis qstatus(CCHH.ESI.CDH.TQ)
  # stop channel(CCHH.ESI.CDH)
  # start channel(CCHH.ESI.CDH)

  # dis chs(PCCHH01.TO.CVS.ZQM1)
  # dis qstatus(CCHH.CVS.TQ)
  # stop channel(PCCHH01.TO.CVS.ZQM1)
  # start channel(PCCHH01.TO.CVS.ZQM1)

  # dis chs(CVS.ZQM1.TO.PCCHH01)
  # stop channel(CVS.ZQM1.TO.PCCHH01)
  # dis chs(CVS.ZQM1.TO.PCCHH01)
  # start channel(CVS.ZQM1.TO.PCCHH01)

  # dis chs(ESI.CDH.CCHH)
  # stop channel(ESI.CDH.CCHH)
  # dis chs(ESI.CDH.CCHH)
  # start channel(ESI.CDH.CCHH)

  # # bounce mq
  # $ endmqm PCCHH01
  # $ strmqm PCCHH01

  # EOF
  #     # cchh arrow ssh root@ibm_mq_uswest2_01
  #     eeval ssh_uswest2 root@192.168.1.1
  #   }


    #
    ### Define helper functions/aliases for kubectl
    #
    .setup-ch_k8s_helpers() {
      .tick_bpu '[start ] .setup-ch_k8s_helpers'
      
      k-logs--canal-sftp-out-rx-optum-accum() {
        eeval k-logs--app "canal-sftp-out-rx-optum-accum" "$@"
      }
      k-logs--aq-status2() {
        eeval k-logs--ns-app "aq-status" "$@"
        eeval k-logs--ns-app "aq-status-rest" "$@"
      }
      k-logs--is-deploy() {
        eeval kubectl "$@" exec "intersystems-$(kubens --current)-0" -- tail -n 20 /data/deploy_logs/intersystems.log
      }
      
      k-pf--aq-status-rest() {
        local k_service='aq-status-rest'
        local k_port='8103'
        eeval kubectl port-forward services/$k_service $k_port:$k_port
      }
      k-pf--claim-api() {
        local k_service='ingenuity-claim-api'
        local k_port='8087'
        eeval kubectl port-forward services/$k_service $k_port:$k_port
      }
      k-pf--rabbitmq() {
        eeval kubectl port-forward service/rabbitmq 15672:15672
      }

      .tick_bpu '[finish] .setup-ch_k8s_helpers'
    }
    .setup-ch_k8s_helpers
    
    . ~/dotfiles/dot_ch_dbenv.sh || .tick_bpu '!! failed to load .setup-ch-dbenv'

    .tick_bpu "[finish] .setup-ch_specific"
  }
  .setup-ch_specific

  alias .reload-shell='qeval exec $SHELL -l'
  alias .reload-bash-profile='qeval . ~/.bash_profile'
  alias .reload-bash-profile-user='qeval . ~/.bash_profile.$USER' .rlbpu='.reload-bash-profile-user'

  # Make sure prompt show success first time thru
  ((1)) && eval "$PROMPT_COMMAND"
}
.bash_profile_user_wrapper


.tick-bash-profile-user -e 'printf "[FINISH-FILE] ~/.bash_profile.toddpierzina \$\$=$$ \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$- fns=%d\n" $(declare -F | wc -l)'
