#!/usr/bin/env zsh

# if [[ -z "$_DOT_ZSHRC_MTIME" ]] || (( $(stat -L -f '%m' ~/.zshrc) > _DOT_ZSHRC_MTIME )); then

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -e ~/.sh_bootstrap ]] && source ~/.sh_bootstrap

zshrc-wrapper() {


  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  # _TICK_x variables control its behavior; all default to false/0/off.
  # export _TICK_OFF= _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
  is-defined .tick || . ~/.tick.sh
  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zshrc)" #, \$PATH=[$PATH]"


  # Private env vars, etc. can be in the optional file ~/.secrets.
  if [[ -e ~/.secrets ]]; then
    source ~/.secrets
    .tick-zshrc '... read ~/.secrets'
  fi

  # Put my homemade scripts and other miscellany here at the start of the classpath.
  if ! matches "$PATH" "$HOME/bin(:|$)"; then
    path-prepend "$HOME/bin"
    .tick-zshrc '... prepended $HOME/bin to PATH'
  fi

  ### START: Zsh-specific settings from zshrc.zsh-template
  #
  export ZSH="$HOME/.oh-my-zsh"

  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
  ZSH_THEME=eastwood

  # Uncomment the following line if pasting URLs and other text is messed up.
  # DISABLE_MAGIC_FUNCTIONS="true"

  zstyle ':omz:update' mode auto      

  # Uncomment the following line if you want to disable marking untracked files
  # under VCS as dirty. This makes repository status check for large repositories
  # much, much faster.
  # DISABLE_UNTRACKED_FILES_DIRTY="true"

  # Uncomment the following line if you want to change the command execution time
  # stamp shown in the history command output.
  # You can set one of the optional three formats:
  # "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
  # or set a custom format using the strftime function format specifications,
  # see 'man strftime' for details.
  # HIST_STAMPS="mm/dd/yyyy"

  # Would you like to use another custom folder than $ZSH/custom?
  # ZSH_CUSTOM=/path/to/new-custom-folder

  # Standard plugins can be found in $ZSH/plugins/
  # Custom plugins may be added to $ZSH_CUSTOM/plugins/
  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
  plugins=(asdf)
  # plugins+=(ssh git git-prompt)
  # plugins+=(macos)
  # plugins+=(colored-man-pages)
  # plugins+=(sublime)
  # plugins+=(mvn)
  .tick-zshrc "... loaded zsh plugins: $plugins"

  # aws docker jira kubectl kubectx
  # brew alias-finder common-aliases command-not-found history-substring-search systemd
  # jsontools
  # lpass
  # vscode
  # node nvm pip yarn
  # react-native

  source $ZSH/oh-my-zsh.sh

  # Compilation flags
  # export ARCHFLAGS="-arch $(uname -m)"

  # Set personal aliases, overriding those provided by Oh My Zsh libs,
  # plugins, and themes. Aliases can be placed here, though Oh My Zsh
  # users are encouraged to define aliases within a top-level file in
  # the $ZSH_CUSTOM folder, with .zsh extension. Examples:
  # - $ZSH_CUSTOM/aliases.zsh
  # - $ZSH_CUSTOM/macos.zsh
  
  #
  ### FINISH: Zsh-specific settings from zshrc.zsh-template

  #
  ### Interactive shell options.
  #
  # ## expansion and globbing
  setopt EXTENDED_GLOB
  # setopt BAD_PATTERN  # print error msg for bad glob pattern
  # setopt CASE_GLOB    # glob case-sensitive
  # setopt CASE_MATCH   # regex case-sensitive
  # setopt CASE_PATHS   # paths case-sensitive
  # setopt GLOB         # perform globbing
  # setopt GLOB_SUBST   # enable globbing after parameter substitution
  # setopt NO__MATCH    # if glob has no matches, error
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


  export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
  export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
  _QUIET=1 safe-source $HOME/configure_nexus_npm_token.sh

  #
  ### PWR-JUMPER
  #
  source $HOME/.pwrfunc.sh

  .tick-zshrc "[END-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH])"
}
zshrc-wrapper $@

alias .reload-zshrc='qeval . ~/.zshrc'
alias .rlzrc='qeval .reload-zshrc'

export _DOT_ZSHRC_MTIME="$(stat -L -f '%m' ~/.zshrc)"
.tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_ZSHRC_MTIME" #, \$PATH=[$PATH])"

# fi