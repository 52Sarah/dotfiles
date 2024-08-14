#!/usr/bin/env bash

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# _TICK_x variables control its behavior; all default to false/0/off.
# export _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
# export _TICK_INDENT=
. ~/.tick.sh
.tick-bash-profile-acc() { .tick -s '.bash_profile.acc' $@; }

.tick-bash-profile-acc "[START-FILE] (\$\$=[$$])"

#
### JAVA version helpers
#
export JAVA_V8='8.0.202-zulu'
export JAVA_V11='11.0.18-zulu'

#
### cd/directory helpers
#
export WORKSPACE_DIR="$HOME/Workspace"
cd-workspace() { 
  [[ -z "$1" ]] && qeval cd "$WORKSPACE_DIR"
  local dir_prefix="$1"; shift 1
  ends_with "$dir_prefix" "\*" || dir_prefix="${dir_prefix}*"
  qeval cd "$WORKSPACE_DIR/$dir_prefix"
}
cd-profile() { 
  [[ "$ITERM_PROFILE" =~ ^$|^Default$ ]] && cd-workspace && return 1
  eval-unquiet cd "$WORKSPACE_DIR/$ITERM_PROFILE"
}
alias cdw='cd-workspace'
alias cdp='cd-profile'


# emulate coreutils' timeout command
timeout() {
  _debug && echo-stderr "START timeout: \$@=$@"
  local USAGE="Usage: timeout [-c ps_cmd] seconds command..."
  local ps_cmd
  [[ "$1" =~ ^-c|--cmd|--command$ ]] && ps_cmd="$2" && shift 2
  [[ -z "$2" ]] && echo-stderr "$USAGE" && return 1
  local seconds="$1"; shift 1
  local cmd="$@"
  : "${ps_cmd:=$cmd}"
  _debug && echo-var ps_cmd seconds cmd
  if [[ ! "$seconds" =~ ^[0-9.]+$ ]]; then
    echo-stderr "timeout: invalid seconds -- $seconds"
    return 1
  fi
  ( 
    eval "$cmd" &
    child=$(ps | egrep "[0-9]{2} $ps_cmd" | awk '{print $1;}')
    _debug && echo-var child
    trap -- "" SIGTERM 
    (       
      sleep $seconds
      kill $child 2>/dev/null
      _debug && echo "after sleep $seconds/kill $child:" && ps
    ) &
    wait $child 2>/dev/null
    _debug && echo "after wait $child:" && ps
  )
}


#
### Virtual Box start/stop/log
#
.setup-vbox-acc-vm-aliases() {

  : "${VBOX_ORA_NAME:=Oracle19c}"
  alias vb-ora-start="qeval vb-start $VBOX_ORA_NAME"
  alias vb-ora-on="qeval vb-ora-start"
  alias vb-ora-up="qeval vb-ora-start"
  vb-ora-poweroff() {
    qecho "START vb-ora-poweroff $@"
    eval-echo "vb-poweroff $VBOX_ORA_NAME $@"
    qecho "END vb-ora-poweroff $@"
  }
  alias vb-ora-stop="qeval vb-ora-poweroff"
  alias vb-ora-down="qeval vb-ora-poweroff"
  alias vb-ora-off="qeval vb-ora-poweroff"
  alias vb-ora-less="qeval vb-less $VBOX_ORA_NAME"
  alias vb-ora-tail="qeval vb-tail $VBOX_ORA_NAME"
  vb-ora-reboot() {
    qecho "START vb-ora-reboot $@"
    qeval vb-ora-stop $@
    qeval vb-ora-start $@
    qecho "END vb-ora-reboot $@"
  }
  alias vb-ora-bounce="vb-ora-reboot"
  alias vb-ora-restart="vb-ora-reboot"

  : "${VBOX_MAPR_NAME:=MapR}"
  alias vb-mapr-start="qeval vb-start $VBOX_MAPR_NAME"
  alias vb-mapr-on="qeval vb-mapr-start"
  alias vb-mapr-up="qeval vb-mapr-start"
  alias vb-mapr-poweroff="qeval mapr-shutdown"
  alias vb-mapr-stop="qeval vb-mapr-poweroff"
  alias vb-mapr-off="qeval vb-mapr-poweroff"
  alias vb-mapr-down="qeval vb-mapr-poweroff"
  
  alias vb-mapr-less="qeval vb-less $VBOX_MAPR_NAME"
  alias vb-mapr-tail="qeval vb-tail $VBOX_MAPR_NAME"
  vb-mapr-reboot() {
    qecho "START vb-mapr-reboot $@"
    qeval vb-mapr-stop
    qeval vb-mapr-start
    qecho "END vb-mapr-reboot $@"
  }
  alias vb-mapr-bounce="vb-mapr-reboot"
  alias vb-mapr-restart="vb-mapr-reboot"
}
! ((_SKIP_SETUP_VBOX)) && .setup-vbox-acc-vm-aliases


#
### GRADLE helpers
# Removed --configuration-cache since it often causes grief, even with problems=warn
#
gw-slowest() {
  gw --info  --no-build-cache --no-configuration-cache --no-configure-on-demand  $@
}
gw-slow() {
  gw --no-build-cache --no-configuration-cache --no-configure-on-demand  $@
}
gw-normal() {
  gw --build-cache --no-configuration-cache --no-configure-on-demand --dependency-verification=off  $@
}
gw-fast() {
  gw --build-cache --no-configuration-cache --configure-on-demand --dependency-verification=off  $@
}
gw-faster() {
  gw --offline  --build-cache --no-configuration-cache --configure-on-demand --dependency-verification=off  $@
}
gw-fastest() {
  gw --offline --no-rebuild  --build-cache --no-configuration-cache --configure-on-demand --dependency-verification=off  $@
}
#
gw-test() {
  [[ -z "$3" ]] && echo-error "Usage: gw-test fast|faster|... testTask testClass [useContainer:false]" && return 1
  local speed=$1 testTask=$2 testClass=$3; shift 3
  local useContainer=false; [[ "$1" =~ ^(true|false)$ ]] && useContainer=$1 && shift
  local excludes="-x:validateDbScripts -x:tag -x:version"
  rm -rf build/reports/tests/$testTask
  gw-$speed --no-build-cache :$testTask --tests "$testClass" $excludes -Puse-container=$useContainer  $@
  open build/reports/tests/$testTask/index.html
}
int-dbTestOracle() {
  [[ -z "$2" ]] && echo-error "Usage: dbTestOracle fast|faster|... testClass [useContainer:false]" && return 1
  local speed=$1 testClass=$2; shift 2
  local useContainer=false; [[ "$1" =~ ^(true|false)$ ]] && useContainer=$1 && shift
  gw_alias=int-dbTestOracle gw-test $speed dbTestOracle $testClass $useContainer  $@
}
int-dbIntTestOracle() {
  [[ -z "$2" ]] && echo-error "Usage: dbIntTestOracle fast|faster|... testClass [useContainer:false]" && return 1
  local speed=$1 testClass=$2; shift 2
  local useContainer=false; [[ "$1" =~ ^(true|false)$ ]] && useContainer=$1 && shift
  gw_alias=int-dbIntTestOracle gw-test $speed dbIntTestOracle $testClass $useContainer  $@
}
#
bin-clean-start() { 
  gw_alias=bin-clean-start gw-slow :server:clean :server:start2  $@
}
bin-start() {
  gw_alias=bin-start gw-normal :server:start2  $@
}
bin-start-fastest() {
  gw_alias=bin-start-fastest gw-fastest :server:start2  $@
}
#
eng-run() {
  gw_alias=eng-run gw-normal :runEngine -Pmapr-enabled=false  -x:validateDb -x:listDb  $@
}
eng-run-fastest() {
  gw_alias=eng-run-fastest gw-fastest :runEngine -Pmapr-enabled=false  -x:validateDb -x:listDb  -x:compileJava  -x:node  -x:war -x:explodeWar  $@
}
#
int-clean() { 
  gw_alias=int-clean gw-slow :clean  $@
}
int-clean-start() { 
  gw_alias=int-clean-start gw-slow :clean :start -Pmapr-enabled=false  $@
}
#
int-start-slowest() {
  gw_alias=int-start-slowest gw-slowest :start  $@
}
int-start-slow() {
  gw_alias=int-start-slow gw-slow :start  $@
}
#
int-start() {
  gw_alias=int-start gw-normal :start -Pmapr-enabled=false  -x:validateDb -x:listDb  $@
}
#
int-start-fast() {
  gw_alias=int-start-fast gw-fast :start -Pmapr-enabled=false  -x:validateDb -x:listDb  -x:compileJava  -x:node  $@
}
int-start-faster-nojava() {
  gw_alias=int-start-faster-nojava gw-fast :start -Pmapr-enabled=false  -x:validateDb -x:listDb  -x:compileJava  $@
}
int-start-faster-nonode() {
  gw_alias=int-start-faster-nonode gw-fast :start -Pmapr-enabled=false  -x:validateDb -x:listDb  -x:node  $@
}
int-start-fastest() {
  gw_alias=int-start-fastest gw-fastest --offline --no-rebuild \
    --build-cache --configuration-cache --configure-on-demand \
    -x:validateDbScripts -x:listDbScripts \
    -x:tag -x:version \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    :start $@ \
    -Pmapr-enabled=false
}
#
int-db-migrate() {
  gw-normal :dbTaskInfoCore :dbTaskMigrateCore  $@
}
#
tty-int-reset-icnow() {
  tty-int reset 44444 start
}
#
# For database unit test container; see: https://accertify.atlassian.net/wiki/spaces/SDLC/pages/2019229708/Dockerized+Oracle+and+Postgres+Database+for+Interceptas+Unit+Testing#Initial-Postgres-Steps
#
int-docker-ora-prepare-db()   { gw-slow :oraclePrepareDatabase  $@; }
int-docker-ora-start()        { gw-slow :oracleStart  $@; }
int-docker-ora-stop()         { gw-slow :oracleStop  $@; }
#
int-docker-pg-prepare-db()    { gw-slow :postgresPrepareDatabase  $@; }
int-docker-pg-start()        { gw-slow :postgresStart  $@; }
int-docker-pg-stop()         { gw-slow :postgresStop  $@; }
#
api-start() {
  gw_alias=api-start gw-normal :startApi $@ -Pmapr-enabled=false
}
api-start-fast() {
  gw_alias=api-start-fast gw-fast :startApi $@ -Pmapr-enabled=false
}
api-start-fastest() {
  gw_alias=api-start-fastest gw-fastest :startApi $@ -Pmapr-enabled=false
}
api-start2() {
  gw_alias=api-start2 gw-normal :startApi2 $@ -Pmapr-enabled=false
}
api-start2-fast() {
  gw_alias=api-start2-fast gw-fast :startApi2 $@ -Pmapr-enabled=false
}
api-start2-fastest() {
  gw_alias=api-start2-fastest gw-fastest :startApi2 $@ -Pmapr-enabled=false
}
#
rtd-start() {
  gw_alias=rtd-start gw-normal :startRtd $@ -Pmapr-enabled=false
}
rtd-start-fast() {
  gw_alias=rtd-start-fast gw-fast :startRtd $@ -Pmapr-enabled=false
}
rtd-start-fastest() {
  gw_alias=rtd-start-fastest gw-fastest --offline --no-rebuild \
    --build-cache --configuration-cache --configure-on-demand \
    -x:validateDbScripts -x:listDbScripts \
    -x:tag -x:version \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    :startRtd $@ \
    -Pmapr-enabled=false
}
rtd-start2() {
  gw_alias=rtd-start2 gw-normal :startRtd2 $@ -Pmapr-enabled=false
}
rtd-start2-fast() {
  gw_alias=rtd-start2-fast gw-fast :startRtd2 $@ -Pmapr-enabled=false
}
rtd-start2-fastest() {
  gw_alias=rtd-start2-fastest gw-fastest :startRtd2 $@ -Pmapr-enabled=false
}
#
rtd-db-migrate() {
  gw-normal :dbTaskInfoRtd :dbTaskMigrateRtd  $@
}
#
flink-start() {
  qeval flink-storage/docker/start.sh &
  qeval flink-update/docker/start.sh &
}
flink-stop() {
  qeval flink-storage/docker/stop.sh
  qeval flink-update/docker/stop.sh
}
#
minion-task() {
  qeval cd "$HOME/Workspace/minion"
  gw-task $MINION_OPTS $@
}
minion-queue-writer-start() {
  gw_alias=minion-queue-writer-start gw-normal :bootRun -Pprofiles=queuewriter $@
}
minion-maprproxy-start() {
  gw_alias=minion-maprproxy-start gw-normal :bootRun -Pprofiles=maprproxy $@
}
minion-velociraptor-direct-start() {
  gw_alias=minion-velociraptor-direct-start gw-normal :bootRun -Pprofiles=velociraptor-direct $@
}
minion-mv-start() {
  gw_alias=minion-mv-start gw-normal :bootRun -Pprofiles=maprproxy,velociraptor-direct $@
}
#
minion-app-up() {
  qeval cd "$HOME/Workspace/minion"
  qeval ./app/docker/start.sh
}
minion-app-down() {
  qeval cd "$HOME/Workspace/minion"
  qeval ./app/docker/stop.sh
}
#
radar-task() {
  qeval cd "$HOME/Workspace/radar"
  gw-task $RADAR_OPTS $@
}

# Tomcat console interfaces for various web apps running locally.
# If command is sent directly, kill the terminal process immediately after,
tty-console() {
  local USAGE="usage: tty-console -p port [-t timeout] [command]"
  local port timeout="1.5" tty_cmd
  while [[ -n "$1" ]]; do case "$1" in
    -p|--port )     port="$2"; shift 2;;
    -t|--timeout )  timeout="$2"; shift 2;;
    *)              break;;
  esac; done
  tty_cmd="$@"
  _debug && echo-var port timeout tty_cmd
  if [[ ! "$port" =~ ^[[:digit:]]{3,5}$ ]]; then
    echo-error "tty-console: missing or invalid port -- $port"
    echo-error "$USAGE"
    return 1
  fi

  # see https://superuser.com/a/410642/17666 for the echo/redirect magic
  local c="nc localhost $port" cfull
  if [[ -n "$tty_cmd" && -n "$timeout" ]]; then
    # local cfull="timeout -c '$c' $timeout 'cat <(echo $tty_cmd) - | $c'"
    local con_tmp="/var/tmp/con.tmp"
    echo "$tty_cmd" > $con_tmp
    echo "quit" >> $con_tmp
    local cfull="$c < $con_tmp"
    _debug && echo-var c cfull
  fi
  echo-verbose ">>>"
  eval-debug "${cfull:-$c}"
  echo-verbose "<<<"
}
#
tty-int()    { qeval tty-console -p 9092 $@; }
tty-api()    { qeval tty-console -p 9074 $@; }
tty-engine() { qeval tty-console -p 9090 $@; }
tty-rtd()    { qeval tty-console -p 9094 $@; }
tty-binder() { qeval tty-console -p 9096 $@; }
tty-radar()  { qeval tty-console -p 9999 $@; }
tty-vert() { 
  qeval tty-console -p 9999 $@ || qeval tty-console -p 9998 $@
}
#
tty-int-reset-icnow() { qeval tty-int reset 44444 start; }
tty-int-cache-status() { qeval tty-int cachestatus; }
tty-int-cache-reset() { 
  [[ -z "$@" ]] && echo-error "usage: tty-int-cache-reset CACHE_NAME" && return 1
  qeval tty-int resetcache $@
}
tty-int-cache-reset-flex() { 
  qeval tty-int resetcache FlexValue
  qeval tty-int resetcache FLEX_VALUE2
}
tty-int-cache-reset-properties() { 
  qeval tty-int resetcache Property
  qeval tty-int resetcache PROPERTY_VALUE
  qeval tty-int resetcache Hierarchy.properties
}
tty-int-cache-reset-rules() { 
  qeval tty-int resetcache Rule
  qeval tty-int resetcache RuleType
  qeval tty-int resetcache RuleSet
  qeval tty-int resetcache RulesInRuleSet
}
#


### ORA vm helpers
ora-ssh() { qeval ssh oracle@db01.vm $@; }

### MAPR vm helpers
mapr-ssh() { qeval ssh maprdemo $@; }
#
# Execute locally on MapR (Linux) box, or remotely via ssh.
mapr-command() {
  if [[ "$(hostname -s)" == "maprdemo" ]]; then
    qeval $@
    return
  fi
  local USAGE="usage: mapr-command [--user user] command"
  [[ -z "$MAPR_USER" ]] && export MAPR_USER=$(whoami)
  [[ "$1" =~ ^(-u|--user)$ ]] && MAPR_USER="$2" && shift 2
  [[ -z "$MAPR_USER" ]] && eecho "$USAGE" && return 1
  if type -t systemctl &>/dev/null; then
    [[ -z "$1" ]] && eecho "$USAGE" && return 1
    ! _quiet || echo ">\$ $@"
    $@
  else
    qeval "ssh ${MAPR_USER}@maprdemo $@"
  fi
}
#
mapr-login-password() { 
  local USAGE="Usage: mapr-login-password [user] [password]; user defaults to $USER, password to \$MAPR_CRED"
  [[ "$1" =~ -h|--help ]] && eecho "$USAGE" && return 0
  : "${MAPR_USER:=$USER}"
  local user="${1:-$MAPR_USER}"
  local password="${2:-$MAPR_CRED}"
  if [[ -z "$password" ]]; then
    eprintf "mapr-login-password: %s\n%s\n" "Password not specified nor in \$MAPR_CRED." "$USAGE"
    return 1
  fi
  qeval maprlogin password -user $user <<< "$password"
}
#
mapr-start() { qeval vb-mapr-start $@; }
mapr-cli-service-list() { qeval mapr-command sudo maprcli service list $@; }
mapr-shutdown() { qeval mapr-command -u root "./mapr-shutdown.sh $@"; }
mapr-ss() { qeval mapr-command sudo ss -lptn4 | less; }
mapr-netstat() { qeval mapr-command sudo netstat -4 --numeric-ports -l -e -p; }

# systemctl (GNU/Linux)
#   --type=service | socket|busname|target|snapshot|device|mount|automount|swap|timer|path|slice|scope
#   --state=running loaded | active | exited
#   --show-types for sockets
#  
#   list-units [default]
#   list-sockets
#   start|stop|reload|[try-]restart|reload-or-[try-]restart
#   kill
#   is-active|is-failed|status
#   show
mapr-sysc() { mapr-command "systemctl $@"; }
mapr-sysc-ls() { mapr-sysc "--type=service --state=running $@"; }
mapr-sysc-ls-all() { mapr-sysc "--type=service $@"; }
#
mapr-zookeeper-status() { mapr-command "sudo systemctl status mapr-zookeeper $@"; }
mapr-zookeeper-restart() { mapr-command "sudo systemctl reload-or-restart mapr-zookeeper $@"; }
mapr-zookeeper-start() { mapr-command "sudo systemctl start mapr-zookeeper $@"; }
mapr-zookeeper-stop() { mapr-command "sudo systemctl stop mapr-zookeeper $@"; }
#
mapr-warden-status() { mapr-command "sudo systemctl status mapr-warden $@"; }
mapr-warden-restart() { mapr-command "sudo systemctl reload-or-restart mapr-warden $@"; }
mapr-warden-start() { mapr-command "sudo systemctl start mapr-warden $@"; }
mapr-warden-stop() { mapr-command "sudo systemctl stop mapr-warden $@"; }
mapr-warden-log() { mapr-command "grep '$(date +%Y-%m-%d)' /opt/mapr/logs/warden.log $@"; }


# apache-drill
#
.setup-drill() {
  : "${DRILL_HOME:=/opt/drill}"
  if [[ -d "$DRILL_HOME/bin" && -d "$DRILL_HOME/conf" ]]; then
    .tick-bash-profile-acc "Using DRILL_HOME=$DRILL_HOME"
    export DRILL_HOME
  else
    .tick-bash-profile-acc "Not using invalid DRILL_HOME=$DRILL_HOME"
    export DRILL_HOME=
  fi
}
! ((_SKIP_SETUP_DRILL)) && .setup-drill


#
### SCHEMASPY
#
.setup-schemaspy() {
  if [[ ! -e "$HOME/lib/schemaspy.jar" ]] then
    .tick-bash-profile "[end] .setup-schemaspy, schemaspy.jar not installed in ~/lib"
    return 1
  fi
  schemaspy-ora() {
    local db_type=orathin
    local db_host=db01.vm db_port=1521
    local db_name=COREVM db_user=core db_password=core
    while [[ "$1" =~ -[a-z] ]]; do case "$1" in
      -host|--host)         db_host="$2"; shift 2;;
      -port|--port)         db_port="$2"; shift 2;;
      -db|--database-name)  db_name="$2"; shift 2;;
      -u|--user)            db_user="$2"; shift 2;;
      -p|--password)        db_password="$2"; shift 2;;
      *) break;;
    esac; done
    local c="schemaspy \
      -t  $db_type \
      -db $db_name -host $db_host -port $db_port \
      -u  $db_user -p $db_password \
      -I  '^SYNCH_' \
      -X  '^id$|^established|^modified' \
      $@"
    qecho "\>\$ $c"
    $c
  }
  schemaspy-pg() {
    local db_type=pgsql11
    local db_host=localhost db_port=5432
    local db_name=core db_user=core db_password=core
    while [[ "$1" =~ -[a-z] ]]; do case "$1" in
      -host|--host)         db_host="$2"; shift 2;;
      -port|--port)         db_port="$2"; shift 2;;
      -db|--database-name)  db_name="$2"; shift 2;;
      -u|--user)            db_user="$2"; shift 2;;
      -p|--password)        db_password="$2"; shift 2;;
      *) break;;
    esac; done
    qeval schemaspy \
      -t "$db_type" \
      -db "$db_name" -host "$db_host" -port "$db_port" \
      -u "$db_user" -p "$db_password" \
      $@
  }
  schemaspy-pg-core() {
    schemaspy-pg -I 'adw.+'
  }
}
! ((_SETUP_SCHEMASPY_DISABLED)) && .setup-schemaspy


alias .reload-bash-profile-acc='eval-quiet . "~/.bash_profile.acc"'
alias .rlbpa='eval-quiet .reload-bash-profile-acc'

.tick-bash-profile-acc "[END-FILE] \(\$\$=[$$]\)"
