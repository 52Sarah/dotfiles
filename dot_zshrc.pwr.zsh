#!/usr/bin/env zsh

.tick-zshrc-pwr() { .tick -s '.zshrc.pwr' $@; }

.tick-zshrc-pwr "[START-FILE] (\$\$=[$$])"

# Do not execute this script if it has already been run this session and is not modified since.
if [[ "$(sh-ok-to-skip ~/.zshrc.pwr)" != 'true' ]]; then

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
    # api tunneling from: https://1worldsync.atlassian.net/wiki/spaces/PE/pages/6947471385/Tunneling+Command+Examples
    alias pwr-tn-api-analytics-etl-dark='eval-quiet pwr tn 4401:analytics-etl-dark.powerreviews.com:443'
    

    alias pwr-tn-api-core-services='eval-quiet pwr tn 4504:core-services.powerreviews.com:443'
    alias pwr-tn-api-content-pub='eval-quiet pwr tn 4518:content-publication-api.powerreviews.com:443'
    alias pwr-tn-api-core-data-etl='eval-quiet pwr tn 6668:core-data-etl.powerreviews.com:443'
    alias pwr-tn-api-product-services-importer='eval-quiet pwr tn 4502:product-services-importer.powerreviews.com:443'
    alias pwr-tn-api-shared-services='eval-quiet pwr tn 4500:shared-services.powerreviews.com:443'
    #
    alias pwr-tn-api-matching-operations='eval-quiet pwr tn 4506:matching-operations-api.powerreviews.io:443'
    alias pwr-tn-api-denormalization='eval-quiet pwr tn 4508:denormalization-api.powerreviews.io:443'
    alias pwr-tn-api-syndication='eval-quiet pwr tn 4510:syndication-api.powerreviews.io:443'
    alias pwr-tn-api-filtering='eval-quiet pwr tn 4512:filtering-api.powerreviews.io:443'
    alias pwr-tn-api-format='eval-quiet pwr tn 4514:format-api.powerreviews.io:443'
    alias pwr-tn-api-publication-worker='eval-quiet pwr tn 4516:publication-worker.powerreviews.io:443'
    #
    # the above aliases would work with curls like this:
    #     curl -X GET "https://localhost:4500/config-service/properties/m9794?keys=FTP_PASSWORD,FTP_USERNAME,FTP_SITE" \
    #       -H "accept: application/json" \
    #       -H "Host: shared-services.powerreviews.com" --insecure
    
    alias pwr-tn-db-analytics='eval-quiet pwr tn 10004:analyticsdb.prod.rds.us-west-2.pwr:5432'
    alias pwr-tn-db-matching='eval-quiet pwr tn 8708:matching-db.prod.us-west-2.pwr:5432'
    alias pwr-tn-db-multi='eval-quiet pwr tn 8710:multi-dbv1.prod.rds.us-west-2.pwr:5432'
    alias pwr-tn-db-reviews='eval-quiet pwr tn 5474:reviews-db3v.prod.us-west-2.pwr:5432'
    alias pwr-tn-db-subject-replica='eval-quiet pwr tn 5472:subject-replica.prod.rds.us-west-2.pwr:5432'
    alias pwr-tn-db-syndication='eval-quiet pwr tn 11051:syndication-db.prod.us-west-2.pwr:5432'
    alias pwr-tn-db-syndication-replica='eval-quiet pwr tn 11052:syndication-replica-db.prod.us-west-2.pwr:5432'
    alias pwr-tn-db-tracking='eval-quiet pwr tn 11053:tracking.prod.rds.us-west-2.pwr:5435'
    alias pwr-tn-db-ugc='eval-quiet pwr tn 6645:prod-ugcv2.cqvr0zfoyqja.us-west-2.rds.amazonaws.com:5432'

    alias pwr-tn-dbs-b2b-api='pwr-tn-db-ugc && pwr-tn-db-subject-replica && pwr-tn-db-multi'

    alias pwr-mfa-developers='AWS_DEFAULT_OUTPUT=json eval-quiet pwr-mfa assume --role pwr-developers'
    alias pwr-mfa-on-call='AWS_DEFAULT_OUTPUT=json eval-quiet pwr-mfa assume --role pwr-on-call'
    alias pwr-mfa-reporting='AWS_DEFAULT_OUTPUT=json eval-quiet pwr-mfa assume --role pwr-reporting'

    #
    ### AWS CLI
    #
    alias aws-whoami='qeval aws sts get-caller-identity'
    #
    alias aws-ecs-bounce-dev-enterprise-api='qeval aws ecs update-service  --cluster dev-ecs  --service dev-enterprise-api  --force-new-deployment'
    alias aws-ecs-bounce-qa-enterprise-api='qeval aws ecs update-service  --cluster qa-ecs  --service qa-enterprise-api  --force-new-deployment'
    #
    #
    # Some commands with nested JSON store it as escaped strings.
    aws-json-unescaped() {
      sed -e 's/\\"/"/g; s/"{/{/g; s/}"/}/g'
    }
    #
    aws-dms-ls-tasks() {
      local c="aws dms describe-replication-tasks --output 'yaml' --query 'ReplicationTasks[].ReplicationTaskIdentifier' $@"
      qeval "$c | sort | awk '{print \$2}'"
    }
    aws-dms-describe-task() {
      local opt_raw=; [[ "$1" =~ ^(--raw|-r)$ ]] && opt_raw=1 && shift
      [[ -n "$1" && ! "$1" =~ ^-.+ ]] && export DMS_TASK_NAME="$1" && shift
      [[ -z "$DMS_TASK_NAME" ]] && echo-error "usage: aws-dms-describe-task [--raw] DMS_TASK_NAME [jq_opts]" && return 1
      local c="aws dms describe-replication-tasks --output 'json' --query \"ReplicationTasks[?ReplicationTaskIdentifier == '$DMS_TASK_NAME']\" $@"
      ((! opt_raw)) && c="$c | aws-json-unescaped"
      qeval "$c | jq --sort-keys $@"
    }
    #
    aws-elbv2-ls-albs() {
      local c="aws elbv2 describe-load-balancers --output 'yaml' --query 'LoadBalancers[].LoadBalancerName' $@ | sort | awk '{print \$2}'"
      qeval "$c"
    }
    aws-elbv2-get-alb-arn() {
      export LB_NAME="${1:-$LB_NAME}"
      [[ -z "$LB_NAME" ]] && echo-error "usage: aws-elbv2-get-alb-arn LB_NAME" && return 1
      local c="aws elbv2 describe-load-balancers --names '$LB_NAME' --output 'text' --query 'LoadBalancers[0].LoadBalancerArn' $@"
      export LB_ARN="$(qeval "$c")"
      echo-glob 'LB_*'
    }
    aws-elbv2-describe-alb() {
      export LB_NAME="${1:-$LB_NAME}"
      [[ -z "$LB_NAME" ]] && echo-error "usage: aws-elbv2-describe-alb LB_NAME" && return 1
      local c="aws elbv2 describe-load-balancers --names '$LB_NAME' --output 'json' --query 'LoadBalancers[0]' $@ | jq"
      qeval "$c"
    }
    aws-elbv2-ls-listeners() {
      export LB_ARN="${1:-$LB_ARN}"
      [[ -z "$LB_ARN" ]] && echo-error "usage: aws-elbv2-ls-listeners LB_ARN" && return 1
      local c="aws elbv2 describe-listeners --load-balancer-arn '$LB_ARN' --output 'json' $@ \ jq"
      qeval "$c"
    }
    aws-elbv2-get-listener-https-arn() {
      export LB_ARN="${1:-$LB_ARN}"
      [[ -z "$LB_ARN" ]] && echo-error "usage: aws-elbv2-get-listener-https-arn LB_ARN" && return 1
      local c="aws elbv2 describe-listeners --load-balancer-arn '$LB_ARN' --output 'text' --query \"Listeners[?Protocol == 'HTTPS'].ListenerArn\" $@"
      export LBL_ARN="$(qeval "$c")"
      echo-glob 'LBL_ARN'
    }
    aws-elbv2-describe-listener-https() {
      export LB_ARN="${1:-$LB_ARN}"
      [[ -z "$LB_ARN" ]] && echo-error "usage: aws-elbv2-describe-listener-https LB_ARN" && return 1
      local c="aws elbv2 describe-listeners --load-balancer-arn '$LB_ARN' --output 'json' --query \"Listeners[?Protocol == 'HTTPS']\" $@ | jq"
      qeval "$c"
    }
    aws-elbv2-ls-rules() {
      export LBL_ARN="${1:-$LBL_ARN}"
      [[ -z "$LBL_ARN" ]] && echo-error "usage: aws-elbv2-ls-rules LBL_ARN" && return 1
      local c="aws elbv2 describe-rules --listener-arn '$LBL_ARN' --output 'json' $@ | jq"
      qeval "$c"
    }
    aws-elbv2-get-rule-arn() {
      export LBL_ARN="${1:-$LBL_ARN}"
      [[ -z "$LBL_ARN" ]] && echo-error "usage: aws-elbv2-get-listener-https-arn LBL_ARN" && return 1
      local c="aws elbv2 describe-rules --listener-arn '$LBL_ARN' --output 'text' --query \"Listeners[?Protocol == 'HTTPS'].ListenerArn\" $@"
      export LBL_ARN="$(qeval "$c")"
      echo-glob 'LBL_ARN'
    }
    aws-elbv2-describe-rule() {
      export LBL_ARN="${1:-$LBL_ARN}"
      [[ -z "$LBL_ARN" ]] && echo-error "usage: aws-elbv2-describe-listener-https LBL_ARN" && return 1
      local c="aws elbv2 describe-rules --listener-arn '$LBL_ARN' --output 'json' --query \"Listeners[?Protocol == 'HTTPS']\" $@ | jq"
      qeval "$c"
    }
    #
    #
    aws-logs-ls-groups() {
      [[ -n "$1" && ! "$1" =~ ^--.+$ ]] && export LG_NAME_PATTERN="$1" && shift
      [[ -z "$LG_NAME_PATTERN" ]] && echo-error "usage: aws-logs-ls-groups LG_NAME_PATTERN" && return 1
      local c="aws logs describe-log-groups --log-group-name-pattern '$LG_NAME_PATTERN' --output 'yaml' --query 'logGroups[].logGroupName' $@ | sort | awk '{print \$2}'"
      qeval "$c"
    }
    aws-logs-filter() {
      [[ -n "$1" && ! "$1" =~ ^-.+$ ]] && export LG_NAME="$1" && shift
      [[ -z "$LG_NAME" ]] && echo-error "usage: aws-logs-tail [LG_NAME] [-s rel_gdate] [aws logs filter-log-events options ...]" && return 1
      local c_params=
      while [[ -n "$1" ]]; do case "$1" in
        -s)
          c_params+=" --start-time $(gdate -d "$2" +%s000)"
          shift 2;;
        -n)
          c_params+=" --max-items $2"
          shift 2;;
        *)
          break;;
      esac; done
      local c="aws logs filter-log-events --log-group-name '$LG_NAME' --output 'yaml' $c_params --query 'events[].message' $@"
      qeval "$c"
    }
    aws-logs-tail() {
      [[ -n "$1" && ! "$1" =~ ^--.+$ ]] && export LG_NAME="$1" && shift
      [[ -z "$LG_NAME" ]] && echo-error "usage: aws-logs-tail LG_NAME" && return 1
      local c="aws logs tail --follow --format 'short' '$LG_NAME' $@"
      qeval "$c"
    }
    #
    #
    aws-rds-ls-instances() {
      local c="aws rds describe-db-instances --output 'yaml' --query 'DBInstances[].DBInstanceIdentifier' $@ | sort | awk '{print \$2}'"
      qeval "$c"
    }
    aws-rds-describe-instance() {
      [[ -z "$1" ]] && echo-error "usage: aws-rds-describe-instance db_instance_id" && return 1
      local db_instance_id="$1"; shift 1
      local c="aws rds describe-db-instances --db-instance-identifier '$db_instance_id' --output 'json' $@"
      local c_out="$(qeval $c)"
      [[ -z "$c_out" ]] && return 1 || jq --sort-keys <<< "$c_out"
    }
    #
    aws-s3-ls-pr-powerreviews-oregon() {
      local c="aws s3 ls 'pr-powerreviews-oregon/$@' "
      qeval "$c"
    }
    aws-s3-ls-publication-results-csv() {
      local c="aws s3 ls 'pr-powerreviews-oregon/publication-results-csv/$@' "
      qeval "$c"
    }
    #
    aws-secrets-list() {
      local c="aws secretsmanager list-secrets --query 'SecretList[].Name' $@ | sort | awk '{print \$2}'"
      qeval "$c"
    }
    alias aws-secrets-ls='aws-secrets-list'
    aws-secrets-get() {
      [[ -z "$1" ]] && echo-error "usage: aws-secrets-get secret_name" && return 1
      local secret_name="$1"; shift 1
      local c="aws secretsmanager get-secret-value --secret-id '$secret_name' --output 'text' --query 'SecretString' $@"
      local c_out="$(qeval $c)"
      [[ -z "$c_out" ]] && return 1 || jq --sort-keys <<< "$c_out"
    }
    #
    aws-find-assumable-roles() {
      aws_username=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
      [[ -z "$aws_username" ]] && echo-error "Could not determine IAM user name. Are you using an assumed role?" && return 1

      echo "Inspecting policies for user: $aws_username"
      echo "----------------------------------------"

      # 1. Check directly attached user policies
      echo "Found in attached policies:"
      MANUAL_POLICIES=$(aws iam list-attached-user-policies --user-name "$aws_username" --query 'AttachedPolicies[].PolicyArn' --output text)
      for policy_arn in $MANUAL_POLICIES; do
          aws iam get-policy-version --policy-arn "$policy_arn" --version-id $(aws iam get-policy --policy-arn "$policy_arn" --query 'Policy.DefaultVersionId' --output text) \
          --query 'PolicyVersion.Document.Statement[?Effect==`Allow` && Action==`sts:AssumeRole`].Resource' --output text | tr '\t' '\n'
      done

      # 2. Check inline user policies
      echo -e "\nFound in inline policies:"
      INLINE_POLICIES=$(aws iam list-user-policies --user-name "$aws_username" --query 'PolicyNames' --output text)
      for policy_name in $INLINE_POLICIES; do
          aws iam get-user-policy --user-name "$aws_username" --policy-name "$policy_name" \
          --query 'PolicyDocument.Statement[?Effect==`Allow` && Action==`sts:AssumeRole`].Resource' --output text | tr '\t' '\n'
      done

      # 3. Check policies from the user's groups
      echo -e "\nFound in group policies:"
      GROUPS=$(aws iam list-groups-for-user --user-name "$aws_username" --query 'Groups[].GroupName' --output text)
      for group_name in $GROUPS; do
          # Attached group policies
          ATTACHED_GROUP_POLICIES=$(aws iam list-attached-group-policies --group-name "$group_name" --query 'AttachedPolicies[].PolicyArn' --output text)
          for policy_arn in $ATTACHED_GROUP_POLICIES; do
              aws iam get-policy-version --policy-arn "$policy_arn" --version-id $(aws iam get-policy --policy-arn "$policy_arn" --query 'Policy.DefaultVersionId' --output text) \
              --query 'PolicyVersion.Document.Statement[?Effect==`Allow` && Action==`sts:AssumeRole`].Resource' --output text | tr '\t' '\n'
          done
          # Inline group policies
          INLINE_GROUP_POLICIES=$(aws iam list-group-policies --group-name "$group_name" --query 'PolicyNames' --output text)
          for policy_name in $INLINE_GROUP_POLICIES; do
              aws iam get-group-policy --group-name "$group_name" --policy-name "$policy_name" \
              --query 'PolicyDocument.Statement[?Effect==`Allow` && Action==`sts:AssumeRole`].Resource' --output text | tr '\t' '\n'
          done
      done | sort | uniq | grep .
    }

    #
    ### GITHUB CLI
    #
    gh-bb() { eval-quiet gh browse --branch "$GIT_BRANCH"; }
    gh-prl-branch() { eval-quiet gh prl-all --head "$GIT_BRANCH"; }
    gh-prl-all() { eval-quiet gh prl-all --search "'updated:>=$(date -v -${1:-30}d -I)'"; }

  }
  zshrc-pwr-wrapper

  alias .reload-boostraprc-pwr='eval-quiet . "~/.zshrc.pwr"'

  sh-store-mtime ~/.zlogin
  .tick-zshrc-pwr "[END-FILE] \(\$\$=[$$]\)"
fi
