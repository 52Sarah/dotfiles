#!/usr/bin/env zsh

# Shell-agnostic definitions for login shells, invoked after .zshrc/.bashrc.
# - functions and aliases
# - read ~/.secrets
# - augment PATH with ~/bin and/or ~/.local/bin
# - tools requiring initialization (e.g., SnowSQL or SDKMAN)
# Functions defined here should depend only on ~/.sh_bootstrap.

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

# At startup, Bash reads from:
#   * login shells: first of ~/.bash_profile, ~/.bash_login, ~/.profile
#   * interactive shells: ~/.bashrc
#   * non-interactive shells: $BASH_ENV (set here to ~/.bashrc)
# See: https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html

source ~/.sh_bootstrap

.sh-login-wrapper() {
  local dot_fname='.sh_login'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-sh-login() {
    .dot-reset-mtimes
    eval-quiet source ~/.sh_login
  }

  export _TICK_INDENT=
  .tick-sh-login() { .tick -s ".sh_login" "$SHELL \$\$=$$ $@"; }
  .tick-start-line .tick-sh-login $dot_fname


  #
  ### terminal setup
  #
  export HISTCONTROL=ignoreboth
  export HISTSIZE=100000
  export HISTFILESIZE=$HISTSIZE
  #
  export EDITOR=vi
  #
  # Note: CLICOLOR_FORCE has an adverse interaction with a few tools.
  export CLICOLOR=1 CLICOLOR_FORCE=1

  #
  ### 'less' setup
  #
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
  export LESS='--shift=.33 --SEARCH-SKIP --quit-if-one --status-column --LONG-PR --quit-at-eof --raw --squeeze --HILITE-UNREAD --no-init'
  export LESSEDIT='subl --new-window --wait --stay %f\:%lm'

  #
  ### 'ack' helpers
  #
  if is-command ack; then
    alias ack-help-types='eval-quiet ack --help-types'
    alias ack-java='ack --type=java' ackj='ack-java'
    alias ack-kotlin='ack --type=kotlin' ackk='ack-kotlin'
    alias ack-mutation='ack --type=mutation'
  fi

  #
  ### GIT (basic aliases and functions)
  #
  alias gbr='eval-quiet git branch'
  alias gbrv='eval-quiet git brv' # git-extras
  alias gbr-rm='eval-quiet git br-rm'
  alias gbr-mv='eval-quiet git br-mv'
  alias gbr-cp='eval-quiet git br-cp'
  #
  # make a backup copy of current branch using timestamp 'mmdd' as default suffix
  git-branch-bak() {
    [[ -n "$1" ]] && mmdd="$1" || mmdd="$(date +'%m%d')"
    local mmdd="${1:-$(date +'%m%d')}"
    eval-quiet git br-cp \"$GIT_BRANCH\" \"${GIT_BRANCH}.BAK.${mmdd}\"
  }
  alias gbr-bak='eval-quiet git-branch-bak'
  #
  git-branch-set-upstream() {
    eval-quiet git branch --set-upstream-to "origin/$GIT_BRANCH"
  }
  git-branch-set-upstream-to() { 
    eval-quiet git branch --set-upstream-to "${@:-origin/$GIT_BRANCH}"
  }
  git-branch-unset-upstream() { 
    eval-quiet git branch --unset-upstream
  }
  #
  git-rebase-main() {
    eval-quiet git fetch \
    && eval-quiet git co main \
    && eval-quiet git pull --ff-only --progress \
    && eval-quiet git co - \
    && eval-quiet git rebase main \
    && eval-quiet git log -n 5
  }
  #
  alias gl='eval-quiet git log -n 5'
  alias glo='eval-quiet git log1 -n 5'
  alias glog='eval-quiet git log2 -n 5'
  #
  alias gpff='eval-quiet git pull --ff-only --progress'
  #
  alias git-rebase-develop='eval-quiet git fetch && eval-quiet git rebase origin/develop'
  # alias git-rebase-main='eval-quiet git fetch && eval-quiet git co main && eval-quiet git pull --ff-only --progress && eval-quiet git rebase origin/main'
  alias git-rebase-abort='eval-quiet git rebase --abort'
  #
  alias gs='eval-quiet git stash'
  alias gs-help='eval-quiet git stash -h'
  alias gs-list='eval-quiet git stash list' 
  alias gs-listd='eval-quiet git stash list --date=short' 
  alias gs-lists='eval-quiet git stash list --stat' 
  alias gs-apply='eval-quiet git stash apply' 
  alias gs-show='eval-quiet git stash show'
  #
  alias gsa='eval-quiet gs-apply'
  alias gsl='eval-quiet gs-list' 
  alias gsld='eval-quiet gs-listd' 
  alias gsls='eval-quiet gs-list --stat' 
  alias gss='eval-quiet gs-show' 
  #
  alias gst='eval-quiet git st'
  alias gsta='eval-quiet git st1'
  alias gstat='eval-quiet git st2'
  alias gstatu='eval-quiet git st3'

  #
  ### JENV
  #
  if is-command jenv; then
    .setup-java-jenv() {
      .tick-sh-login '[start] .setup-java-jenv'

      if is-zsh && [[ "$(whence -w jenv)" == "jenv: function" ]]; then
        .tick-sh-login 'jenv already initialized'
      elif ! is-zsh && [[ "$(type -t)" == "function" ]]; then
        .tick-sh-login 'jenv already initialized'
      else
        .tick-sh-login '... initializing jenv'
        eval "$(jenv init --no-rehash -)"
        path-prepend "$HOME/.jenv/bin"
        .tick-sh-login "... initialized jenv"
      fi
      # .tick-sh-login -e 'echo "... using $(jenv --version)"'
      # .tick-sh-login -e 'echo "... using java $(jenv version)"'
      # .tick-sh-login -e 'echo "... $ which javac: $(2>&1 which javac)"'
      # .tick-sh-login -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
      
      local jenv_javahome="$(jenv javahome)"
      if [[ -z "$jenv_javahome" ]]; then
        .tick-sh-login "jenv reports a blank JAVA_HOME"
      elif [[ ! -d "$jenv_javahome" ]]; then
        .tick-sh-login "jenv reports a non-directory JAVA_HOME: $jenv_javahome"
      elif [[ ! -d "$jenv_javahome/bin" ]]; then
        .tick-sh-login "jenv non-directory JAVA_HOME/bin: $jenv_javahome/bin"
      else
        export JAVA_HOME="$jenv_javahome"
      fi

      .tick-sh-login -e "tilde [end] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
    }
    .setup-java-jenv
  fi

  #
  ### POSTGRESQL (via HOMEBREW)
  #
  if ((_DOT_SKIP_POSTGRES_SETUP)); then
    .tick-sh-login '[skip] pg: _DOT_SKIP_POSTGRES_SETUP'
  elif [[ -z "$HOMEBREW_PREFIX" ]]; then
    .tick-sh-login '[skip] pg: HOMEBREW_PREFIX not defined'
  elif ! is-command brew; then
    .tick-sh-login '[skip] pg: brew command not installed'
  else
    .setup-pg() {
      export HOMEBREW_POSTGRESQL_SERVICE='postgresql@17'
      if [[ ! -e "$HOMEBREW_PREFIX/Cellar/$HOMEBREW_POSTGRESQL_SERVICE" ]]; then
        .tick-sh-login "[skip] .setup-pg, invalid HOMEBREW_POSTGRESQL_SERVICE=$HOMEBREW_POSTGRESQL_SERVICE"
        return 1
      fi
      alias pg-restart='eval-quiet brew services restart $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-start='eval-quiet brew services start $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-stop='eval-quiet brew services stop $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-info='eval-quiet brew services info -v $HOMEBREW_POSTGRESQL_SERVICE'
    }
   .setup-pg
  fi  

  #
  ### SCHEMASPY
  #
  if [[ -f "$HOME/lib/schemaspy.jar" ]]; then
    schemaspy() {
      local driver_path="$HOME/lib"
      local spy_output="schemaspy-out"
      while [[ "$1" =~ -[a-z] ]]; do case "$1" in
        -dp|--driver-path)    driver_path="$2"; shift 2;;
        -o|--outputDirectory) spy_output="$2"; shift 2;;
        *) break;;
      esac; done
      eval-quiet java -jar "$HOME/lib/schemaspy.jar" \
        -cat '%' \
        -dp "$driver_path" \
        -o  "$spy_output" \
        -noviews -noimplied -nopages -maxdet 9999 \
        $@
    }
    .tick-sh-login 'schemaspy command defined'
  fi

  #
  ### PIPENV
  #
  if is-command pipenv; then
    export PIPENV_SHELL="$SHELL"
    .tick-sh-login "pipenv: set PIPENV_SHELL=$PIPENV_SHELL"
  fi

  #
  ### RANCHER DESKTOP
  #
  .setup-rancher-desktop() {
    if ((_DOT_SKIP_RANCHER_DESKTOP_SETUP)); then
      return 1
    elif [[ ! -d ~/.rd/bin ]]; then
      return 1
    else
      path-apppend "$HOME/.rd/bin"
      .tick-sh-login 'Rancher Desktop: appended ~/.rd/bin to PATH'
    fi
  }
  .setup-rancher-desktop


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-sh-login "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.sh-login-wrapper && unset -f .sh-login-wrapper
