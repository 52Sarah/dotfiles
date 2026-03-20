#!/usr/bin/env bash

# At startup, Bash reads from:
#   * login shells: first of ~/.bash_profile, ~/.bash_login, ~/.profile
#   * interactive shells: ~/.bashrc
#   * non-interactive shells: $BASH_ENV (set here to ~/.bashrc)
#   * shells invoked as 'sh':
#     - login shells: ~/.profile
#     - interactive shells: $ENV file (set here to ~/.profile)
# See: https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html

source ~/.sh_bootstrap

.bash-profile-wrapper() {
  local dot_fname='.bash_profile'

  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-bash-profile() {
    .dot-reset-mtimes
    eval-quiet . ~/.bash_profile
  }

  .tick-bash-profile() { .tick -s ".bash_profile" "\$\$=$$ $@"; }
  .tick-bash-profile "[START-FILE] \$SHELL=$SHELL, \$PPID=$PPID, mtime=$(file-mtime ~/$dot_fname)"

  .tick-and-source .tick-bash-profile ~/.sh_profile

  # A non-interactive login shell requires the interactive environment setup.
  .tick-and-source .tick-bash-profile ~/.bashrc


  # Don't show the 'zsh is the default shell' message.
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # Shell scripts executed with Bash will read this file.
  export BASH_ENV=~/.bashrc

  # Shell scripts executed with sh will read this file.
  export ENV=~/.bash_profile

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'

  # Set prompt: . ~/pwd $
  export PS1=' \w \$ '

  #
  ### ITERM shell integration and prompt/display helpers
  #
  if [[ ! -f "$HOME/.iterm2_shell_integration.bash" ]]; then
    .tick-bash-profile '[skip] ~/iterm2: no iterm2_shell_integration.bash file to read'
  else
    .tick-and-source .tick-bash-profile ~/.iterm2_shell_integration.zsh
    export ITERM_BADGE="$ITERM_PROFILE"
    iterm2_print_user_vars() {
      iterm2_set_user_var badge "$ITERM_BADGE"
    }
    # From https://superuser.com/a/344397/17666
    # Note that tab and window take effect imediately; badge needs to wait for a prompt display
    iterm-text() {
      local USAGE="usage: iterm-text ${ITERM_BADGE:+--badge|}--tab|--window TEXT..."
      local mode= do_tab= do_window= do_badge= obj="tab and window"
      while [[ "$1" ]]; do case "$1" in
        -t|--tab)   do_tab=1; shift 1;;
        -w|--win*)  do_window=1; shift 1;;
        -b|--badge) do_badge=1; shift 1;;
        -*) echo-error "iterm-text: illegal option -- $1"
            echo-error $USAGE
            return 1;;
        *) break;;
      esac; done
      [[ -z "$do_tab$do_window$do_badge" ]] && do_tab=1 do_window=1 do_badge=${+ITERM_BADGE}
      local text="$@"
      [[ -z "$text" ]] && echo-error "$USAGE" && return 1

      ((do_tab))    && echo -ne "\e]1;$text\a"    && echo-verbose "Updated iTerm tab title to: $text"
      ((do_window)) && echo -ne "\e]2;$text\a"    && echo-verbose "Updated iTerm window title to: $text"
      ((do_badge))  && export ITERM_BADGE="$text" && echo-verbose "Updating iTerm badge to: $text"
    }
    alias itt='iterm-text'
  fi

  # Zsh supports early (profile) and late (login) scripts; emulate this for Bash by calling agnostic login script.
  .tick-and-source .tick-bash-profile ~/.sh_login


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-bash-profile "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.bash-profile-wrapper && unset -f .bash-profile-wrapper
