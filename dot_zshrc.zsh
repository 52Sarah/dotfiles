#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

zshrc-wrapper() {
  local dot_fname='.zshrc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-zshrc() {
    unset "_DOT_MTIMES[~/.zshrc]"
    eval-quiet source ~/.zshrc
  }
  alias .rlzrc='eval-verbose .reload-zshrc'

  is-command .tick || source ~/.tick.sh
  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zshrc)" #, \$PATH=[$PATH]"

  safe-source ~/.sh_rc


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


  #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
  export SDKMAN_DIR="$HOME/.sdkman"
  safe-source "$HOME/.sdkman/bin/sdkman-init.sh"

  safe-source "$HOME/.iterm2_shell_integration.zsh"

  export NODE_EXTRA_CA_CERTS=$HOME/.onyx-env/onyx-truststore.pem
  export SSL_CERT_FILE=$HOME/.onyx-env/onyx-truststore.pem
  export REQUESTS_CA_BUNDLE=$HOME/.onyx-env/onyx-truststore.pem


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
zshrc-wrapper $@
unset -f zshrc-wrapper .tick-zshrc

