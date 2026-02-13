#!/usr/bin/env bash

.bashrc-group1001-wrapper() {
  local dot_fname='.bashrc.group1001'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-bashrc-group1001() {
    .dot-reset-mtimes
    eval-quiet source ~/.bashrc.group1001
  }

  .tick-bashrc-group1001() { .tick -s '.bashrc.group1001' $@; }
  .tick-bashrc-group1001 "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/.bashrc.group1001), \$SHELL=$SHELL"

  .tick-bashrc-group1001 "\$0=$0 BASH_SOURCE=$BASH_SOURCE)"

  safe-source ~/.sh_rc.group1001


  # Insert initialization here.


  .dot-store-mtime ~/$dot_fname

  .tick-bashrc-group1001 "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]"
}
.bashrc-group1001-wrapper && unset -f .bashrc-group1001-wrapper

