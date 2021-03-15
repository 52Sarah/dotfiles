#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# ch-bash-profile's .bash_profile runs this user-specific script if it exists

# Non-interactive shells read the $BASH_ENV file, if any.
export BASH_ENV="$HOME/.bashrc.$USER"
. "$BASH_ENV"

# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1


# Simple login file debugging, enabled if caller checks that ~/.tick.LOGINSCRIPT exists 
# and sets prefix accordingly.
.tick() { 
  local prefix="$1" && shift && [[ -z "$prefix" ]] && return 
  local dt="$(date +'%D %T')"
   2>&1 printf "%s %s %s\n" "$dt" "$prefix" "$*" >> "$HOME/.tick.log"
}
.tickeval() { # delayed evaluation
  local prefix="$1" && shift && [[ -z "$prefix" ]] && return 0
  .tick "$prefix" "$(eval "$*")"
}


.bash_profile.USER() {

  local tick_prefix= && [[ -e "$HOME/.tick.bash_profile.$USER" ]] && tick_prefix='[.b_prof.$USER]'
  .tickeval "$tick_prefix" 'printf "== START == SHELLOPTS=[%s]\n" "$-"'
  # .tickeval "$tick_prefix" 'printf "== START == SHELLOPTS=[%s]\n" "$SHELLOPTS"'


  # Usage: 'set -x' enables "x" and 'set +x' disables it. List below shows letter and name.
  # Default enabled shell options/variables are commented out below.
  #   $-=himBH
  #   $SHELLOPTS=braceexpand:emacs:hashall:histexpand:history:interactive-comments:monitor
  #
  # set -B -o braceexpand
    set    +o emacs
  # set +e +o errexit
  # set +E +o errtrace
  # set +T +o functrace
  # set -h -o hashall     # remember command location in history
  # set -H -o histexpand  # !-style history substitution
  # set    -o history
    set    -o ignoreeof   # ctrl-d won't close session
  # set    -o interactive-comments
  # set -m -o monitor     # job control enabled
  # set +C +o noclobber   # "noclobber"--files cannot be overwritten by redirection
  # set +n +o noexec      # read commands but don't execute
  # set +u +o nounset     # treat unset variable substitution as error
  # set +t +o onecmd      # exit after executing one command
  # set +v +o verbose     # print shell lines as they are read
    set    -o vi          # vi-style line editing
  # set +x +o xtrace      # print commands and args as they are executed
  # set -i                # indicates shell is interactive; generally read-only

  shopt -s extglob
  shopt -s histappend     # when closing a session, add to history instead of overwriting
  shopt -s cdspell
  shopt -s cmdhist        # store multi-line commands as one line in history


  export EDITOR=vim
  export CLICOLOR=1 CLICOLOR_FORCE=1

  # See: https://ss64.com/bash/less.html
  export LESS='--quit-at-eof --quit-if-one-screen --hilite-search --LONG-PROMPT --RAW --squeeze --HILITE-UNREAD --no-init --shift=.25'
  export LESSEDIT='subl --new-window --wait --stay %f\:%lm'


  # Ignore repeated lines and lines starting with ' '
  export HISTCONTROL=ignoreboth
  export HISTSIZE=100000
  export HISTFILESIZE=$HISTSIZE
  export HISTTIMEFORMAT=' %F %T  '

  # history-grep
  hg() { if [[ -z "$1" ]]; then history; else history | grep -E "$*"; fi }

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'

  # -o show owner (-l includes group), -h human file sizes, -F suffix (/@)
  alias ll='ls -ohF'
  alias lltr='ls -ohFtr'
  alias llsr='ls -ohFSr'
  alias la='ls -AohF'
  alias lA='ls -aohF'
  alias latr='ls -AohFtr'

  # Think "ll and la but narrower": cut out permissions, link count and owner.
  # $ ls -ohF
  # total 520
  # -rw-r--r--  1 toddpierzina   1.2K Mar 10 11:33 README.md
  # $1: permissions, $2: inode count, $3: owner, $4: size, $5: date/time, $6: filename
  lln() {
    ls -oF "$@" |\
    sed -E \
      -e '/^total .+$/d' \
      -e 's/^([^ ]{9,}) +([[:digit:]]+) +([^ ]+) +([^ ]+) ([^ ]+ +[^ ]+ +[^ ]+) +(.+)$/\4'$'\t''\5'$'\t''\6/' |\
    tilde-compress |\
    awk -F$'\t' \
      '{printf "%12'$'\'''d  %s  %s\n", $1, $2, $3}'
  }
  lan() { lln -A "$@"; }

  # Display permissions in octal, from: http://askubuntu.com/a/152005
  # I've tried to figure out how this works but have no fucking clue.
  lso() {
    ls -ohF "$@" |\
      awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' |\
      tilde-compress
    ls -ohF "$@" |\
      awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' |\
      tilde-compress
  }

  alias t='tail'
  alias tf='tail -f'
  alias tfl='less -S +F' # does not wrap long lines

  alias nfind='find -L . -name '
  alias pfind='find -L . -path '
  alias rfind='find -L -E . -regex '

  # Oops, return to where I was, if possible.
  uncd() {
    [[ -z "$OLDPWD" ]] && >&2 echo 'uncd: cannot determine prior directory' && return 1
    [[ ! -d "$OLDPWD" ]] && >&2 echo 'uncd: $OLDPWD: prior directory no longer exists' && return 1
    cd "$OLDPWD"
  }


  #
  ### VAULT
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
    ! type -t git &>/dev/null && .tick "$tick_prefix" "git not installed" && return 0
    .tickeval "$tick_prefix" 'echo "using $(git --version)"'

    alias g='git'
    
    export __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
    if [[ -e "$__GIT_PROMPT_DIR/gitprompt.sh" ]]; then
      .tick "$tick_prefix" "using git-prompt in $__GIT_PROMPT_DIR"
      export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
      export GIT_PROMPT_END_USER='\n\w \$ '
      export GIT_PROMPT_START_USER='_LAST_COMMAND_INDICATOR_'
      export GIT_PROMPT_THEME='Custom' # use custom theme specified in file GIT_PROMPT_THEME_FILE (default ~/.git-prompt-colors.sh)
      # export GIT_PROMPT_ONLY_IN_REPO=1
      # export GIT_PROMPT_SHOW_UPSTREAM=1
      # export GIT_PROMPT_THEME_FILE=~/.git-prompt-colors.sh
      # export GIT_PROMPT_THEME=Solarized # use theme optimized for solarized color scheme
      . "$__GIT_PROMPT_DIR/gitprompt.sh"
    else
      .tick "$tick_prefix" "not using git-prompt"
    fi
    .tick "$tick_prefix" "PS1: [$PS1]"
    .tick "$tick_prefix" "PROMPT_COMMAND=[$PROMPT_COMMAND]"

    # if [[ -e "$HOME/.git-prompt.sh" ]]; then
    #   export GIT_PS1_SHOWDIRTYSTATE=1 GIT_PS1_SHOWUNTRACKEDFILES=1 GIT_PS1_SHOWUPSTREAM=1 GIT_PS1_SHOWCOLORHINTS=1
    #   export GIT_PS1_STATESEPARATOR='|' GIT_PS1_DESCRIBE_STYLE='branch' GIT_PS1_HIDE_IF_PWD_IGNORED=1
    #   . "$HOME/.git-prompt.sh"
    #   .tick "loaded git-prompt, PS1=$PS1"
    # fi
    if [[ -e "$HOME/.git-completion" ]]; then
      .tick "$tick_prefix" "loading git completion from $HOME"
      . "$HOME/.git-completion"
    fi
    complete -p | grep -E -q 'git$' && .tick "$tick_prefix" "loaded git cli completion" || .tick "$tick_prefix" "not using git completion"
  }
  _setup_git


  #
  ### JAVA/JENV
  #   TODO: may have to move this to .bashrc
  #
  _setup_java() {
    ! type -t jenv &>/dev/null && .tick "$tick_prefix" "jenv not installed" && return 0

    if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
      .tick "$tick_prefix" "jenv already initialized"
    else
      .tick "$tick_prefix" "initializing jenv"
      eval "$(jenv init -)"
      [[ ! "$PATH" =~ \.jenv/bin ]] && export PATH="$HOME/.jenv/bin:$PATH"
      .tick "$tick_prefix" "initialized jenv, PATH: [$PATH]"
    fi
    .tickeval "$tick_prefix" 'echo "using $(jenv --version), version=$(jenv version)"'
    
    .tick "$tick_prefix" "trying to set JAVA_HOME from jenv"
    local javahome="$(jenv javahome)"
    if [[ -z "$javahome" || ! -d "$javahome" || -d "$javahome/bin" ]]; then
      .tick "$tick_prefix" "jenv reports a non-existent or invalid JAVA_HOME: [$javahome]"
    else
      [[ -n "$JAVA_HOME" ]] && .tick "$tick_prefix" "changing JAVA_HOME from [$JAVA_HOME]"
      export JAVA_HOME="$javahome"
    fi
    .tick "$tick_prefix" "using JAVA_HOME: [$JAVA_HOME]"
  }
  _setup_java


  #
  ### PYTHON
  #   TODO: may have to move this to .bashrc
  #
  # Set up Python aliases, tools and completion if installed.
  _setup_pyenv() {
    ! type -t pyenv &>/dev/null && .tick "$tick_prefix" "pyenv not installed"
    if [[ "$(type -t pyenv 2>/dev/null)" == "function" ]]; then
      .tick "$tick_prefix" "pyenv already initialized"
    else
      .tick "$tick_prefix" "initializing pyenv"
      export PYENV_HOME="$HOME/.pyenv"
      [[ ! $"PATH" =~ $PYENV_HOME/bin ]] && export PATH="$PYENV_HOME/bin:$PATH" && .tick "$tick_prefix" "PATH: [$PATH]"
      eval "$(pyenv init -)"
    fi
    .tickeval "$tick_prefix" 'echo "using $(pyenv --version 2>/dev/null), version=$(pyenv version)"'
  }
  #
  _setup_python() {
    ! type -t python &>/dev/null && .tick "$tick_prefix" "python not installed" && return 0

    .tickeval "$tick_prefix" 'echo "using python version: $(python --version)"'
    .tickeval "$tick_prefix" 'echo "using pip version: $(pip --version)"'

    .tick "$tick_prefix" "initializing pip completion"
    eval "$(python -m pip completion --bash)"
    complete -p | grep -E -q 'pip$' && .tick "$tick_prefix" "loaded pip cli completion"
  }
  _setup_pyenv
  _setup_python

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
    .tick "$tick_prefix" "starting _prompt_command, prev_status=[$prev_status]"
    [[ -z "$PS1" ]] && return 0

    history -a
    local _pprefix && ((prev_status)) && _pprefix="!\$" || _pprefix="\$"
    export PS1="\\w $_pprefix "
    # export PS1='--\n$(__git_ps1 "[%s]") \w $_pprefix '
    # export GITBR="$(git branch --show-current 2> /dev/null)"
    # __git_ps1 "$_sep\n" " \w $_pprefix\$ " "[%s]"'
    .tick "$tick_prefix" "finishing _prompt_command, PS1=[$PS1]"
  }
  #export PROMPT_COMMAND='_prompt_command'


  # Make specified, or all in PWD, shell scripts executable.
  chx() {
    local opt_verbose=$(( SH_VERBOSE ))
    [[ "$1" =~ ^(-v|--verbose)$ ]] && shift && opt_verbose=1
    
    local files=("$@")
    [[ ! "$1" ]] && files=(*.sh) && opt_verbose=1

    (( opt_verbose )) && opt_verbose="-vv" || opt_verbose=
    chmod $opt_verbose +x "${files[@]}"
  }


  alias .reload-shell='exec $SHELL -l'
  alias .rls='.reload-shell'

  alias .reload-bash-profile='. $HOME/.bash_profile'
  alias .rlbp='.reload-bash-profile'

  alias .reload-bash-profile-user='. $HOME/.bash_profile.$USER'
  alias .rlbpu='.reload-bash-profile-user'


  .tickeval "$tick_prefix" 'printf "== FINISH ==\n"'
}
.bash_profile.USER "$@"
