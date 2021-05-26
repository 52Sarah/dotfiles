#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# ch-bash-profile's .bash_profile runs this user-specific script if it exists

.bash_profile.USER() {

  # Don't show the 'zsh is the default shell' message.
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # Non-interactive shells read the $BASH_ENV file, if any.
  export BASH_ENV="$HOME/.bashrc.$USER"
  . "$BASH_ENV"


  unset TICK_BASH_PROFILE_USER
  if type -t .tick >&/dev/null && [[ -e "$HOME/.tick.bash_profile.$USER" ]]; then
    export TICK_BASH_PROFILE_USER='~/.bash_profile.$USER'
    .tick_bpu() { .tick -s "$TICK_BASH_PROFILE_USER" "$@"; }
    .tickeval_bpu() { .tickeval -s "$TICK_BASH_PROFILE_USER" "$@"; }
  else
    .tick_bpu() { :; }
    .tickeval_bpu() { :; }
  fi
  .tickeval_bpu 'printf "== START == \$-=[%s] PID,PPID,COMMAND=[%s] \$_=[%s]\n" "$-" "$(ps -o pid,ppid,command -p $PPID | tail -n -1)" "$_"'


  # Offloaded 
  [[ -e "$HOME/.bash_settings.$USER" ]] && . "$HOME/.bash_settings.$USER"
  
  #
  ### 'ls' helpers:
  # -o  show owner
  # -l  show owner and group)
  # -h  human-readble file sizes
  # -F  add suffix (/@)
  # -tr sort by time modified, old to new
  # -Sr sort by size, ascending
  #
  ll() {    ls -ohF "$@" | tilde-compress; }
  lltr() {  ls -ohFtr "$@" | tilde-compress; }
  llsr() {  ls -ohFSr "$@" | tilde-compress; }
  la() {    ls -AohF "$@" | tilde-compress; }
  lA() {    ls -aohF "$@" | tilde-compress; }
  latr() {  ls -AohFtr "$@" | tilde-compress; }
  lasr() {  ls -AohFSr "$@" | tilde-compress; }
  #
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
  #
  # Display permissions in octal, from: http://askubuntu.com/a/152005
  # I've tried to figure out how this works but have no fucking clue.
  lso() {
    ls -ohF "$@" |\
    awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' |\
    sed -E -e "s:\\$HOME:\\~:g"
  }

  #
  ### 'tail' helpers
  #
  alias t='tail'
  alias tf='tail -f'
  # Lines will not wrap on screen, BUT by interrupting (CTRL-C), arrow keys can scroll
  # left and write. Press 'F' to resume "tailing".
  alias tfl='less --chop-long-lines +F'

  #
  ### 'find' helperrs
  #
  alias nfind='find -L . -name '
  alias pfind='find -L . -path '
  alias rfind='find -L -E . -regex '

  #
  ### terminal wrap/unwrap
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

  # Oops, return to where I was one time, if possible.
  uncd() {
    [[ -z "$OLDPWD" ]] && >&2 echo 'uncd: cannot determine prior directory' && return 1
    [[ ! -d "$OLDPWD" ]] && >&2 echo 'uncd: $OLDPWD: prior directory no longer exists' && return 1
    cd "$OLDPWD"
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
# shellcheck disable=SC2206,SC2086  # quote to avoid split
touchd_R() {
    local dirs=("$@")
    [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
    for dir in "${dirs[@]}"; do
        # local subdirs="$(find "$dir" -depth ! -type f)"
        # vecho "touchd_R: for $dir, found subdirs: $subdirs"
        # for subdir in $subdirs; do
        find "$dir" -depth ! -type f -print |\
        while read -r subdir; do
            # vecho "touchd_R: calling touchd for subdir='$subdir'"
            touchd "$subdir"
        done
        # vecho "touchd_R: calling touchd for dir='$dir'"
        touchd "$dir"
    done
}

  #
  ### CH-Specific
  #
  vault-token-refresh() {
    vault login -method=ldap -no-print username=todd.pierzina password=$SECRET_OKTA_CRED && echo Vault token refreshed.
  }


  #
  ###  GIT
  #
  # Enable git prompt and completion if installed.
  #
  _setup_git() {
    ! type -t git &>/dev/null && .tick_bpu "git not installed" && return 0
    .tickeval_bpu 'echo "using $(git --version)"'

    alias g='git'

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
        [[ -z "$gitbr" ]] && eecho "gf-feature-finish: not in a git repository" && return 1
        local featureName="${1:-${gitbr#*feature/}}"; [[ -n "$1" ]] && shift
        mvn --batch-mode $1 gitflow:feature-start -Dverbose=true -DfeatureName=$featureName $2
      }
    fi
    
    export __GIT_PROMPT_DIR="$(brew --prefix)/opt/bash-git-prompt/share"
    if [[ -e "$__GIT_PROMPT_DIR/gitprompt.sh" ]]; then
      .tick_bpu "using git-prompt in $__GIT_PROMPT_DIR"
      export GIT_PROMPT_ONLY_IN_REPO=
      export GIT_PROMPT_SHOW_UPSTREAM=1
      export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
      export GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=1

      export GIT_PROMPT_THEME='Custom'
      . "$__GIT_PROMPT_DIR/gitprompt.sh"
    else
      .tick_bpu "not using git-prompt"
    fi
    .tick_bpu "PS1: [$PS1]"
    .tick_bpu "PROMPT_COMMAND=[$PROMPT_COMMAND]"

    if [[ -e "$HOME/.git-completion" ]]; then
      .tick_bpu "loading git completion from $HOME"
      . "$HOME/.git-completion"
    fi
    complete -p | grep -E -q 'git$' && .tick_bpu "loaded git cli completion" || .tick_bpu "not using git completion"

    if [[ -e "$HOME/.git-flow-completion" ]]; then
      .tick_bpu "loading git-flow completion from $HOME"
      . "$HOME/.git-flow-completion"
    fi
  }
  _setup_git && unset -f _setup_git


  #
  ### JAVA/JENV
  #
  _setup_java() {
    ! type -t jenv &>/dev/null && .tick_bpu "jenv not installed" && return 0

    if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
      .tick_bpu "jenv already initialized"
    else
      .tick_bpu "initializing jenv"
      eval "$(jenv init -)"
      [[ ! "$PATH" =~ \.jenv/bin ]] && export PATH="$HOME/.jenv/bin:$PATH"
      .tick_bpu "initialized jenv, PATH: [$PATH]"
    fi
    .tickeval_bpu 'echo "using $(jenv --version), version=$(jenv version)"'
    
    .tick_bpu "trying to set JAVA_HOME from jenv"
    local javahome="$(jenv javahome)"
    if [[ -z "$javahome" || ! -d "$javahome" || -d "$javahome/bin" ]]; then
      .tick_bpu "jenv reports a non-existent or invalid JAVA_HOME: [$javahome]"
    else
      [[ -n "$JAVA_HOME" ]] && .tick_bpu "changing JAVA_HOME from [$JAVA_HOME]"
      export JAVA_HOME="$javahome"
    fi
    .tick_bpu "using JAVA_HOME: [$JAVA_HOME]"
  }
  _setup_java && unset -f _setup_java


  #
  ### PYTHON
  #   TODO: may have to move this to .bashrc
  #
  # Set up Python aliases, tools and completion if installed.
  _setup_pyenv() {
    ! type -t pyenv &>/dev/null && .tick_bpu "pyenv not installed"
    if [[ "$(type -t pyenv 2>/dev/null)" == "function" ]]; then
      .tick_bpu "pyenv already initialized"
    else
      .tick_bpu "initializing pyenv"
      export PYENV_HOME="$HOME/.pyenv"
      [[ ! $"PATH" =~ $PYENV_HOME/bin ]] && export PATH="$PYENV_HOME/bin:$PATH" && .tick_bpu "PATH: [$PATH]"
      eval "$(pyenv init -)"
    fi
    .tickeval_bpu 'echo "using $(pyenv --version 2>/dev/null), version=$(pyenv version)"'
  }
  #
  _setup_python() {
    ! type -t python &>/dev/null && .tick_bpu "python not installed" && return 0

    .tickeval_bpu 'echo "using python version: $(python --version)"'
    .tickeval_bpu 'echo "using pip version: $(pip --version)"'

    .tick_bpu "initializing pip completion"
    eval "$(python -m pip completion --bash)"
    complete -p | grep -E -q 'pip$' && .tick_bpu "loaded pip cli completion"
  }
  _setup_pyenv && unset -f _setup_pyenv
  _setup_python && unset -f _setup_python

  #
  ### PS1 COMMAND LINE PROMPT
  #
  # - if unset, leave unset (non-interactive shell)
  # - if last command was in error, display "!" prefix before "$" and before line sep
  # - `history -a` explicitly flushes the session history to the history file
  # __git_ps1 shows the current git branch, if any, and is configured below
  # - \u = user, \h = hostname, \w = working dir
  #
  _prompt_command() {
    local prev_status=$?
    .tick_bpu "starting _prompt_command, prev_status=[$prev_status]"
    [[ -z "$PS1" ]] && return 0

    history -a
    local _pprefix && ((prev_status)) && _pprefix="!\$" || _pprefix="\$"
    export PS1="\\w $_pprefix "
    # export PS1='--\n$(__git_ps1 "[%s]") \w $_pprefix '
    # export GIT_BRANCH="$(git branch --show-current 2> /dev/null)"
    # __git_ps1 "$_sep\n" " \w $_pprefix\$ " "[%s]"'
    .tick_bpu "finishing _prompt_command, PS1=[$PS1]"
  }
  #export PROMPT_COMMAND='_prompt_command'


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


  .tickeval_bpu 'printf "== FINISH ==\n"'
}
.bash_profile.USER "$@"
