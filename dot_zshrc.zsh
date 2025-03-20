#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -e ~/.sh_bootstraprc ]] && source ~/.sh_bootstraprc

# Do not execute this script if it has already been run this session and is not modified since.
if [[ "$(sh-ok-to-skip ~/.zshrc)" != 'true' ]]; then

  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  is-defined .tick || source ~/.tick.sh
  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zshrc)" #, \$PATH=[$PATH]"
  
  zshrc-wrapper() {
    .tick-zshrc "[START-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

    # Private env vars, etc. can be in the optional file ~/.secrets.
    if [[ -e ~/.secrets ]]; then
      source ~/.secrets
      .tick-zshrc '... read ~/.secrets'
    else
      .tick-zshrc '... no ~/.secrets to read'
    fi

    # Put my homemade scripts and other miscellany here at the start of the classpath.
    if ! matches "$PATH" "$HOME/bin(:|$)"; then
      path-prepend "$HOME/bin"
      .tick-zshrc '... prepended $HOME/bin to PATH'
    else
      .tick-zshrc '... $HOME/bin already in PATH'
    fi

    .tick-zshrc "[END-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH])"
  }
  zshrc-wrapper $@

  .reload-zshrc() {
    unset "_DOT_SH_MTIMES[zshrc]"
    eval-quiet source ~/.zshrc
  }
  alias .rlzrc='eval-verbose .reload-zshrc'

  .source-extra-start-files '.zshrc'

  sh-store-mtime ~/.zshrc
  .tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_SH_MTIMES[zshrc]" #, \$PATH=[$PATH])"
fi
