#!/usr/bin/env bash

# All "shell settings" and options are placed here, to ba called by .bash_profile
# (or possible .bashrc).

# Simple login file debugging.
type -t .tick >& /dev/null || . ~/.tick
if .do_tick ".bash_settings.$USER"; then
  .tick_bsu() { .tick ".bash_settings.$USER" $@; }
  .tickeval_bsu() { .tickeval ".bash_settings.$USER" $@; }
  .tickvars_bsu() { .tickvars ".bash_settings.$USER" $@; }
else
  .tick_bsu() { :; }
  .tickeval_bsu() { :; }
  .tickvars_bsu() { :; }
fi
.tick_bsu "[START-FILE] .bash_settings.$USER"


.bash_settings_user() {
  .tickeval_bsu 'printf "[start] .bash_settings_user (%d variables)\n" "$(env | egrep '^[A-Za-z_.-].*' | wc -l)"'

  export EDITOR=vim
  export CLICOLOR=1

  # Uncomment to color output even when being piped.
  # Turning this on has an adverse interaction with a few tools.
  export CLICOLOR_FORCE=1

  # See: https://ss64.com/bash/less.html
  # -#, --shift               Percent of screen to scroll right and left for wide files
  # -A, --SEARCH-SKIP-SCREEN  Search just after current line, not visible page
  # -F, --quit-if-one-screen  Do not display prompt for short files
  # -g, --hilite-search       Only hilite one search result
  # -i, --ignore-case         Ignore case unless pattern contains uppercase letters
  # -J, --status-column       Displays column at left for search matches
  # -m, --long-prompt         Prompts like 'more'; -M even more verbose
  # -n, --line-numbers        Suppress line numbers in prompt
  # -N, --LINE-NUMBERS        Show line numbers at start of each line
  # -q, --quit-at-eof         Exit second time at eof, not just with 'q'; -Q quits first time
  # -r, --raw-control-chars   Render all escape sequences properly; -R renders only colors
  # -s, --squeeze-blank-lines Consecutive blank lines shown as one
  # -S, --chop-long-lines     Truncate long lines, do not wrap
  # -w, --hilite-unread       Highlight "new" line after 1+ pages forward movement; -W after any 1+ lines
  # -X, --no-init             Do not clear screen when loading
  export LESS='--shift=.33 --SEARCH-SKIP --quit-if-one --status-col --LONG-PR --quit-at-eof --raw --squeeze --HILITE-UNREAD --no-init'
  export LESSEDIT='subl --new-window --wait --stay %f\:%lm'


  # Ignore repeated lines and lines starting with ' '
  export HISTCONTROL=ignoreboth
  export HISTSIZE=100000
  export HISTFILESIZE=$HISTSIZE
  # export HISTTIMEFORMAT='%F %T   '
  export HISTTIMEFORMAT='%m/%d %H:%M  '

  # Exclude from tab completion
  export FIGNORE='DS_Store:Icon?'

  export SUBLIME_LIB="$HOME/Library/Application Support/Sublime Text 3"

  export CCHH_HOME="$HOME/cchh"

  .tickvars_bsu EDITOR ${!CLICOLOR*} ${!LESS*} ${!HIST*} FIGNORE SUBLIME_LIB CCHH_HOME

  alias .reload-bash-settings-user=". ~/.bash_settings.$USER"
  alias .rlbsu='.reload-bash-settings-user'

  .tickeval_bsu 'printf "[finish] .bash_settings_user (%d variables)\n" "$(env | egrep '^[A-Za-z_.-].*' | wc -l)"'
}
.bash_settings_user $* && unset -f .bash_settings_user


.tick_bsu "[FINISH-FILE] .bash_settings.$USER"
