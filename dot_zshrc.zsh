#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

.zshrc-wrapper() {
  local dot_fname='.zshrc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-zshrc() {
    .dot-reset-mtimes
    eval-quiet source ~/.zshrc
  }
  alias .rlzrc='eval-verbose .reload-zshrc'

  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/.zshrc), \$SHELL=$SHELL"

  safe-source ~/.sh_rc

  #
  ### ITERM shell integration and prompt/display helpers
  #
  if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
    .tick-zshrc ' ... ~/iterm2: no iterm2_shell_integration.zsh file to read'
  else
    source "$HOME/.iterm2_shell_integration.zsh"
    .tick-zshrc ' ... ~/iterm2: read iterm2_shell_integration.zsh file'
  fi


  # Insert initialization here.

  
  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
.zshrc-wrapper && unset -f .zshrc-wrapper
