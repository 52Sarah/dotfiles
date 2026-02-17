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
  alias .rlbrc='eval-verbose .reload-bashrc'

  .tick-bashrc() { .tick -s '.bashrc' $@; }
  .tick-bashrc "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname), \$SHELL=$SHELL"

  # Local overrides might be in ~.zshenv; since Bash has no equivalent, read that file here too.
  if [[ ! -f ~/.zshenv ]]; then
    .tick-bashrc '... no ~/.zshenv file to read'
  else
    source ~/.zshenv
    .tick-bashrc '... read ~/.zshenv file'
  fi

  safe-source ~/.sh_rc


  # Insert initialization here.


  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-bashrc "[END-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname)"
}
.bashrc-wrapper && unset -f .bashrc-wrapper .tick-bashrc
