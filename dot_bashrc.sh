              #!/usr/bin/env bash

# At startup, Bash reads from:
#   1. Login shells: first of [~/.bash_profile, ~/.bash_login, ~/.profile]
#   2. Interactive shells: ~/.bashrc
# If BASH_ENV is defined (typically ~/.bashrc), it is read when Bash executes a shell script.
# See: https://stackoverflow.com/a/18187389/160955

[[ -e ~/.sh_bootstraprc ]] && source ~/.sh_bootstraprc

bashrc-wrapper() {

  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  # _TICK_x variables control its behavior; all default to false/0/off.
  # export _TICK_OFF= _TICK_ON=
  # export _TICK_STDERR= _TICK_STDOUT=
  .tick-bashrc() { .tick -s '.bashrc' $@; }

  .tick-bashrc "[START-FILE] (\$\$=$$, \$PATH=[$PATH]"

  # Private env vars, etc. can be in the optional file ~/.secrets.
  if [[ -e ~/.secrets ]]; then
    source ~/.secrets
    .tick-bashrc '... read ~/.secrets'
  fi

  # Put my homemade scripts and other miscellany here at the start of the classpath.
  if ! matches "$PATH" "$HOME/bin(:|$)"; then
    export PATH="$HOME/bin:$PATH"
    .tick-bashrc "... prepended ~/bin to PATH"
  fi


  setup-npm() {
    .tick-bashrc '[start] setup npm/Node/Nexus'

    local rootca_pem="$(mkcert -CAROOT)/rootCA.pem"
    if [[ -e "$rootca_pem" ]]; then
      export NODE_EXTRA_CA_CERTS="$rootca_pem"
    else
      .tick-bashrc "... $rootca_pem: No such file; cannot set NODE_EXTRA_CA_CERTS"
    fi

    for yarn_bin in ~/.yarn/bin ~/.config/yarn/global/node_modules/.bin; do
      if [[ -e "$yarn_bin" ]]; then
        path-append --prepend "$yarn_bin"
      else
        .tick-bashrc "... $yarn_bin: No such directory; cannot prepend to PATH"
      fi
    done
    _QUIET=1 safe-source $HOME/configure_nexus_npm_token.sh

    .tick-bashrc '[end] setup npm/Node/Nexus'
  }
  setup-npm

  #
  ### ASDF
  #
  if [[ -e ~/.asdf/asdf.sh ]]; then
    source ~/.asdf/asdf.sh
    .tick-bashrc '... read ~/.asdf/asdf.sh'
    # _QUIET=1 safe-source ~/.asdf/plugins/java/set-java-home.bash
    # PATH="/usr/local/opt/openjdk/bin:$PATH"
  fi

  #
  ### PWR-JUMPER
  #
  if [[ -e ~/.pwrfunc.sh ]]; then
    source ~/.pwrfunc.sh
    .tick-bashrc '... read ~/.pwrfunc.sh'
  fi

  .tick-bashrc "[END-FILE] (\$\$=$$, \$PATH=[$PATH])"
}
bashrc-wrapper $@

alias .reload-bashrc='qeval . ~/.bashrc'
alias .rlbrc='veval .reload-bashrc'
