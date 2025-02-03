#!/usr/bin/env bash

# At startup, Bash reads from:
# - Login shells: first of [~/.bash_profile, ~/.bash_login, ~/.profile]
# - Interactive shells: ~/.bashrc
# - Non-interactive shells: $BASH_ENV (~/.bashrc)
# - Any shell invoked as 'sh': $ENV file (~/.profile)
# See: https://stackoverflow.com/a/18187389/160955

# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1

[[ -e ~/.sh_bootstrap_profile ]] && source ~/.sh_bootstrap_profile

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# _TICK_x variables control its behavior; all default to false/0/off.
# export _TICK_OFF= _TICK_ON=
# export _TICK_STDERR= _TICK_STDOUT=
.tick-bash-profile() { .tick -s '.bash_profile' $@; }
.tick-bash-profile "[START-FILE] (\$\$=[$$], \$PATH=[$PATH], \$PS1=[$PS1])"

# Shell scripts executed with Bash will read this file.
export BASH_ENV=~/.bashrc
[[ -e ~/.bashrc ]] && . ~/.bashrc

bash-profile-wrapper() {

  # Shell scripts executed with sh will read this file.
  export ENV=~/.profile

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'

}
bash-profile-wrapper $@

alias .reload-bash-profile='qeval . "~/.bash_profile"'
alias .rlbp='veval .reload-bash-profile'

.tick-bash-profile "[END-FILE] (\$\$=[$$], \$PATH=[$PATH])"
