#!/usr/bin/env bash
#
# shellcheck disable=1090,2009,2015,2154,2155
#
# SublimeLinter/ShellCheck excluded issues; see https://github.com/koalaman/shellcheck/wiki/Ignore
# - 1090 (https://github.com/koalaman/shellcheck/wiki/SC1090): Can't follow non-constant source.
#        Use a 'source' directive to specify location.
# - 2009 (https://github.com/koalaman/shellcheck/wiki/SC2009): Consider using pgrep instead of
#        grepping ps output.
# - 2015 (https://github.com/koalaman/shellcheck/wiki/SC2015): Note that A && B || C is not
#        if-then-else. C may run when A is true.
# - 2154 (https://github.com/koalaman/shellcheck/wiki/SC2154): var is referenced but not assigned.
# - 2155 (https://github.com/koalaman/shellcheck/wiki/SC2155): Declare and assign separately to
#        avoid masking return values.

# Bash reads .bash_profile || .bash_login || .profile, whichever it finds first,
# for interactive shells. Since there's nothing bash-specific in .profile (as far as I know),
# I will put all non-interactive-ish commands into .bashrc (called by non-interactive shells) and
# have it sourced by .bash_profile.
#
# https://apple.stackexchange.com/a/13019/39935


. "$HOME/.__login.debug.sh" ".profile" || __echo() { :; }
__echo "-------------------"
__echo "[.profile] starting; pid: $$, ppid: $PPID, -='$-', SHLVL=$SHLVL, PS1='$PS1'"


#
# This space intentionally left blank.
#


__echo "[.profile] sourcing .bashrc"
. "$HOME/.bashrc"


__echo "[.profile] finished"
