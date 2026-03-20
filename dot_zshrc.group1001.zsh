#!/usr/bin/env zsh

.zshrc-group1001-wrapper() {
  local dot_fname='.zshrc.group1001'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-zshrc-group1001() {
    .dot-reset-mtimes
    eval-quiet source ~/.zshrc.group1001
  }

  .tick-zshrc-group1001() { .tick -s '.zshrc.group1001' "$SHELL \$\$=$$ $@"; }
  .tick-start-line .tick-zshrc-group1001 $dot_fname

  .tick-zshrc-group1001 "\$0=$0"


  # Insert initialization here.
  .tick-zshrc-group1001 "... nothing to initialize in ~/$dot_fname"


  .dot-store-mtime ~/$dot_fname
  .tick-zshrc-group1001 "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.zshrc-group1001-wrapper && unset -f .zshrc-group1001-wrapper

