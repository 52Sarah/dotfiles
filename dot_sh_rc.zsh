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

.sh-rc-wrapper() {
  local dot_fname='.sh_rc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-sh-rc() {
    .dot-reset-mtimes
    eval-quiet source ~/.sh_rc
  }

  .tick-sh-rc() { .tick -s '.sh_rc' "$SHELL \$\$=$$ $@"; }
  .tick-start-line .tick-sh-rc $dot_fname


   # Private env vars, etc. can be in the optional file ~/.secrets.
   .tick-and-source .tick-sh-rc ~/.secrets

  # Put homemade scripts and other miscellany here at the start of the classpath.
  if [[ -d ~/.local/bin ]]; then
    path-prepend "$HOME/.local/bin"
    .tick-sh-rc '... prepended ~/.local/bin to PATH'
  fi
  if [[ -d ~/bin ]]; then
    path-prepend "$HOME/bin"
    .tick-sh-rc '... prepended ~/bin to PATH'
  fi


  # added to .zshrc by Snowflake SnowSQL installer v1.2
  local SNOWSQL_PKG="/Applications/SnowSQL.app/Contents/MacOS"
  if [[ -d "$SNOWSQL_PKG" ]]; then
    path-prepend "$SNOWSQL_PKG"
    .tick-sh-rc " ... prepended $SNOWSQL_PKG to PATH"
  fi

  #
  ### ASDF
  #
  .tick-and-source .tick-sh-rc ~/.asdf/asdf.sh

  #
  ###  HOMEBREW
  #
  .setup-homebrew() {
    .tick-sh-rc "[start] .setup-homebrew, INTELLIJ_ENVIRONMENT_READER=$INTELLIJ_ENVIRONMENT_READER"

    local brew_binary="$(glob-path-first /usr/local/bin/brew /opt/homebrew/bin/brew)"
    if [[ ! -e "$brew_binary" ]]; then
      .tick-sh-rc "... homebrew not installed"
      .tick-sh-rc "... execute: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      .tick-sh-rc "[end] .setup-homebrew"
      return 1
    fi

    eval "$($brew_binary shellenv $SHELL 2>/dev/null)"
    if [[ -d "$HOMEBREW_PREFIX" ]]; then
      .tick-sh-rc "... homebrew shellenv properly set HOMEBREW_PREFIX=$HOMEBREW_PREFIX"
    else
      .tick-sh-rc "... homebrew shellenv did not properly set \$HOMEBREW_PREFIX"
      .tick-sh-rc "[end] .setup-homebrew"
      return 1
    fi

    local brew_bin="$(substring-before-last $brew_binary '/')"
    path-prepend "$brew_bin"
    .tick-sh-rc "... prepended $brew_bin to PATH"

    local openssl_home="$HOMEBREW_PREFIX/opt/openssl@3"
    if [[ -e "$openssl_home" ]]; then
      path-prepend "$openssl_home/bin"
      .tick-sh-rc "... prepended $openssl_home/bin to PATH"
    fi

    .tick-sh-rc "[end] .setup-homebrew"
  }
  .setup-homebrew

  #
  ### SDKMAN
  #
  if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    .tick-sh-rc '... initialized SDKMAN'
  fi

  # Make key env vars available to UI apps, esp. IntelliJ
  launchctl setenv PATH "$PATH"
  launchctl setenv JAVA_HOME "$JAVA_HOME"


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-sh-rc "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.sh-rc-wrapper && unset -f .sh-rc-wrapper
