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

.profile-wrapper() {
  local dot_fname='.profile'

  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-profile() {
    .dot-reset-mtimes
    eval-quiet . ~/.profile
  }

  .tick-profile() { .tick -s '.profile' "\$\$=$$ $@"; }
  .tick-profile "[START-FILE] \$SHELL=$SHELL, \$PPID=$PPID, mtime=$(file-mtime ~/$dot_fname)"

  .tick-and-source .tick-profile ~/.bash_profile


  # Insert initialization here.
  .tick-profile "... nothing to initialize in ~/$dot_fname"

  
  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-profile "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.profile-wrapper && unset -f .profile-wrapper .tick-profile
