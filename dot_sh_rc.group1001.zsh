#!/usr/bin/env zsh

.sh-rc-group1001-wrapper() {
  local dot_fname='.sh_rc.group1001'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-rc-group1001() {
    .dot-reset-mtimes
    eval-quiet source ~/.sh_rc.group1001
  }

  .tick-sh-rc-group1001() { .tick -s '.sh_rc.group1001' $@; }
  .tick-sh-rc-group1001 "[START-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname), \$SHELL=$SHELL"


  if ((_DOT_SKIP_ONYX_SETUP)); then
    .tick-sh-rc-group1001 "[skip] ONYX initialization: _DOT_SKIP_ONYX_SETUP"
  else
    .setup-onyx() {
      .tick-sh-rc-group1001 "[start] ONYX initialization"

      ONYX_TMP="$HOME/tmp/onyx/setup-env.sh/$$"
      if is-zsh; then
        ONYX_SETUP="$HOME/Workspace/onyx-zendesk-connector/scripts/env/setup-onyx.zshrc"
      else
        ONYX_SETUP="$HOME/Workspace/onyx-zendesk-connector/scripts/env/setup-onyx.bashrc"
      fi
      if [[ ! -f "$ONYX_SETUP" ]]; then
        .tick-sh-rc-group1001 " ... [ERROR] file not found: $ONYX_SETUP"
      elif [[ -f "$ONYX_TMP" ]]; then
        .tick-sh-rc-group1001 " ... skipping setup-onyx.zshrc, ONYX_TMP already exists: $ONYX_TMP"
      elif [[ -n "$ONYX_ENV" ]]; then
        .tick-sh-rc-group1001 " ... skipping setup-onyx.zshrc, ONYX_ENV already initialized: $ONYX_ENV"
      else
        .tick-sh-rc-group1001 " ... reading $ONYX_SETUP"
        source "$ONYX_SETUP"
      fi
      .tick-sh-rc-group1001 " ... ONYX_ENV=$ONYX_ENV ONYX_JVM_DIR=$ONYX_JVM_DIR"

      # from onyx-jcm/docs/setup.sh
      export ONYX_ENV_HOME="$HOME/.onyx-env"

      export CERT_FILE="$ONYX_ENV_HOME/onyx-truststore.pem"
      .tick-sh-rc-group1001 " ... ONYX_ENV_HOME=$ONYX_ENV_HOME"
      .tick-sh-rc-group1001 " ... CERT_FILE=$CERT_FILE"
      export NODE_EXTRA_CA_CERTS="$CERT_FILE"
      export SSL_CERT_FILE="$CERT_FILE"
      export REQUESTS_CA_BUNDLE="$CERT_FILE"
      export HTTPLIB2_CA_CERTS="$CERT_FILE"

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

      .tick-sh-rc-group1001 " [end] ONYX initialization"
    }
    .setup-onyx
  fi

  source-extra-dot-files $dot_fname
  .dot-store-mtime ~/$dot_fname

  .tick-sh-rc-group1001 "[END-FILE] (\$\$=$$), mtime=$(file-mtime ~/$dot_fname)"
}
.sh-rc-group1001-wrapper && unset -f .sh-rc-group1001-wrapper

