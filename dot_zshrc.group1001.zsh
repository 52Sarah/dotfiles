#!/usr/bin/env bash

.zshrc-group1001-wrapper() {
  local dot_fname='.zshrc.group1001'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-zshrc-group1001() {
    dot-reset-mtimes
    eval-quiet source ~/.zshrc.group1001
  }

  .tick-zshrc-group1001() { .tick -s '.zshrc.group1001' $@; }
  .tick-zshrc-group1001 "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/.zshrc.group1001)"

  .tick-zshrc-group1001 "\$0=$0 BASH_SOURCE=$BASH_SOURCE"

  safe-source ~/.sh_rc.group1001


  # Insert initialization here.


  dot-store-mtime ~/$dot_fname
  .tick-zshrc-group1001 "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]"
}
.zshrc-group1001-wrapper && unset -f .zshrc-group1001-wrapper

