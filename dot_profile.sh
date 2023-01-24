#!/usr/bin/env bash

# For interactive/login shells, Bash reads, in order:
#   - ~/.bash_profile || ~/.bash_login || ~/.profile
#   - once it finds one it stops looking
# For non-interactive shells, Bash reads the $BASH_ENV file (usually ~/.bashrc).
#
# For any shells invoked as 'sh', Bash reads the $ENV file (usually ~/.profile).

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# TICK_x variables control its behavior; all default to false/0/off.
# export TICK_ENABLED= TICK_STDERR= TICK_STDOUT=
type -t .tick >&/dev/null || . ~/.tick.sh

.tick-profile() { .tick -s '.profile' "$@"; }


.tick-profile "[START-FILE] (\$\$=[$$], \$_=[$_], \$PATH=[$PATH])"

alias .reload-profile='qeval . ~/.profile'

.tick-profile "[END-FILE  ] (\$\$=[$$], \$_=[$_], \$PATH=[$PATH])"
