#!/usr/bin/env bash

# At startup, Bash reads from:
# 1. Login shells: first of [~/.bash_rcprofile, ~/.bash_rclogin, ~/.profile]
# 2. Interactive shells: ~/.bashrc
# 3. Non-interactive shells: $BASH_ENV (~/.bashrc)
# 4. Any shell invoked as 'sh': $ENV file (~/.profile)
# See: https://stackoverflow.com/a/18187389/160955

source ~/.sh_bootstrap

# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1

[[ -e ~/.bashrc ]] && source ~/.bashrc

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
is-command .tick || source ~/.tick.sh
.tick-bash-profile() { .tick -s '.bash_rcprofile' $@; }
.tick-bash-profile "[START-FILE] (\$\$=[$$], \$PATH=[$PATH], \$PS1=[$PS1])"


# Shell scripts executed with Bash will read this file.
export BASH_ENV=~/.bashrc

bash-profile-wrapper() {

  # Shell scripts executed with sh will read this file.
  export ENV=~/.profile

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'

}
bash-profile-wrapper $@

alias .reload-bash-profile='qeval source ~/.bash_rcprofile'
alias .rlbp='veval .reload-bash-profile'

.tick-bash-profile "[END-FILE] (\$\$=[$$], \$PATH=[$PATH])"
