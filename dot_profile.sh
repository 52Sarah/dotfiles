#!/usr/bin/env bash

# For interactive/login shells, Bash reads, in order:
#   - ~/.bash_profile || ~/.bash_login || ~/.profile
#   - once it finds one it stops looking
# For non-interactive shells, Bash reads the $BASH_ENV file (usually ~/.bashrc).
#
# For any shells invoked as 'sh', Bash reads the $ENV file (usually ~/.profile).

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
type -t .tick >&/dev/null || . ~/.tick.sh
.tick_profile() { .tick ".profile" "$@"; }
# export TICK_STDERR= TICK_STDOUT= TICK_INDENT=

.tick_profile "[START-FILE ] ~/.profile (\$\$=$$, \$_=$_)"

.profile_wrapper() {
  .tick_profile "[start ] .profile_wrapper (\$\$=$$, \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$-, \$_=$_)"
  
  alias .reload-profile='. ~/.profile'
  alias .rlp=.reload-profile

  .tick_profile "[finish] .profile_wrapper (\$\$=$$, \$_=$_)"
}
.profile_wrapper


.tick_profile "[FINISH-FILE] ~/.profile (\$\$=$$, \$_=$_)"
