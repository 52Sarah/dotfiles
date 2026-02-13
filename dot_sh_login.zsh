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

source ~/.sh_bootstrap

.sh-login-wrapper() {
  local dot_fname='.sh_login'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-login() {
    .dot-reset-mtimes
    eval-quiet source ~/.sh_login
  }

  # A non-interactive login shell requires the interactive environment setup.
  safe-source ~/.sh_rc

  export _TICK_INDENT=
  .tick-sh-login() { .tick -s ".sh_login" $@; }
  .tick-sh-login "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname), \$SHELL=$SHELL"


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

  export HISTCONTROL=ignoreboth
  export HISTSIZE=100000
  export HISTFILESIZE=$HISTSIZE

  export EDITOR=vi

  # Note: CLICOLOR_FORCE has an adverse interaction with a few tools.
  export CLICOLOR=1 CLICOLOR_FORCE=1

  #
  ### 'ack' helpers
  #
  if is-command ack; then
    alias ack-help-types='eval-quiet ack --help-types'
    alias ack-java='eval-quiet ack --type=java'; alias ackj='ack-java'
  fi

  #
  ### JENV
  #
  if ! is-command jenv; then
    .tick-sh-login '[skip] .setup-java-jenv: jenv command not installed'
  else
    .setup-java-jenv() {
      .tick-sh-login '[start] .setup-java-jenv'
      if [[ "$(whence -w jenv)" == "jenv: function" ]]; then
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
      
      local javahome="$(jenv javahome)"
      if [[ -z "$javahome" ]]; then
        .tick-sh-login "jenv reports a blank JAVA_HOME"
      elif [[ ! -d "$javahome" ]]; then
        .tick-sh-login "jenv reports a non-directory JAVA_HOME: $javahome"
      elif [[ ! -d "$javahome/bin" ]]; then
        .tick-sh-login "jenv non-directory JAVA_HOME/bin: $javahome/bin"
      else
        export JAVA_HOME="$javahome"
      fi

      .tick-sh-login -e tilde-compress "[end] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
    }
    .setup-java-jenv
  fi

  #
  ### POSTGRESQL (via HOMEBREW)
  #
  if ((_DOT_SKIP_POSTGRES_SETUP)); then
    .tick-sh-login '[skip] .setup-pg: _DOT_SKIP_POSTGRES_SETUP'
  elif [[ -z "$HOMEBREW_PREFIX" ]]; then
    .tick-sh-login '[skip] .setup-pg: HOMEBREW_PREFIX not defined'
  elif ! is-command brew; then
    .tick-sh-login '[skip] .setup-pg: brew  command not installed'
  else
    .setup-pg() {
      .tick-sh-login '[start] .setup-pg'
      export HOMEBREW_POSTGRESQL_SERVICE='postgresql@17'
      if [[ -e "$HOMEBREW_PREFIX/Cellar/$HOMEBREW_POSTGRESQL_SERVICE" ]]; then
        .tick-sh-login "... found HOMEBREW_POSTGRESQL_SERVICE=$HOMEBREW_POSTGRESQL_SERVICE"
      else
        .tick-sh-login "[end] .setup-pg, invalid HOMEBREW_POSTGRESQL_SERVICE=$HOMEBREW_POSTGRESQL_SERVICE"
        return 1
      fi
      # path-append '/usr/local/opt/postgresql/bin'
      alias pg-restart='eval-quiet brew services restart $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-start='eval-quiet brew services start $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-stop='eval-quiet brew services stop $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-info='eval-quiet brew services info -v $HOMEBREW_POSTGRESQL_SERVICE'
      .tick-sh-login '[end] .setup-pg'
    }
   .setup-pg
  fi  

  #
  ### SCHEMASPY
  #
  if [[ ! -f "$HOME/lib/schemaspy.jar" ]]; then
    .tick-sh-login '[skip] .setup-schemaspy: ~/lib/schemaspy.jar file not found'
  else
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
  fi

  #
  ### PIPENV
  #
  if ! is-command pipenv; then
    .tick-sh-login '... pipenv is not installed'
  else
    export PIPENV_SHELL="$SHELL"
    .tick-sh-login '... initialized pipenv'
  fi


  #
  ### RANCHER DESKTOP
  #
  if ((_DOT_SKIP_RANCHER_DESKTOP_SETUP)); then
    .tick-sh-login '[skip] Rancher Desktop setup: _DOT_SKIP_RANCHER_DESKTOP_SETUP'
  elif [[ ! -d ~/.rd/bin ]]; then
    .tick-sh-login '... Rancher Desktop: no ~/.rd/bin to add to PATH'
  else
    path-prepend "$HOME/.rd/bin"
    .tick-sh-login '... Rancher Desktop: prepended ~/.rd/bin to PATH'
  fi


  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-sh-login "[END-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname)"
}
.sh-login-wrapper && unset -f .sh-login-wrapper
