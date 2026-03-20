#!/usr/bin/env zsh

.sh-rc-group1001-wrapper() {
  local dot_fname='.sh_rc.group1001'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-sh-rc-group1001() {
    .dot-reset-mtimes
    eval-quiet source ~/.sh_rc.group1001
  }

  .tick-sh-rc-group1001() { .tick -s '.sh_rc.group1001' "\$\$=$$ $@"; }
  .tick-sh-rc-group1001 "[START-FILE] \$SHELL=$SHELL, \$PPID=$PPID, mtime=$(file-mtime ~/$dot_fname)"


  #
  ### GCLOUD aliases
  #
  alias gcp='gcloud'
  alias gcp-projects-list='eval-quiet gcloud projects list'
  alias gcp-config-list='eval-quiet gcloud config list'

  #
  ### GRADLE aliases
  #
  alias gw='eval-quiet ./gradlew'
  alias gw-tasks='eval-quiet ./gradlew tasks'
  alias gw-tasks-application='eval-quiet ./gradlew tasks --group application'
  alias gw-tasks-build='eval-quiet ./gradlew tasks --group build'
  #
  alias gwh='eval-quiet ./gradlew help'
  alias gwh-task='eval-quiet ./gradlew help --task'
  #
  alias gw-ktlint-check='eval-quiet ./gradlew ktlintCheck'
  alias gw-ktlint-format='eval-quiet ./gradlew ktlintFormat'
  #
  alias gw-onyx-generate-graphql-code='eval-quiet ./gradlew generateGraphQLCode'
  #
  alias gw-liquibase-drop-all='eval-quiet ./gradlew liquibaseDropAll'
  alias gw-liquibase-history='eval-quiet ./gradlew liquibaseHistory'
  alias gw-liquibase-rollback-1='eval-quiet ./gradlew liquibaseRollbackCount -PliquibaseCommandValue=1'
  alias gw-liquibase-rollback-1-sql='eval-quiet ./gradlew liquibaseRollbackCountSql -PliquibaseCommandValue=1'
  alias gw-liquibase-status='eval-quiet ./gradlew liquibaseStatus'
  alias gw-liquibase-update='eval-quiet ./gradlew liquibaseUpdate'

  #
  ### Windsurf
  if [[ -d "$HOME/.codeium/windsurf/bin" ]]; then
    path-append "$HOME/.codeium/windsurf/bin"
  fi

  #
  ### ONYX environment initialization
  #
  if ((_DOT_SKIP_ONYX_SETUP)); then
    .tick-sh-rc-group1001 "[skip] Onyx: _DOT_SKIP_ONYX_SETUP"
  else
    .setup-onyx() {
      .tick-sh-rc-group1001 "[start] Onyx initialization"

      export ONYX_DEBUG=true; [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]] && export ONYX_DEBUG=false
      export ONYX_TRACE=false
      export ONYX_NO_PROFILE=true 

      local ONYX_SETUP_PROJECT_ROOT="$HOME/Workspace/onyx-zendesk-connector"
      local ONYX_SETUP_EXT=zshrc; is-zsh || ONYX_SETUP_EXT=bashrc
      local ONYX_SETUP="$ONYX_SETUP_PROJECT_ROOT/scripts/env/setup-onyx.$ONYX_SETUP_EXT"
      local ONYX_TMP=$HOME/tmp/onyx/setup-env.sh/$$
      if [[ ! -d "$ONYX_SETUP_PROJECT_ROOT" ]]; then
        .tick-sh-rc-group1001 " ... [ERROR] ONYX_SETUP_PROJECT_ROOT directory not found: $(tilde $ONYX_SETUP_PROJECT_ROOT)"
      elif [[ ! -f "$ONYX_SETUP" ]]; then
        .tick-sh-rc-group1001 " ... [ERROR] ONYX_SETUP file not found: $(tilde $ONYX_SETUP)"
      # elif [[ -f "$ONYX_TMP" ]]; then
      #   .tick-sh-rc-group1001 " ... skipping setup-onyx.zshrc, ONYX_TMP already exists: $(tilde $ONYX_TMP)"
      # elif [[ -n "$ONYX_ENV" ]]; then
      #   .tick-sh-rc-group1001 " ... skipping setup-onyx.zshrc, ONYX_ENV already initialized: $(tilde $ONYX_ENV)"
      elif [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]]; then
        .tick-sh-rc-group1001 " ... skipping setup-onyx.zshrc, \$INTELLIJ_ENVIRONMENT_READER='$INTELLIJ_ENVIRONMENT_READER'"
      else
        .tick-sh-rc-group1001 " ... reading $(tilde $ONYX_SETUP)"
        if [[ "$ONYX_DEBUG" == "true" ]]; then
          source $ONYX_SETUP "$ONYX_ENV"
        else
          source $ONYX_SETUP "$ONYX_ENV" &>/dev/null
        fi
        .tick-sh-rc-group1001 " ... done reading $(tilde $ONYX_SETUP)"

        .tick-sh-rc-group1001 " ... ONYX_ENV=$ONYX_ENV"
        .tick-sh-rc-group1001 " ... POSTGRES_IP=$POSTGRES_IP"
        .tick-sh-rc-group1001 " ... ONYX_DEBUG=$ONYX_DEBUG ONYX_NO_PROFILE=$ONYX_NO_PROFILE LOAD_PARALLEL=$LOAD_PARALLEL"
        .tick-sh-rc-group1001 " ... SCRIPT_ENV_DIR=$(tilde $SCRIPT_ENV_DIR) SCRIPT_DIR=$(tilde $SCRIPT_DIR)"
        .tick-sh-rc-group1001 " ... ONYX_JVM_DIR=$(tilde $ONYX_JVM_DIR)"
        .tick-sh-rc-group1001 " ... TMP_EXPORT=$(tilde $TMP_EXPORT)"

        for s in dump-env encrypt reset-env setup-env setup-local-user-env; do
          alias onyx-$s="$SHELL $SCRIPT_ENV_DIR/$s.sh"
        done
        alias onyx-env-scripts="less $SCRIPT_ENV_DIR/env-scripts.md"
      fi

      # # from onyx-jcm/docs/setup.sh
      # export ONYX_ENV_HOME=$HOME/.onyx-env

      # export CERT_FILE="$ONYX_ENV_HOME/onyx-truststore.pem"
      # .tick-sh-rc-group1001 " ... ONYX_ENV_HOME=$ONYX_ENV_HOME"
      # .tick-sh-rc-group1001 " ... CERT_FILE=$CERT_FILE"
      # export NODE_EXTRA_CA_CERTS="$CERT_FILE"
      # export SSL_CERT_FILE="$CERT_FILE"
      # export REQUESTS_CA_BUNDLE="$CERT_FILE"
      # export HTTPLIB2_CA_CERTS="$CERT_FILE"

      # from onyx-jvm/scripts/env/setup-local-user-env.sh
      # export ONYX_SANDBOX=$USER
      # export PIPELINE=${CI:-${GITLAB_CI:-"false"}}
      # .tick-sh-rc-group1001 " ... ONYX_SANDBOX=$ONYX_SANDBOX"
      # .tick-sh-rc-group1001 " ... PIPELINE=$PIPELINE, CI=$CI, GITLAB_CI=$GITLAB_CI"

      # [[ -z "$POSTGRES_IP" ]] && export POSTGRES_IP='localhost'
      # [[ -z "$POSTGRES_USER" ]] && export POSTGRES_USER="admin"
      # [[ -z "$POSTGRES_SCHEMA" ]] && export POSTGRES_SCHEMA='ci'
      # .tick-sh-rc-group1001 " ... POSTGRES_IP=$POSTGRES_IP, POSTGRES_USER=$POSTGRES_USER, POSTGRES_SCHEMA=$POSTGRES_SCHEMA"
      # [[ -z "$POSTGRES_DATABASE" ]] && export POSTGRES_DATABASE='postgres'
      # export TMP_LOCAL=$ONYX_ENV_HOME/${ONYX_ENV}-local-keys.sec

      .tick-sh-rc-group1001 " [end] Onyx initialization"
    }
    .setup-onyx
  fi

  .dot-source-extra-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-sh-rc-group1001 "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.sh-rc-group1001-wrapper && unset -f .sh-rc-group1001-wrapper

