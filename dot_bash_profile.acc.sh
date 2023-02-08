#!/usr/bin/env bash

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# TICK_x variables control its behavior; all default to false/0/off.
# export TICK_ENABLED= TICK_STDERR= TICK_STDOUT=
# export TICK__INDENT=
. ~/.tick.sh
.tick-bash-profile-acc() { .tick -s '.bash_profile.acc' "$@"; }

.tick-bash-profile-acc "[START-FILE] (\$\$=[$$])"

#
### Virtual Box start/stop
#
.setup-acc-vb-vm-aliases() {
  [[ -z "$2" ]] && eecho "usage: .setup-acc-vb-vm-aliases abbr vm_name" && return 1
  local abbr="$1" vm_name="$2"; shift 2
  alias vb-$abbr-start="qeval vb-start \"$vm_name\""
  alias vb-$abbr-reboot="qeval vb-reboot \"$vm_name\""
  alias vb-$abbr-shutdown="qeval vb-shutdown \"$vm_name\""
  alias vb-$abbr-poweroff="qeval vb-poweroff \"$vm_name\""
  alias vb-$abbr-log="qeval vb-log \"$vm_name\""
}
.setup-acc-vb-vm-aliases ora 'Oracle 19c'
.setup-acc-vb-vm-aliases mapr 'MapR-Sandbox-6.1.0-Secure'

#
### GRADLE helpers
#
# Usage: gw-int-task [-m] gw-task-options...
#        where -m says to include the flag to disable mapr: -Pmapr-enabled=false
int-clean() {
  qeval gw-task clean $@
}
int-clean-start() {
  qeval gw-task clean start -Pmapr-enabled=false $@
}
int-start() {
  qeval gw-task --offline --build-cache --configure-on-demand start -Pmapr-enabled=false $@
}

### MAPR vm helpers
#
# Execute locally on MapR (Linux) box, or remotely via ssh.
mapr-command() {
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
mapr-start() { vb-mapr-start "$@"; }
mapr-ssh() { mapr-command "$@"; }
mapr-cli-service-list() { mapr-command sudo maprcli service list "$@"; }
mapr-shutdown() { mapr-command -u root "./mapr-shutdown.sh $@"; }
mapr-ss() { mapr-command sudo ss -lptn4 | cat; }
mapr-netstat() { mapr-command sudo netstat -4 --numeric-ports -l -e -p; }
# mapr-netstat2() {
#   local addr user pid_proc this_pid proc class
#   mapr-netstat \
#   | awk '/^tcp/ { printf("%s\t%s\t%s\n", $4, $7, $9); }' \
#   | while read -r addr user pid_proc; do
#       this_pid="${pid_proc%%/*}"
#       proc="${pid_proc##*/}"
#       decho "a:[$addr] u:[$user] pid:$this_pid proc:[$proc]"
#       class=.
#       if [[ "$proc" =~ "java" ]]; then
#         eprintf '...java\n'
#         class="$(SH_QUIET=1 mapr-command "ps -f -p $this_pid | egrep -o --color=never ' [a-z.]+\.[A-Z][[:alnum:]]+'")"; echo-status
#       fi
#       eprintf "...class=%s\n" "$class"
#       printf "A%-17s\tU%-8s\tI%-5s\tP%s\tC%s\n" "$addr" "$user" "$this_pid" "$proc" "$class"
#     done
# }
#
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

