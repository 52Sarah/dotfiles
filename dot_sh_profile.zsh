#!/usr/bin/env zsh

# Shell-agnostic functions for all login scripts.
# Functions defined here do not depend on any other startup files.
# No references to tick logging in this file.
#
# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

sh-profile-wrapper() {
  local dot_fname='.sh_profile'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-profile() {
    unset "_DOT_MTIMES[.sh_profile]"
    eval-quiet source ~/.sh_profile
  }

  export _TICK_INDENT=
  is-command .tick || safe-source ~/.tick.sh
  .tick-profile() { .tick -s ".sh_profile" $@; }
  .tick-profile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.sh_profile)" #, \$PATH=[$PATH], \$PS1=[$PS1])"


  # This space intentionally left blank.


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-profile "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
sh-profile-wrapper $@
unset -f sh-profile-wrapper .tick-profile
