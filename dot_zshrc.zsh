#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells; should only include late-init items
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

.zshrc-wrapper() {
  local dot_fname='.zshrc'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-zshrc() {
    dot-reset-mtimes
    eval-quiet source ~/.zshrc
  }
  alias .rlzrc='eval-verbose .reload-zshrc'

  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zshrc)" #, \$PATH=[$PATH]"

  safe-source ~/.sh_rc

  #
  ### ITERM shell integration and prompt/display helpers
  #
  if [[ ! -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
    .tick-zshrc ' ... ~/iterm2: no iterm2_shell_integration.zsh file to read'
  else
    source "$HOME/.iterm2_shell_integration.zsh"
    .tick-zshrc ' ... ~/iterm2: read iterm2_shell_integration.zsh file'
  fi


  # Insert additional .zprofile handling here.

  #
  ### GROUP 1001 SPECIFIC
  #
  ONYX_SETUP=$HOME/Workspace/onyx-jvm/scripts/env/setup-onyx.zshrc
  if [[ -n "$ONYX_ENV" ]]; then
    .tick-zshrc " ... skipping setup-onyx.zshrc, ONYX_ENV already defined"
  elif [[ ! -f "" ]]; then
    .tick-zshrc " ... skipping setup-onyx.zshrc, file not found: $ONYX_SETUP"
    export ONYX_ENV='ci'
  else
    .tick-zshrc " ... reading setup-onyx.zshrc"
    source $ONYX_SETUP
  fi
  .tick-zshrc " ... ONYX_ENV=$ONYX_ENV"

  # from onyx-jcm/docs/setup.sh
  export ONYX_ENV_HOME=$HOME/.onyx-env
  export ONYX_ENV_DIR=$ONYX_ENV_HOME
  export CERT_FILE=$ONYX_ENV_HOME/onyx-truststore.pem
  .tick-zshrc " ... ONYX_ENV_HOME=$ONYX_ENV_HOME"
  .tick-zshrc " ... CERT_FILE=$CERT_FILE"
  export NODE_EXTRA_CA_CERTS=$CERT_FILE
  export SSL_CERT_FILE=$CERT_FILE
  export REQUESTS_CA_BUNDLE=$CERT_FILE
  export HTTPLIB2_CA_CERTS=$CERT_FILE

  # from onyx-jvm/scripts/env/setup-local-user-env.sh
  export ONYX_SANDBOX=$USER
  export PIPELINE=${CI:-${GITLAB_CI:-"false"}}
  .tick-zshrc " ... ONYX_SANDBOX=$ONYX_SANDBOX"
  .tick-zshrc " ... PIPELINE=$PIPELINE, CI=$CI, GITLAB_CI=$GITLAB_CI"

  [[ -z "$POSTGRES_IP" ]] && export POSTGRES_IP='localhost'
  [[ -z "$POSTGRES_USER" ]] && export POSTGRES_USER="admin"
  [[ -z "$POSTGRES_SCHEMA" ]] && export POSTGRES_SCHEMA='ci'
  .tick-zshrc " ... POSTGRES_IP=$POSTGRES_IP, POSTGRES_USER=$POSTGRES_USER, POSTGRES_SCHEMA=$POSTGRES_SCHEMA"
  [[ -z "$POSTGRES_DATABASE" ]] && export POSTGRES_DATABASE='postgres'
  # export TMP_LOCAL=$ONYX_ENV_HOME/${ONYX_ENV}-local-keys.sec

  # TODO: hopefully temporary until I out why the install fails
  # brew install --cask google-cloud-sdk is failing and not adding bin to cli
  path-append "$HOMEBREW_PREFIX/share/google-cloud-sdk/bin"
  .tick-zshrc " ... HOMEBREW_PREFIX=$HOMEBREW_PREFIX"


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
.zshrc-wrapper && unset -f .zshrc-wrapper
