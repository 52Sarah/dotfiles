#!/usr/bin/env bash

.bashrc-group1001-wrapper() {
  local dot_fname='.bashrc.group1001'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-bashrc-group1001() {
    .dot-reset-mtimes
    eval-quiet source ~/.bashrc.group1001
  }

  .tick-bashrc-group1001() { .tick -s '.bashrc.group1001' "$SHELL \$\$=$$ $@"; }
  .tick-start-line .tick-bashrc-group1001 $dot_fname

  .tick-bashrc-group1001 "\$0=$0 BASH_SOURCE=$BASH_SOURCE)"


  # Insert initialization here.
  .tick-bashrc-group1001 "... nothing to initialize in ~/$dot_fname"

  .dot-store-mtime ~/$dot_fname

  .tick-bashrc-group1001 "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.bashrc-group1001-wrapper && unset -f .bashrc-group1001-wrapper

