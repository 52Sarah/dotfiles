#!/usr/bin/env zsh

# if [[ -z "$_DOT_ZSHRC_MTIME" ]] || (( $(stat -L -f '%m' ~/.zshrc) > _DOT_ZSHRC_MTIME )); then

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -e ~/.sh_bootstraprc ]] && source ~/.sh_bootstraprc

zshrc-wrapper() {


  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  # _TICK_x variables control its behavior; all default to false/0/off.
  # export _TICK_OFF= _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zshrc)" #, \$PATH=[$PATH]"


  # Private env vars, etc. can be in the optional file ~/.secrets.
  if [[ -e ~/.secrets ]]; then
    source ~/.secrets
    .tick-zshrc '... read ~/.secrets'
  fi

  # Put my homemade scripts and other miscellany here at the start of the classpath.
  if ! matches "$PATH" "$HOME/bin(:|$)"; then
    path-prepend "$HOME/bin"
    .tick-zshrc '... prepended $HOME/bin to PATH'
  fi

  #
  ### Interactive shell options.
  #
  # ## expansion and globbing
  setopt EXTENDED_GLOB
  # setopt BAD_PATTERN  # print error msg for bad glob pattern
  # setopt CASE_GLOB    # glob case-sensitive
  # setopt CASE_MATCH   # regex case-sensitive
  # setopt CASE_PATHS   # paths case-sensitive
  # setopt GLOB         # perform globbing
  # setopt GLOB_SUBST   # enable globbing after parameter substitution
  # setopt NO__MATCH    # if glob has no matches, error
  #
  # ## input/output
  setopt PATH_SCRIPT          # check current directory for script, then command path
  #
  # ## job control
  setopt LONG_LIST_JOBS
  # setopt MONITOR      # allow job control
  #
  # ## functions
  # setopt WARN_CREATE_GLOBAL   # warn if global parameter created in function
  # setopt WARN_NESTED_VAR      # warn if enclosing function parameter is set


  export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
  export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
  _QUIET=1 safe-source $HOME/configure_nexus_npm_token.sh

  #
  ### PWR-JUMPER
  #
  source $HOME/.pwrfunc.sh

  .tick-zshrc "[END-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH])"
}
zshrc-wrapper $@

alias .reload-zshrc='qeval . ~/.zshrc'
alias .rlzrc='veval .reload-zshrc'

export _DOT_ZSHRC_MTIME="$(stat -L -f '%m' ~/.zshrc)"
.tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_ZSHRC_MTIME" #, \$PATH=[$PATH])"

# fi