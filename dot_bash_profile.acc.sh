#!/usr/bin/env bash

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# TICK_x variables control its behavior; all default to false/0/off.
# export TICK_ENABLED= TICK_STDERR= TICK_STDOUT=
# export TICK__INDENT=
. ~/.tick.sh
.tick-bash-profile-acc() { .tick -s '.bash_profile.acc' "$@"; }

.tick-bash-profile-acc "[START-FILE] (\$\$=[$$])"

#
### JAVA version helpers
#
export JAVA_V8='8.0.202-zulu'
export JAVA_V11='11.0.18-zulu'

#
### Virtual Box start/stop/log
#
.setup-acc-vb-vm-aliases() {
  [[ -z "$2" ]] && eecho "usage: .setup-acc-vb-vm-aliases abbr vm_name" && return 1
  local abbr="$1" vm_name="$2"; shift 2
  alias vb-$abbr-start="vb-start \"$vm_name\""
  alias vb-$abbr-reboot="vb-reboot \"$vm_name\""
  alias vb-$abbr-shutdown="vb-shutdown \"$vm_name\""
  alias vb-$abbr-poweroff="vb-poweroff \"$vm_name\""
  alias vb-$abbr-log="vb-log \"$vm_name\""
}

.setup-acc-vb-vm-aliases ora "${VBOX_ORA_NAME:=Oracle19c_19_18}"
.setup-acc-vb-vm-aliases mapr "${VBOX_MAPR_NAME:=MapR-Sandbox-6.1.0-Secure}"

#
### GRADLE helpers
#
gw-slow() {
  gw-task --info --no-build-cache --no-configuration-cache --no-configure-on-demand $@
}
gw-normal() {
  gw-task --build-cache $@
}
gw-fast() {
  gw-normal --no-rebuild --configuration-cache --configure-on-demand $@
}
gw-faster() {
  gw-fast  --offline -x war -x explodeWar $@
}
#
int-clean() { 
  iterm-set-title --tab 'int-clean'
  gw-slow clean $@
}
int-clean-start() { 
  iterm-set-title --tab 'int-clean-start'
  gw-normal clean start $@
}
int-clean-start-mapr-no() { 
  iterm-set-title --tab 'int-clean-start'
  gw-normal clean start -Pmapr-enabled=false $@
}
int-clean-start-slow() { 
  iterm-set-title --tab 'int-clean-start-slow'
  gw-slow clean start $@
}
int-clean-start-slow-mapr-no() { 
  iterm-set-title --tab 'int-clean-start-slow'
  gw-slow clean start -Pmapr-enabled=false $@
}
int-start-mapr-yes() {
  iterm-set-title --tab 'int-start'
  gw-normal start -Pmapr-enabled=true $@
}
int-start-mapr-no() {
  iterm-set-title --tab 'int-start'
  gw-normal start -Pmapr-enabled=false $@
}
int-start-slow() {
  iterm-set-title --tab 'int-start-slow'
  gw-slow start $@
}
int-start-slow-mapr-yes() {
  iterm-set-title --tab 'int-start-slow'
  gw-slow start -Pmapr-enabled=true $@
}
int-start-slow-mapr-no() {
  iterm-set-title --tab 'int-start-slow'
  gw-slow start -Pmapr-enabled=false $@
}
int-start-fast() {
  iterm-set-title --tab 'int-start-fast'
  gw-fast start $@
}
int-start-fast-mapr-yes() {
  iterm-set-title --tab 'int-start-fast'
  gw-fast start -Pmapr-enabled=true $@
}
int-start-fast-mapr-no() {
  iterm-set-title --tab 'int-start-fast'
  gw-fast start -Pmapr-enabled=false $@
}
int-db-migrate() {
  iterm-set-title --tab 'int-db-migrate'
  gw-normal dbTaskInfoCore dbTaskMigrateCore $@
}
#
# For database unit test container
#
int-ora-prep-db() {
  iterm-set-title --tab 'int-ora-prep-db'
  gw-normal oraclePrepareDatabase $@
}
int-ora-start() {
  iterm-set-title --tab 'int-ora-start'
  gw-fast oracleStart $@
}
int-ora-stop() {
  iterm-set-title --tab 'int-ora-stop'
  gw-normal oracleStop $@
}
#
api-start() {
  iterm-set-title --tab 'api-start'
  gw-normal startApi -Psharding-enabled=true $@
}
api-start-mapr-yes() {
  iterm-set-title --tab 'api-start'
  gw-normal startApi -Psharding-enabled=true -Pmapr-enabled=true $@
}
api-start-mapr-no() {
  iterm-set-title --tab 'api-start'
  gw-normal startApi -Psharding-enabled=true -Pmapr-enabled=false $@
}
api-start-fast() {
  iterm-set-title --tab 'api-start-fast'
  gw-fast startApi -Pmapr-enabled=true $@
}
api-start-fast-mapr-yes() {
  iterm-set-title --tab 'api-start-fast'
  gw-fast startApi -Psharding-enabled=true -Pmapr-enabled=true $@
}
api-start-fast-mapr-no() {
  iterm-set-title --tab 'api-start-fast'
  gw-fast startApi -Psharding-enabled=true -Pmapr-enabled=false $@
}
api-start-faster() {
  iterm-set-title --tab 'api-start-faster'
  gw-faster startApi -Psharding-enabled=true $@
}
api-start-faster-mapr-yes() {
  iterm-set-title --tab 'api-start-faster'
  gw-faster startApi -Psharding-enabled=true -Pmapr-enabled=true $@
}
api-start-faster-mapr-no() {
  iterm-set-title --tab 'api-start-faster'
  gw-faster startApi -Psharding-enabled=true -Pmapr-enabled=false $@
}
#
rtd-start() {
  iterm-set-title --tab 'rtd'
  gw-normal startRtd $@
}
rtd-start-fast() {
  iterm-set-title --tab 'rtd'
  gw-fast startRtd $@
}
rtd-start-faster() {
  iterm-set-title --tab 'rtd'
  gw-faster startRtd $@
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
  iterm-set-title --tab 'queuewriter'
  gw-normal bootRun -Pprofiles=queuewriter $@
}
minion-maprproxy-start() {
  iterm-set-title --tab 'maprproxy'
  gw-normal bootRun -Pprofiles=maprproxy $@
}
minion-velociraptor-direct-start() {
  iterm-set-title --tab 'velociraptor-direct'
  gw-normal bootRun -Pprofiles=velociraptor-direct $@
}
minion-mv-start() {
  iterm-set-title --tab 'maprproxy,velociraptor-direct'
  gw-normal bootRun -Pprofiles=maprproxy,velociraptor-direct $@
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
tty-console() {
  local USAGE="Usage: tty-console -p port [-t title] [command]"
  local port title tty_cmd
  while [[ "$1" ]]; do case "$1" in
    -p|--port )   port="$2"; : ${title:=tty:$port}; shift 2;;
    -t|--title )  title="$2"; shift 2;;
    *)            break;;
  esac; done
  tty_cmd="$@"
  echo-glob port title tty_cmd

  [[ ! "$port" =~ ^[[:digit:]]{3,5}$ ]] && echo-error "$USAGE" && return 1

  # see https://superuser.com/a/410642/17666 for the echo/redirect magic
  local c="nc localhost $port"
  [[ -n "$tty_cmd" ]] && c="cat <(echo $tty_cmd) - | $c"
  qeval $c
}
tty-int()   { qeval tty-console -p 9092 "$@"; }
tty-api()   { qeval tty-console -p 9074 "$@"; }
tty-radar() { qeval tty-console -p 9999 "$@"; }
tty-vert()  { 
  qeval tty-console -p 9999 "$@" || qeval tty-console -p 9998 "$@"
}

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
    ((SH_QUIET)) || echo ">\$ $@"
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
mapr-start() { mapr-start "$@"; }
mapr-cli-service-list() { mapr-command sudo maprcli service list "$@"; }
mapr-shutdown() { mapr-command -u root "./mapr-shutdown.sh $@"; }
mapr-ss() { mapr-command sudo ss -lptn4 | cat; }
mapr-netstat() { mapr-command sudo netstat -4 --numeric-ports -l -e -p; }

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


alias .reload-bash-profile-acc='qeval . "~/.bash_profile"'
alias .rlbpa='veval .reload-bash-profile-acc'

.tick-bash-profile-acc "[END-FILE] (\$\$=[$$])"

