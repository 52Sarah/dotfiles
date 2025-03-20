#!/usr/bin/env zsh

if [[ -z "$_DOT_SH_MTIMES" ]]; then
  typeset -A _DOT_SH_MTIMES 2>/dev/null || declare -a _DOT_SH_MTIMES
fi
if [[ -z "$_DOT_SH_MTIMES[sh_bootstrap_profile]" ]] || (( $(stat -L -f '%m' ~/.sh_bootstrap_profile) > _DOT_SH_MTIMES[sh_bootstrap_profile] )); then

  # At startup, Zsh reads, in order, from:
  #   1. ~/.zshenv
  #   2. ~/.zprofile for login shells
  #   3. ~/.zshrc for interactive shells
  #   4. ~/.zlogin for login shells
  # See: https://zsh.sourceforge.io/Doc/Release/Files.html

  [[ -e ~/.sh_bootstraprc ]] && source ~/.sh_bootstraprc

  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  # _TICK_x variables control its behavior; all default to false/0/off.
  # export _TICK_OFF= _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
  export _TICK_INDENT=
  is-defined .tick || safe-source ~/.tick.sh

  .tick-profile() { .tick -s ".sh_bootstrap_profile" $@; }
  .tick-profile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.sh_bootstrap_profile)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

  bootstrap-profile-wrapper() {
    .tick-profile "[START-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

    echo-error 'This space intentionally left blank.'

    .tick-profile "[END-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH])"
  }
  bootstrap-profile-wrapper

  .reload-bootstrap-profile() {
    unset "_DOT_SH_MTIMES[sh_bootstrap_profile]"
    eval-quiet source ~/.sh_bootstrap_profile
  }

  _DOT_SH_MTIMES+=(sh_bootstrap_profile "$(stat -L -f '%m' ~/.sh_bootstrap_profile)")
  .tick-profile "[END-FILE] (\$\$=$$), mtime=$_DOT_SH_MTIMES[sh_bootstrap_profile]" #, \$PATH=[$PATH])"
fi
