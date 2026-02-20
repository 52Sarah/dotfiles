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

# At startup, Bash reads from:
#   * login shells: first of ~/.bash_profile, ~/.bash_login, ~/.profile
#   * interactive shells: ~/.bashrc
#   * non-interactive shells: $BASH_ENV (set here to ~/.bashrc)
# See: https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html

source ~/.sh_bootstrap

sh-profile-wrapper() {
  local dot_fname='.sh_profile'

  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-sh-profile() {
    .dot-reset-mtimes
    eval-quiet source ~/.sh_profile
  }

  export _TICK_INDENT=
  .tick-sh-profile() { .tick -s ".sh_profile" $@; }
  .tick-sh-profile "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname), \$SHELL=$SHELL"


  # Insert initialization here.
  .tick-sh-profile "... nothing to initialize in ~/$dot_fname"


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-sh-profile "[END-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname)"
}
sh-profile-wrapper $@
unset -f sh-profile-wrapper .tick-sh-profile
