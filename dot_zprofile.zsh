#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

.zprofile-wrapper() {
  local dot_fname='.zprofile'

  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-zprofile() {
    unset "_DOT_MTIMES[.zprofile]"
    eval-quiet source ~/.zprofile
  }
  alias .rlzp='eval-verbose .reload-zprofile'

  .tick-zprofile() { .tick -s ".zprofile" $@; }
  .tick-zprofile "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname), \$SHELL=$SHELL"

  safe-source ~/.sh_profile


  # Insert initialization here.


  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-zprofile "[END-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname)"
}
.zprofile-wrapper && unset -f .zprofile-wrapper
