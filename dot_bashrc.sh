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

.bashrc-wrapper() {
  local dot_fname='.bashrc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-bashrc() {
    .dot-reset-mtimes
    eval-quiet source ~/.bashrc
  }

  .tick-bashrc() { .tick -s '.bashrc' "$SHELL \$\$=$$ $@"; }
  .tick-start-line .tick-bashrc $dot_fname

  # Local overrides might be in ~.zshenv; since Bash has no equivalent, read that file here too.
  .tick-and-source .tick-bashrc ~/.zshenv

  .tick-and-source .tick-bashrc ~/.sh_rc

  
  #
  ### GCLOUD-SDK (replicate what Zsh's gcloud plugin takes care of)
  #
  if [[ -z $HOMEBREW_PREFIX ]]; then
    .tick-bashrc '[skip] gcloud-sdk: HOMEBREW_PREFIX not defined'
  elif [[ ! -d $HOMEBREW_PREFIX/share/google-cloud-sdk/bin ]]; then
    .tick-bashrc '[skip] gcloud-sdk: no $HOMEBREW_PREFIX/share/google-cloud-sdk/bin directory'
  else
    .tick-and-source .tick-bashrc "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.bash.inc"
    .tick-and-source .tick-bashrc "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.bash.inc"
  fi


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-bashrc "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.bashrc-wrapper && unset -f .bashrc-wrapper .tick-bashrc
