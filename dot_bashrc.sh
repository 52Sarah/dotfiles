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

  .tick-bashrc() { .tick -s '.bashrc' $@; }
  .tick-bashrc "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname), \$SHELL=$SHELL"

  # Local overrides might be in ~.zshenv; since Bash has no equivalent, read that file here too.
  if [[ ! -f ~/.zshenv ]]; then
    .tick-bashrc '... no ~/.zshenv file to read'
  else
    .tick-bashrc '... reading ~/.zshenv file'
    source ~/.zshenv
    .tick-bashrc '... done reading ~/.zshenv file'
  fi

  .tick-bashrc ' ... reading ~/.sh_rc'
  safe-source ~/.sh_rc
  .tick-bashrc ' ... done reading ~/.sh_rc'


  #
  ### GCLOUD-SDK
  #
  if [[ -z $HOMEBREW_PREFIX ]]; then
    .tick-bashrc '[skip] gcloud-sdk: HOMEBREW_PREFIX not defined'
  elif [[ ! -d $HOMEBREW_PREFIX/share/google-cloud-sdk/bin ]]; then
    .tick-bashrc '[skip] gcloud-sdk: no $HOMEBREW_PREFIX/share/google-cloud-sdk/bin directory'
  else
    source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.bash.inc"
    source "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.bash.inc"
    .tick-bashrc '... added gcloud to PATH and loaded gcloud bash completion'
  fi


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-bashrc "[END-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname)"
}
.bashrc-wrapper && unset -f .bashrc-wrapper .tick-bashrc
