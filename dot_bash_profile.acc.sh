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

.setup-acc-vb-vm-aliases ora "${VBOX_ORA_NAME:=Oracle_19c}"
.setup-acc-vb-vm-aliases mapr "${VBOX_MAPR_NAME:=MapR-Sandbox-6.1.0-Secure}"

#
### GRADLE helpers
#
interceptas-task() {
  qeval cd "$HOME/Workspace/interceptas"
  qeval gw-task $INTERCEPTAS_OPTS $@
}
int-start() {
  vecho 'Listens on ports 8081'
  qeval interceptas-task start $@
}
#
api-start() {
  iterm-set-title --tab 'api'
  vecho 'Listens on ports 9009'
  qeval interceptas-task startApi -Pmapr-enabled=true -Psharding-enabled=true $@
}
#
rtd-start() {
  vecho 'Listens on ports 8088'
  iterm-set-title --tab 'rtd'
  qeval interceptas-task startRtd $@
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
int-db-sync() {
  qeval interceptas-task dbTaskInfoCore dbTaskMigrateCore $@
}
#
minion-task() {
  qeval cd "$HOME/Workspace/minion"
  qeval gw-task $MINION_OPTS $@
}
minion-queue-writer-start() {
  vecho 'Listens on ports 8080'
  qeval minion-task bootRun -Pprofiles=queuewriter $@
}
minion-velociraptor-direct-start() {
  qeval minion-task bootRun -Pprofiles=velociraptor-direct $@
}
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
  qeval gw-task $RADAR_OPTS $@
}
#
vertigo-task() {
  qeval cd "$HOME/Workspace/vertigo"
  qeval gw-task $VERTIGO_OPTS $@
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
  local user='maprdev'; [[ "$1" =~ ^(-u|--user)$ ]] && user="$2" && shift 2
  [[ -z "$user" ]] && eecho "$USAGE" && return 1
  if type -t systemctl &>/dev/null; then
    [[ -z "$1" ]] && eecho "$USAGE" && return 1
    ((SH_QUIET)) || echo ">\$ $@"
    $@
  else
    qeval "ssh $user@mapr01.vm $@"
  fi
}
#
mapr-login-password() { 
  local USAGE="Usage: mapr-login-password [user] [password]; user defaults to 'maprdev', password to user"
  [[ -z "$MAPR_USER" ]] && export MAPR_USER=$(whoami)
  local user="${1:-$MAPR_USER}"
  local password="${2:-$MAPR_CRED}"
  qeval maprlogin password -user $user <<< "$password"
}
#
mapr-start() { vb-mapr-start "$@"; }
mapr-cli-service-list() { mapr-command sudo maprcli service list "$@"; }
mapr-shutdown() { mapr-command -u root "./mapr-shutdown.sh $@"; }
mapr-ss() { mapr-command sudo ss -lptn4 | cat; }
mapr-netstat() { mapr-command sudo netstat -4 --numeric-ports -l -e -p; }

# systemctl (GNU/Linux)
#   --type=service | socket|busname|target|snapshot|device|mount|automount|swap|timer|path|slice|scope
#   --state=running loaded | active | exited
#   --show-types for sockets
#   --no-ask-password
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
mapr-zookeper-status() { mapr-command "sudo systemctl status mapr-zookeper $@"; }
mapr-zookeper-restart() { mapr-command "sudo systemctl reload-or-restart --no-ask-password mapr-zookeper $@"; }
mapr-zookeper-start() { mapr-command "sudo systemctl start --no-ask-password mapr-zookeper $@"; }
mapr-zookeper-stop() { mapr-command "sudo systemctl stop --no-ask-password mapr-zookeper $@"; }
#
mapr-warden-status() { mapr-command "sudo systemctl status mapr-warden $@"; }
mapr-warden-restart() { mapr-command "sudo systemctl reload-or-restart --no-ask-password mapr-warden $@"; }
mapr-warden-start() { mapr-command "sudo systemctl start --no-ask-password mapr-warden $@"; }
mapr-warden-stop() { mapr-command "sudo systemctl stop --no-ask-password mapr-warden $@"; }
mapr-warden-log() { mapr-command "grep '$(date +%Y-%m-%d)' /opt/mapr/logs/warden.log $@"; }


.tick-bash-profile-acc "[END-FILE] (\$\$=[$$])"

