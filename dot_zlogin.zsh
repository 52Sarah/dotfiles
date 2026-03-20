#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

.zlogin-wrapper() {
  local dot_fname='.zlogin'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-zlogin() {
    plugins=()
    .dot-reset-mtimes
    eval-quiet . ~/.zlogin
  }

  .tick-zlogin() { .tick -s ".zlogin" "\$\$=$$ $@"; }
  .tick-zlogin "[START-FILE] \$SHELL=$SHELL, \$PPID=$PPID, mtime=$(file-mtime ~/$dot_fname)"

  # A non-interactive login shell requires the interactive environment setup.
  .tick-and-source .tick-zlogin ~/.zshrc

  .tick-and-source .tick-zlogin ~/.sh_login


  # Shell scripts executed with sh will read this file.
  export ENV=~/.zlogin

  # iTerm2 shell integration
  .tick-and-source .tick-zlogin ~/.iterm2_shell_integration.zsh
  
  ### See: https://zsh.sourceforge.io/Doc/Release/Options.html
  #
  # ## changing directories
  setopt AUTO_CD        # if command is not defined, try to cd instead
  setopt AUTO_PUSHD     # cd pushes onto stack
  setopt PUSHD_IGNORE_DUPS
  setopt PUSHD_MINUS    # more intuitive +/- when moving to stack by position
  #
  # ## completion
  setopt ALWAYS_TO_END    # move cursor to end of word after any completion
  setopt no__BEEP
  setopt no__LIST_BEEP
  setopt COMPLETE_IN_WORD # complete from both ends of word
  #
  # ## expansion and globbing
  setopt EXTENDED_GLOB
  # setopt BAD_PATTERN  # print error msg for bad glob pattern
  # setopt CASE_GLOB    # glob case-sensitive
  # setopt CASE_MATCH   # regex case-sensitive
  # setopt CASE_PATHS   # paths case-sensitive
  # setopt GLOB         # perform globbing
  setopt GLOB_DOTS      # complete dotfiles
  # setopt GLOB_SUBST   # enable globbing after parameter substitution
  setopt no__NOMATCH    # if glob has no matches, error
  #
  # ## input/output
  setopt PATH_SCRIPT          # check current directory for script, then command path
  #
  # ## job control
  setopt LONG_LIST_JOBS
  # setopt MONITOR      # allow job control
  #
  # ## functions
  # setopt WARN_CREATE_GLOBAL   # warn if global parameter created in function
  # setopt WARN_NESTED_VAR      # warn if enclosing function parameter is set
  #
  # ## history
  setopt no__BANG_HIST        # do not perform ! history expansion
  setopt EXTENDED_HISTORY     # save timestamp and duration seconds to history file
  setopt HIST_EXPIRE_DUPS_FIRST
  setopt HIST_IGNORE_DUPS     # ignore subsequent identical lines
  setopt HIST_IGNORE_SPACE    # ignore lines beginning with space
  setopt HIST_VERIFY          # load line into buffer, do not execute immediately
  setopt SHARE_HISTORY
  #
  # ## input/output
  setopt CORRECT              # try to correct only command
  setopt no__CORRECT_ALL      # try to correct spelling of entire line
  setopt INTERACTIVE_COMMENTS # allow comments in interactive shells
  #
  # ## prompting
  setopt PROMPT_SUBST         # expansion and substitution are performed in prompts

  # use vi-style history editing
  bindkey -v

  # See: https://stackoverflow.com/questions/4405382/how-can-i-read-documentation-about-built-in-zsh-commands
  unalias run-help 2>/dev/null
  autoload run-help
  export HELPDIR=/usr/share/zsh/5.9/help

  # See: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Prompt-Expansion
  # Use: green ./red ! based on $?; PWD (~ as $HOME); $
  export PROMPT="%0(?:%B%F{green}.%f%b:%B%F{red}!%f%b) %~ \$ "

  # Global aliases, used anywhere on command line
  alias -g H='| head'
  alias -g T='| tail'
  alias -g L='| less'
  alias -g G='| egrep'
  alias -g NOUT='>& /dev/null'
  alias -g NERR='2> /dev/null'


  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-zlogin "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.zlogin-wrapper && unset -f .zlogin-wrapper
