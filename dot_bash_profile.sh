#!/usr/bin/env bash

# At startup, Bash reads from:
#   * login shells: first of ~/.bash_profile, ~/.bash_login, ~/.profile
#   * interactive shells: ~/.bashrc
#   * non-interactive shells: $BASH_ENV (set here to ~/.bashrc)
#   * shells invoked as 'sh':
#     - login shells: ~/.profile
#     - interactive shells: $ENV file (set here to ~/.profile)
# See: https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html

source ~/.sh_bootstrap

.bash-profile-wrapper() {
  local dot_fname='.bash_profile'

  dot-ok-to-skip ~/$dot_fname && return 

  .reload-bash-profile() {
    dot-reset-mtimes
    eval-quiet . ~/.bash_profile
  }
  alias .rlpf='eval-verbose .reload-bash-profile'

  .tick-bash-profile() { .tick -s ".bash_profile" $@; }
  .tick-bash-profile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' $HOME/.bash_profile)"

  safe-source ~/.sh_profile


  # A non-interactive login shell requires the interactive environment setup.
  safe-source ~/.bashrc


  # Don't show the 'zsh is the default shell' message.
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # Shell scripts executed with Bash will read this file.
  export BASH_ENV=~/.bashrc

  # Shell scripts executed with sh will read this file.
  export ENV=~/.bash_profile

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-bash-profile "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname], PROMPT=[$PROMPT]"
}
.bash-profile-wrapper && unset -f .bash-profile-wrapper
