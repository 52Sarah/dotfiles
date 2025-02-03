#!/usr/bin/env zsh

# if [[ -z "$_DOT_ZPROFILE_MTIME" ]] || (( $(stat -L -f '%m' ~/.zprofile) > _DOT_ZPROFILE_MTIME )); then

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -e ~/.sh_bootstrap_profile ]] && source ~/.sh_bootstrap_profile

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# _TICK_x variables control its behavior; all default to false/0/off.
# export _TICK_OFF= _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
.tick-zprofile() { .tick -s '.zprofile' $@; }
.tick-zprofile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zprofile)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

[[ -e ~/.zshrc ]] && . ~/.zshrc

zprofile-wrapper() {

  .tick-zprofile "[START-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

  # Shell scripts executed with sh will read this file.
  export ENV=~/.zprofile

  ### START: Zsh-specific settings [mostly from zshrc.zsh-template]
  #
  export ZSH="$HOME/.oh-my-zsh"

  zstyle ':omz:update' mode auto      

  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
  ZSH_THEME=eastwood

  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
  plugins+=(alias-finder)
  plugins+=(asdf)
  plugins+=(git-prompt)
  plugins+=(mvn)
  plugins+=(npm)
  plugins+=(ssh)
  plugins+=(sublime)
  .tick-zshrc "... loaded zsh plugins: $plugins"
  #
  source $ZSH/oh-my-zsh.sh
  #
  ### FINISH: Zsh-specific settings from zshrc.zsh-template

  bindkey -v

  export CASE_SENSITIVE="true"
  export ENABLE_CORRECTION="true"
  export COMPLETION_WAITING_DOTS="%F{white}waiting...%f"

  # See: https://stackoverflow.com/questions/4405382/how-can-i-read-documentation-about-built-in-zsh-commands
  unalias run-help 2>/dev/null
  autoload run-help
  export HELPDIR=/usr/share/zsh/5.9/help
  unalias man 2>/dev/null
  man() {
    command man $@ && return 0
    echo-verbose "Trying run-help..."
    run-help $@
  }

  ### Login Zsh options
  #
  # ## changing directories
  setopt AUTO_CD        # if command is not defined, try to cd instead
  setopt AUTO_PUSHD     # cd pushes onto stack
  setopt PUSHD_IGNORE_DUPS
  setopt PUSHD_MINUS    # more intuitive +/- when moving to stack by position
  #
  # ## completion
  setopt ALWAYS_TO_END    # move cursor to end of word after any completion
  setopt COMPLETE_IN_WORD # complete from both ends of word
  #
  # ## history
  setopt NO__BANG_HIST        # do not perform ! history expansion
  setopt EXTENDED_HISTORY     # save timestamp and duration seconds to history file
  setopt HIST_EXPIRE_DUPS_FIRST
  setopt HIST_IGNORE_DUPS     # ignore subsequent identical lines
  setopt HIST_IGNORE_SPACE    # ignore lines beginning with space
  setopt HIST_VERIFY          # load line into buffer, do not execute immediately
  setopt SHARE_HISTORY
  #
  # ## input/output
  setopt CORRECT_ALL          # try to correct spelling of entire line
  setopt INTERACTIVE_COMMENTS # allow comments in interactive shells
  #
  # ## prompting
  setopt PROMPT_SUBST   # expansion and substitution are performed in prompts

}
zprofile-wrapper

alias .reload-zprofile='qeval . ~/.zprofile'
alias .rlzp='veval .reload-zprofile'

export _DOT_ZPROFILE_MTIME="$(stat -L -f '%m' ~/.zprofile)"
.tick-zprofile "[END-FILE] (\$\$=$$), mtime=$_DOT_ZPROFILE_MTIME" #, \$PATH=[$PATH])"

# fi