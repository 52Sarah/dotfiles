#!/usr/bin/env zsh

.tick-zshrc-pwr() { .tick -s '.zshrc.pwr' $@; }

.tick-zshrc-pwr "[START-FILE] (\$\$=[$$])"

zshrc-pwr-wrapper() {

  #
  ### cd/directory helpers
  #
  export WORKSPACE_DIR="$HOME/Workspace"
  cd-workspace() { 
    if [[ -z "$1" ]]; then
      qeval cd "$WORKSPACE_DIR"
    else
      local dir_prefix="$1"; (($#@)) && shift 1
      ends_with "$dir_prefix" "\*" || dir_prefix="${dir_prefix}*"
      qeval cd $WORKSPACE_DIR/${dir_prefix}
    fi
  }
  cd-profile() { 
    [[ -z "$ITERM_PROFILE" || "$ITERM_PROFILE" = 'Default' ]] && cd-workspace && return 1
    eval-quiet cd "$WORKSPACE_DIR/$ITERM_PROFILE"
  }
  alias cdw='cd-workspace'
  alias cdp='cd-profile'


  export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
  export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

  .tick-zshrc-pwr '[start] initializing nexus_npm_token'
  _QUIET=1 safe-source $HOME/.configure_nexus_npm_token.sh
  .tick-zshrc-pwr '[end] nexus_npm_token'
  #
  ### RANCHER DESKTOP, DOCKER
  #
  path-prepend ~/.rd/bin
  #
  alias docker-start-pg-local='qeval docker run --detach --rm --publish 5432:4432 --name pg_local -e POSTGRES_PASSWORD=password postgres:14.15'
  alias docker-stop-pg-local='qeval docker stop pg_local'

  #
  ### PWR JUMPER
  #
  .tick-zshrc-pwr '[start] initializing pwr-jumper'
  _QUIET=1 safe-source ~/.pwrfunc.sh
  .tick-zshrc-pwr '[end] pwr-jumper'

  #
  ### PWR TOOLS
  #
  alias pwr-tn-syndication-replica='eval-quiet pwr tn 11052:syndication-replica-db.prod.us-west-2.pwr:5432'
  alias pwr-tn-ugc='eval-quiet pwr tn 6645:prod-ugcv2.cqvr0zfoyqja.us-west-2.rds.amazonaws.com:5432'

  alias pwr-mfa-developers='AWS_DEFAULT_OUTPUT=json eval-quiet pwr-mfa assume --role pwr-developers'
  alias pwr-mfa-on-call='AWS_DEFAULT_OUTPUT=json eval-quiet pwr-mfa assume --role pwr-on-call'

  #
  ### AWS CLI
  #
  alias aws-s3-ls-bucket-prefix='qeval aws s3 ls --bucket-name-prefix'

}
zshrc-pwr-wrapper

alias .reload-boostraprc-pwr='eval-quiet . "~/.zshrc.pwr"'

.tick-zshrc-pwr "[END-FILE] \(\$\$=[$$]\)"
