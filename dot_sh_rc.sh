#!/usr/bin/env zsh

# Shell-agnostic definitions for interactive shells:
# - functions and aliases
# - read ~/.secrets
# - augment PATH with ~/bin and/or ~/.local/bin
# - tools that expect to be initialized in .bashrc or .zshrc (Homebrew, SDKMAN)
# Functions defined here should depend only on ~/.sh_bootstrap.

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zshrc for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

.shrc-wrapper() {
  local dot_fname='.sh_rc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-rc() {
    dot-reset-mtimes
    eval-quiet source ~/.sh_rc
  }

  .tick-shrc() { .tick -s ".sh_rc" $@; }
  .tick-shrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.sh_rc)" #, \$PATH=[$PATH], \$PS1=[$PS1])"


   # Private env vars, etc. can be in the optional file ~/.secrets.
  if [[ ! -f ~/.secrets ]]; then
    .tick-shrc '... no ~/.secrets file to read'
  else
    source ~/.secrets
    .tick-shrc '... read ~/.secrets file'
  fi

  # Put homemade scripts and other miscellany here at the start of the classpath.
  if [[ ! -d ~/.local/bin ]]; then
    .tick-shrc '... no ~/.local/bin directory to add to PATH'
  else
    path-prepend "$HOME/.local/bin"
    .tick-shrc '... prepended ~/.local/bin to PATH'
  fi
  if [[ ! -d ~/bin ]]; then
    .tick-shrc ' ... no ~/bin directory to add to PATH'
  elif matches "$PATH" "$HOME/bin(:|$)"; then
    .tick-shrc '... ~/bin already in PATH'
  else
    path-prepend "$HOME/bin"
    .tick-shrc '... prepended ~/bin to PATH'
  fi


  # added to .zshrc by Snowflake SnowSQL installer v1.2
  local SNOWSQL_PKG="/Applications/SnowSQL.app/Contents/MacOS"
  if [[ ! -d "$SNOWSQL_PKG" ]]; then
    .tick-shrc " ... [skip] SnowSQL: no $SNOWSQL_PKG directory to add to PATH"
  else
    path-prepend "$SNOWSQL_PKG"
    .tick-shrc " ... prepended $SNOWSQL_PKG to PATH"
  fi

  #
  ### ASDF
  #
  if [[ -f ~/.asdf/asdf.sh ]]; then
    source ~/.asdf/asdf.sh
    .tick-bashrc '... read ~/.asdf/asdf.sh'
  fi

  #
  ###  HOMEBREW
  #
  .setup-homebrew() {
    .tick-shrc '[start] .setup-homebrew'
    .tick-shrc "... \$INTELLIJ_ENVIRONMENT_READER=$INTELLIJ_ENVIRONMENT_READER"
    .tick-shrc "... \$SHELL=$SHELL"

    local brew_binary="$(glob-path-first /usr/local/bin/brew /opt/homebrew/bin/brew)"
    if [[ -n "$brew_binary" ]]; then
      .tick-shrc "... using homebrew binary: $brew_binary"
    else
      .tick-shrc "... homebrew not installed"
      .tick-shrc "... execute: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      .tick-shrc "[end] .setup-homebrew"
      return 1
    fi

    eval "$($brew_binary shellenv $SHELL 2>/dev/null)"
    if [[ -d "$HOMEBREW_PREFIX" ]]; then
      .tick-shrc "... homebrew shellenv set \$HOMEBREW_PREFIX=$HOMEBREW_PREFIX"
    else
      .tick-shrc "... homebrew shellenv did not properly set \$HOMEBREW_PREFIX"
      .tick-shrc "[end] .setup-homebrew"
      return 1
    fi

    .tick-shrc "... computing brew_bin from \$brew_binary=$brew_binary"
    local brew_bin="$(substring-before-last $brew_binary '/')"
    path-prepend "$brew_bin"
    .tick-shrc "... prepended $brew_bin to PATH"

    local gnu_getopt_home="$HOMEBREW_PREFIX/opt/gnu-getopt"
    .tick-shrc "... checking gnu_getopt_home=$gnu_getopt_home"
    if [[ -e "$gnu_getopt_home" ]]; then
      path-prepend "$gnu_getopt_home/bin"
      .tick-shrc "... prepended $gnu_getopt_home/bin to PATH"
    else
      .tick-shrc "... gnu-getopt not installed via brew"
    fi

    local openssl_home="$HOMEBREW_PREFIX/opt/openssl@3"
    if [[ -e "$openssl_home" ]]; then
      path-prepend "$openssl_home/bin"
      .tick-shrc "... prepended $openssl_home/bin to PATH"
    else
      .tick-shrc '... openssl@3 not installed via brew'
    fi

    .tick-shrc "[end] .setup-homebrew"
  }
  .setup-homebrew

  #
  ### SDKMAN
  #
  if [[ ! -d "$HOME/.sdkman" ]]; then
    .tick-shrc '[skip] SDKMAN: no ~/.sdkman directory'
  elif [[ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    .tick-shrc '[skip] SDKMAN: no ~/.sdkman/bin/sdkman-init.sh file'
  else
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    .tick-shrc '... initialized SDKMAN'
  fi


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-shrc "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
.shrc-wrapper && unset -f .shrc-wrapper
