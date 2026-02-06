#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

zlogin-wrapper() {
  local dot_fname='.zlogin'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-zlogin() {
    plugins=()
    unset "_DOT_MTIMES[.zlogin]"
    eval-quiet . ~/.zlogin
  }
  alias .rlzl='eval-verbose .reload-zlogin'

  is-command .tick || source ~/.tick.sh
  .tick-zlogin() { .tick -s ".zlogin" $@; }
  .tick-zlogin "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' $HOME/.zlogin)"

  safe-source ~/.sh_login


  # Shell scripts executed with sh will read this file.
  export ENV=~/.zlogin

  ### START: Zsh-specific settings [mostly from zshrc.zsh-template]
  #
  zstyle ':omz:update' mode auto
  zstyle ':omz:update' verbosity minimal

  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
  ZSH_THEME=robbyrussell

  CASE_SENSITIVE=false
  HYPHEN_SENSITIVE=true
  ENABLE_CORRECTION=true
  COMPLETION_WAITING_DOTS="%F{white}waiting...%f"
  DISABLE_UNTRACKED_FILES_DIRTY=true
  HIST_STAMPS="%m/%d %H:%M:%S"

  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
  # plugins+=(alias-finder)
  plugins+=(asdf)
  plugins+=(autojump)
  plugins+=(colored-man-pages)
  plugins+=(gh)
  plugins+=(git-prompt)
  plugins+=(pipenv)
  plugins+=(vi-mode)
  
  # See: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/vi-mode/README.md
  VI_MODE_SET_CURSOR=true
  # VI_MODE_CURSOR_VISUAL=5 # blinking line
  # VI_MODE_CURSOR_INSERT=5 # blinking line

  if [[ -e "$HOME/.oh-my-zsh" ]]; then
    .tick-zlogin "... loading oh-my-zsh, plugins=[$plugins]"
    export ZSH="$HOME/.oh-my-zsh"
    source "$ZSH/oh-my-zsh.sh"
    .tick-zlogin "... loaded oh-my-zsh, ZSH=$ZSH, plugins=[$plugins]"
  else
    .tick-zlogin "... not loading oh-my-zsh, not present in $HOME/.oh-my-zsh"
  fi
  
  ZSH_THEME_GIT_PROMPT_PREFIX='('
  ZSH_THEME_GIT_PROMPT_SUFFIX=')'
  ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
  # ZSH_THEME_GIT_SHOW_UPSTREAM=1
  # ZSH_THEME_GIT_PROMPT_UPSTREAM_SEPARATOR="%{$reset_color%}|%{$fg[cyan]%}"
  #
  ### FINISH: Zsh-specific settings from zshrc.zsh-template

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

  # Initialize zsh completion system
  fpath+=~/.zfunc; autoload -Uz compinit; compinit
  zstyle ':completion:*' menu select

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


  #
  ### pipenv
  #
  if [[ -e ~/.local ]]; then
    path-prepend "$HOME/.local/bin"
    .tick-zlogin '... prepended ~/.local/bin to PATH'
  else
    .tick-zlogin '... no ~/.local/bin to add to PATH'
  fi
  #
  if is-command pipenv; then
    export PIPENV_SHELL=/bin/zsh
    # eval "$(_PIPENV_COMPLETE=zsh_source pipenv)"
    .tick-zlogin '... initialized pipenv'
  else
    .tick-zlogin '... pipenv is not installed'
  fi

  #
  ### rancher desktop
  #
  if [[ -e ~/.rd/bin ]]; then
    path-prepend "$HOME/.rd/bin"
    .tick-zlogin '... prepended ~/.rd/bin to PATH'
  else
    .tick-zlogin '... no ~/.rd/bin to add to PATH'
  fi


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-zlogin "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
zlogin-wrapper $@
unset -f zlogin-wrapper .tick-zlogin
