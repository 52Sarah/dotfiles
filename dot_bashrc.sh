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

.bashrc-wrapper() {
  local dot_fname='.bashrc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-bashrc() {
    .dot-reset-mtimes
    eval-quiet source ~/.bashrc
  }
  alias .rlbrc='eval-verbose .reload-bashrc'

  .tick-bashrc() { .tick -s '.bashrc' $@; }
  .tick-bashrc "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/.bashrc), \$SHELL=$SHELL"

  # Local overrides might be in ~.zshenv; since Bash has no equivalent, read that file here too.
  if [[ ! -f ~/.zshenv ]]; then
    .tick-bashrc '... no ~/.zshenv file to read'
  else
    source ~/.zshenv
    .tick-bashrc '... read ~/.zshenv file'
  fi

  safe-source ~/.sh_rc


  #
  ### ITERM shell integration and prompt/display helpers
  #
  if [[ ! -f "$HOME/.iterm2_shell_integration.bash" ]]; then
    .tick-bashrc '[skip] ~/iterm2: no iterm2_shell_integration.zsh file to read'
  elif [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
    .tick-bashrc "[skip] iTerm2 not default terminal program"
  else
    .tick-bashrc ' ... loading iTerm2 bash shell integration'
    source "$HOME/.iterm2_shell_integration.bash"
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


  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-bashrc "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
.bashrc-wrapper && unset -f .bashrc-wrapper .tick-bashrc
