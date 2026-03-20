#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

.zprofile-wrapper() {
  local dot_fname='.zprofile'

  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-zprofile() {
    .dot-reset-mtimes
    eval-quiet source ~/.zprofile
  }

  .tick-zprofile() { .tick -s ".zprofile" "\$\$=$$ $@"; }
  .tick-zprofile "[START-FILE] \$SHELL=$SHELL, \$PPID=$PPID, mtime=$(file-mtime ~/$dot_fname)"

  .tick-and-source .tick-zprofile ~/.sh_profile


  #
  ### OH-MY-ZSH
  # Initialized here in ~/.zprofile (early) since some of the plugins (e.g., gcloud) 
  # impact PATH and other settings that ~/.zshrc and ~/.zlogin depend on.
  #
  if ((_DOT_SKIP_OHMYZSH_SETUP)); then
    .tick-zprofile "[skip] Oh My Zsh: _DOT_SKIP_OHMYZSH_SETUP"
  elif [[ ! -e "$HOME/.oh-my-zsh" ]]; then
    .tick-zprofile "[skip] Oh My Zsh: no ~/.oh-my-zsh directory found"
  else
    .setup-oh-my-zsh() {
      .tick-zprofile "[start] .setup-oh-my-zsh"
      
      export ZSH="$HOME/.oh-my-zsh"
      plugins=()

      zstyle ':omz:update' mode auto
      zstyle ':omz:update' verbosity minimal

      # Initialize zsh completion system
      export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
      [[ -d ~/.zfunc ]] && export FPATH="$FPATH:~/.zfunc"
      zstyle ':completion:*' menu select
  
      # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
      ZSH_THEME=robbyrussell

      CASE_SENSITIVE=false
      HYPHEN_SENSITIVE=true
      ENABLE_CORRECTION=true
      COMPLETION_WAITING_DOTS="%F{white}waiting...%f"
      DISABLE_UNTRACKED_FILES_DIRTY=true
      HIST_STAMPS="%m/%d %H:%M:%S"

      # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
      plugins+=(colored-man-pages)
      # plugins+=(dotenv)
      plugins+=(gcloud)
      plugins+=(git-extras)
      plugins+=(git-prompt)
      # plugins+=(iterm2)
      plugins+=(vi-mode)
      
      .tick-and-source .tick-zprofile "$ZSH/oh-my-zsh.sh"
      
      # See: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/vi-mode
      VI_MODE_SET_CURSOR=true

      # See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-prompt
      ZSH_THEME_GIT_PROMPT_PREFIX='('
      ZSH_THEME_GIT_PROMPT_SUFFIX=')'
      ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
      # ZSH_THEME_GIT_SHOW_UPSTREAM=1
      # ZSH_THEME_GIT_PROMPT_UPSTREAM_SEPARATOR="%{$reset_color%}|%{$fg[cyan]%}"

      .tick-zprofile "[end] .setup-oh-my-zsh, plugins=$plugins"
    }
    .setup-oh-my-zsh
  fi

  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-zprofile "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.zprofile-wrapper && unset -f .zprofile-wrapper
