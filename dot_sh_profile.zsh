#!/usr/bin/env zsh

# Shell-agnostic definitions for login shells, executed before .bashrc/.zshrc.
# Functions defined here should depend only on ~/.sh_bootstrap.
#
# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

sh-profile-wrapper() {
  local dot_fname='.sh_profile'

  dot-ok-to-skip ~/$dot_fname && return 

  .reload-profile() {
    dot-reset-mtimes
    eval-quiet source ~/.sh_profile
  }

  export _TICK_INDENT=
  .tick-sh-profile() { .tick -s ".sh_profile" $@; }
  .tick-sh-profile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.sh_profile)" #, \$PATH=[$PATH], \$PS1=[$PS1])"


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-sh-profile "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
sh-profile-wrapper $@
unset -f sh-profile-wrapper .tick-sh-profile
