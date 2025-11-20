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
### VIRTUAL BOX general helpers
#
.setup-vbox() {
  if is-defined VBoxManage; then
    .tick-bootstrap-profile '... setting up VirtualBox'

    export VBOX_VMS_HOME="$HOME/VirtualBox VMs"
    export VBOX_VERSION="$(substring_before_last $(VBoxManage --version) '.')" # e.g., 6.1 or 7.1

    vb() { eval-quiet VBoxManage $@; }
    #
    vb-list() {
      local _QUIET=$_QUIET _VERBOSE=$_VERBOSE _WHATIF=$_WHATIF
      local opt_hostonly opt_running
      local opts_are_general=1 general_opts
      while [[ "$1" ]]; do echo "arg: $1"; case "$1" in
        -q|--quiet)     _QUIET=1; shift 1;;
        -v|--verbose)   _VERBOSE=1; shift 1;;
        -h|--host*)     opt_hostonly=1; shift 1;;
        -r|--run*)      opt_running=1; shift 1;;

        --) opts_are_general=0; shift 1;;
        -*) if ((! opts_are_general)); then
              echo "((! opts_are_general))"
              break
            else
              general_opts="$general_opts $1"
              shift 1
              echo-var general_opts
            fi;;
        *) break;;
      esac; done
      local specific_opts="$@"
      echo-var opt_hostonly opt_running opts_are_general general_opts specific_opts
      if ((opt_hostonly)); then
        local hostonly="hostonlynets"; [[ "$VBOX_VERSION" =~ ^6 ]] && hostonly="hostonlyifs"
        eval-quiet vb $general_opts list $specific_opts "$hostonly"
      else
        local obj="vms"; ((opt_running)) && obj="runningvms" && shift 1
        eval-quiet vb $general_opts list --sorted $specific_opts "$obj"
      fi

    }
    alias vbls='eval-quiet vb-list'
    #
    vb-status() {
      local USAGE="usage: vb-status [--all] [--long]"
      local all= long=
      while [[ "$1" ]]; do case "$1" in
        -a|--all)   all=1; shift 1;;
        -l|--long)  long=1; shift 1;;
        *) break;;
      esac; done

      ((all)) && printf "\nALL VMS\n" && vb-list
      
      printf "\nRUNNING VMS\n"
      vb-list --running

      if ((long)); then
        printf "\nRUNNING VMS --long\n"
        vb-list --running -- --long |\
          egrep '^(Name|Guest OS|UUID|Config file|Log folder|Memory size|State):\s{2,}'
      fi
    }
    alias vbst=vb-status

    # Lookup full vm name given a pattern; if not found, return pattern with error status.
    vb-vm-name() {
      [[ -z "$1" ]] && echo-error "usage: vb-vm-name patt" && return 1
      local patt="$1" && shift
      local save_clicolor_force=${CLICOLOR_FORCE}
      unset CLICOLOR_FORCE
      if ls -1A "$VBOX_VMS_HOME/" | egrep -i "$patt"; then
        export CLICOLOR_FORCE=$save_clicolor_force
        return 0
      else
         echo "$patt"
         export CLICOLOR_FORCE=$save_clicolor_force
         return 1
      fi
    }

    vb-start() {
      [[ -z "$1" ]] && echo-error "usage: vb-start vm_name [startvm options]" && return 1
      local vm_name="$1" && shift
      eval-quiet VBoxManage startvm \"$vm_name\" --type headless $@
    }
    vb-controlvm() {
      [[ -z "$2" ]] && echo-error "usage: vb-controlvm vm_name_patt cmd [controlvm cmd options]" && return 1
      local vm_name_patt="$1" && shift
      local cmd="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      eval-quiet VBoxManage controlvm \"$vm_name\" $cmd $@
    }
    vb-reboot() {
      [[ -z "$1" ]] && echo-error "usage: vb-reboot vm_name" && return 1
      local vm_name_patt="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      eval-quiet vb-controlvm "$vm_name" reboot $@
    }
    vb-poweroff() {
      [[ -z "$1" ]] && echo-error "usage: vb-poweroff vm_name_patt [--type=gui|headless|..., other startvm options]" && return 1
      local vm_name_patt="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      gecho vm_name
      eval-quiet vb-controlvm "$vm_name" poweroff $@
    }

    vb-less() {
      [[ -z "$1" ]] && echo-error "usage: vb-less vm_name ['less' options]" && return 1
      local vm_name_patt="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      eval-quiet less $@ \"$VBOX_VMS_HOME/$vm_name/Logs/VBox.log\"
    }
    vb-tail() {
      [[ -z "$1" ]] && echo-error "usage: vb-tail vm_name_patt [-f or other 'tail' options]" && return 1
      local vm_name_patt="$1" && shift
      eval-quiet tail $@ \"$VBOX_VMS_HOME/$vm_name/Logs/VBox.log\"
    }
  fi
}
! ((_SKIP_SETUP_VBOX)) && .setup-vbox

#
### MAPR (client)
#
.setup-mapr() {
  .tick-bootstrap-profile '[start] .setup-mapr'
  [[ ! -e "/opt/mapr" ]] && .tick-bootstrap-profile '[end] .setup-mapr, no such directory: /opt/mapr' && return 1

  export MAPR_HOME="/opt/mapr"
  path-prepend "$MAPR_HOME/bin"

  .tick-bootstrap-profile "[end] .setup-mapr, MAPR_HOME=$MAPR_HOME, PATH=$PATH"
}
! ((_SKIP_SETUP_MAPR)) && .setup-mapr


#
### HADOOP (client & server, not embedded in MapR)
#
.setup-hadoop() {
  .tick-bootstrap-profile '[start] .setup-hadoop'
  [[ ! -e "/opt/hadoop" ]] && .tick-bootstrap-profile '[end] .setup-hadoop, no such directory: /opt/mapr' && return 1

  export HADOOP_HOME="/opt/hadoop"
  path-prepend "$HADOOP_HOME/sbin"
  path-prepend "$HADOOP_HOME/bin"

  export HADOOP_LIBEXEC_DIR="$HADOOP_HOME/libexec"
  export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
  export HADOOP_LOG_DIR="/var/log/hadoop"

  .tick-bootstrap-profile "[end] .setup-hadoop, HADOOP_HOME=$HADOOP_HOME, PATH=$PATH"
}
! ((_SKIP_SETUP_HADOOP)) && .setup-hadoop



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
#
# Relevant env:
# - GW_SKIP_REPORT  1 to bypass opening the report in default browser
gw-test() {
  local testTaskFull="$(egrep -o ':[^ ]+' <<< $@)"
  [[ -z "$testTaskFull" ]] && testTaskFull=':test'

  # save [project] and task without ':'
  local testProject testTask
  if [[ "$testTaskFull" =~ ^:[^:]+:[^:]+ ]]; then
    testProject="$(substring_before_last $testTaskFull ':')"
    testProject="${testProject//:/}"
  fi
  testTask="$(substring_after_last $testTaskFull ':')"

  GW_REPORT_DIR="build/reports/tests/$testTask"
  if [[ -n "$testProject" ]]; then
    [[ ! -d "$testProject" ]] && echo-error "gw-test: $testProject: No such directory"
    GW_REPORT_DIR="$testProject/$GW_REPORT_DIR"
  fi
  export GW_REPORT="$GW_REPORT_DIR/index.html"
  [[ -e "$GW_REPORT" ]] && rm -rf "$GW_REPORT_DIR"
  
  vecho-vars testTaskFull testProject testTask GW_REPORT_DIR GW_REPORT GW_SKIP_REPORT

  gw -Pshow-logs=true $@

  ((GW_SKIP_REPORT)) || qeval open "$GW_REPORT"
}
#
gw-test-deprecated() {
  local USAGE="Usage: gw-test [slow*|normal|fast*] [:testTask] [--tests] tests ..."
  [[ -z "$2" ]] && echo-error "$USAGE" && return 1
  local speed='normal'; [[ "$1" =~ slow.*|normal|fast.* ]] && speed="$1" && shift 1
  local testTask=':test'; [[ "$1" =~ ^:.+ ]] && testTask="$1" && shift 1
  [[ "$1" == '--tests' ]] && shift 1
  [[ -z "$1" ]] && echo-error "$USAGE" && return 1
  local tests="$1"; shift 1

  if [[ "$testTask" =~ ^:[^:]+:[^:]+ ]]; then
    local testSubProject="$(substring_before_last $testTask ':')"
    testTask=":$(substring_after_last $testTask ':')"
  fi

  # local excludes="-x:tag -x:version"
  # local excludes="$excludes -x:listDb -x:validateDb"
  # local excludes="$excludes -x:compileGroovy -x:compileTestGroovy -x:compileIntTestGroovy"

  GW_REPORT_DIR="build/reports/tests/${testTask//:/}"
  [[ -n "$testSubProject" ]] && GW_REPORT_DIR="${testSubProject//:/}/$GW_REPORT_DIR"
  export GW_REPORT="$GW_REPORT_DIR/index.html"
  vecho-vars speed testSubProject testTask tests GW_REPORT_DIR GW_REPORT
  rm -rf "$GW_REPORT_DIR"

  # gw-$speed $testTask $excludes --no-build-cache $@
  gw-$speed $testSubProject$testTask --no-build-cache --tests "$tests" $@

  ((GW_SKIP_REPORT)) || qeval open "$GW_REPORT"
}
#
int-copyJsp() {
  qeval gw --quiet :copyJsp $@
}
#
int-dbTestOracle() {
  [[ -z "$2" ]] && echo-error "Usage: int-dbTestOracle slow*|normal|fast* ..." && return 1
  qeval gw-test :dbTestOracle $@
}
int-dbIntTestOracle() {
  [[ -z "$2" ]] && echo-error "Usage: int-dbIntTestOracle slow*|normal|fast* ..." && return 1
  qeval gw-test :dbIntTestOracle $@
}
#
# Removed --configuration-cache since it often causes grief, even with problems=warn
gw-slowest()  { gw --info --no-build-cache --no-configure-on-demand  --no-configuration-cache $@; }
gw-slower()   { gw --no-build-cache --no-configure-on-demand  --no-configuration-cache $@; }
gw-slow()     { gw --no-build-cache --no-configure-on-demand  --no-configuration-cache $@; }
gw-normal()   { gw $@; }
gw-fast()     { gw --build-cache $@; }
gw-faster()   { gw --configure-on-demand --build-cache $@; }
gw-fastest()  { gw --offline --no-rebuild --dependency-verification=off --configure-on-demand --build-cache $@; }
#
app-start-slowest() { app-start gw-slowest $@; }
app-start-slower()  { app-start gw-slower $@; }
app-start-slow()    { app-start gw-slow $@; }
app-start() {
  local gw=gw-normal; [[ -n "$1" ]] && gw="$1" && shift 1
  local task=:start; [[ "$1" =~ ^:.+ ]] && task="$1" && shift 1
  local http_port=8081
  ncz -q $http_port && echo-error "app-start: Port $http_port already active" && return 1
  $gw $task $@
}
app-start-fast() { 
  app-start gw-fast $@
}
app-start-faster() { 
  app-start gw-faster \
    -x:validateDb -x:listDbs  -x:tag -x:version \
    $@
}
app-start-only() {
  app-start gw-fastest \
    -x:validateDb -x:listDbs  -x:tag -x:version \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    -x:compileJava -x:processResources -x:classes -x:war -x:explodeWar \
    -x:makeTomcatDirs -x:apiTomcatConfig \
    $@
}
#
int-clean()       { gw-slow :clean $@; }
app-clean-start() { gw-slow :clean :start $@; }
#
int-db-migrate()  { gw-normal :dbTaskInfoCore :dbTaskMigrateCore $@; }
#
api-start() {
  local gw=gw-normal; [[ -n "$1" ]] && gw="$1" && shift 1
  local task=:startApi; [[ "$1" =~ ^:.+ ]] && task="$1" && shift 1
  local http_port=9088
  ncz -q $http_port && echo-error "app-start: Port $http_port already active" && return 1
  $gw $task \
    -x:compileGroovy \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    $@
}
api-start-fast() {
  api-start gw-fast \
    -x:validateDb -x:listDbs  -x:tag -x:version \
    $@
}
api-start-faster() { 
  api-start gw-faster $@
}
api-start-only() { 
  api-start gw-fastest \
    -x:validateDb -x:listDbs  -x:tag -x:version \
    -x:compileJava -x:processResources -x:classes -x:war -x:explodeWar \
    -x:makeTomcatDirs -x:apiTomcatConfig \
    $@
}
#
rtd-start() {
  local gw="${1:-gw-normal}"
  local task="${2:-:startRtd}"
  $gw \
    -x:compileGroovy \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    $task $@
}
rtd-start-fast() {
  local gw="${1:-gw-fast}"
  local task="${2:-:startRtd}"
  $gw \
    -x:validateDb -x:listDb  -x:tag -x:version \
    -x:compileGroovy \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    $task $@
}
rtd-start-faster()  { rtd-start-fast gw-faster $@; }
rtd-start-only() { 
  local gw="${1:-gw-fast}"
  local task="${2:-:startRtd}"
  $gw \
    -x:validateDb -x:listDbs  -x:tag -x:version \
    -x:compileGroovy \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    -x:compileJava -x:processResources -x:classes -x:war -x:explodeWar \
    -x:makeTomcatDirs -x:apiTomcatConfig \
    $task $@
}
#
rtd-start2()          { rtd-start gw-normal :startRtd2 $@; }
rtd-start2-fast()     { rtd-start-fast gw-fast :startRtd2 $@; }
rtd-start2-faster()   { rtd-start-fast gw-faster :startRtd2 $@; }
rtd-start2-only()     { rtd-start-only gw-fastest :startRtd2 $@; }
#
rtd-db-migrate() { gw-normal :dbTaskInfoRtd :dbTaskMigrateRtd $@; }
#
eng-run() { 
  local gw="${1:-gw-normal}"
  local task="${2:-:runEngine}"
  $gw \
    -x:validateDb -x:listDb  -x:tag -x:version \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    $task $@
}
eng-run-fast() { 
  $gw \
    -x:validateDb -x:listDb  -x:tag -x:version \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    $task $@
}
eng-run-faster()  { eng-run-fast gw-faster $@; }
eng-run-only() {
  $gw \
    -x:validateDb -x:listDb  -x:tag -x:version \
    -x:concatCoreCommonJS -x:concatCoreMergedLegacyJS -x:concatTransactiondDetailJS -x:concatVendorJS \
    -x:nodeSetup -x:npmSetup -x:npmInstall -x:jsDist \
    -x:compileJava -x:node -x:war -x:explodeWar \
    $task $@
}
#
bin-clean-start()   { gw-slow :server:clean :server:start2 $@; }
bin-start()         { gw-normal :server:start2 $@; }
bin-start-fast()    { gw-fast :server:start2 $@; }
bin-start-faster()  { gw-faster :server:start2 $@; }
bin-start-only()    { gw-fastest :server:start2 $@; }
bin-client-pub()    { gw-normal :client:publishMavenJavaPublicationToMavenLocal $@; }
#
vert-start()         { gw-normal :start2 $@; }
vert-start-fastest() { gw-fastest :start2 $@; }
#
# For database unit test container; see: https://accertify.atlassian.net/wiki/spaces/SDLC/pages/2019229708/Dockerized+Oracle+and+Postgres+Database+for+Interceptas+Unit+Testing#Initial-Postgres-Steps
#
int-docker-ora-prepare-db()   { gw-slow :oraclePrepareDatabase $@; }
int-docker-ora-start()        { gw-slow :oracleStart $@; }
int-docker-ora-stop()         { gw-slow :oracleStop $@; }
#
int-docker-pg-prepare-db()    { gw-slow :postgresPrepareDatabase $@; }
int-docker-pg-start()         { gw-slow :postgresStart $@; }
int-docker-pg-stop()          { gw-slow :postgresStop $@; }
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
  gw-normal :bootRun -Pprofiles=queuewriter $@
}
minion-maprproxy-start() {
  gw-normal :bootRun -Pprofiles=maprproxy $@
}
minion-velociraptor-direct-start() {
  gw-normal :bootRun -Pprofiles=velociraptor-direct $@
}
minion-mv-start() {
  gw-normal :bootRun -Pprofiles=maprproxy,velociraptor-direct $@
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
# If command is sent directly, kill the terminal process immediately after.
tty-console() {
  local USAGE="usage: tty-console -p port [-s server] [-t timeout] [command]"
  local port server="localhost" timeout="1.5" tty_cmd
  while [[ -n "$1" ]]; do case "$1" in
    -p|--port )     port="$2"; shift 2;;
    -s|--server )   server="$2"; shift 2;;
    -t|--timeout )  timeout="$2"; shift 2;;
    *)              break;;
  esac; done
  tty_cmd="$@"
  _debug && echo-var server port timeout tty_cmd
  if [[ ! "$port" =~ ^[[:digit:]]{3,5}$ ]]; then
    echo-error "tty-console: missing or invalid port -- $port"
    echo-error "$USAGE"
    return 1
  fi

  # see https://superuser.com/a/410642/17666 for the echo/redirect magic
  local c="nc $server $port" cfull
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
tty-app() { qeval tty-console -p 9092 $@; }
tty-api() { qeval tty-console -p 9074 $@; }
tty-eng() { qeval tty-console -p 9090 $@; }
tty-rtd() { qeval tty-console -p 9094 $@; }
tty-bin() { qeval tty-console -p 9096 $@; }
tty-rad() { qeval tty-console -p 9999 $@; }
tty-ver() { qeval tty-console -p 9999 $@ || qeval tty-console -p 9998 $@; }
tapp()    { tty-app $@; }
tapi()    { tty-api $@; }
trtd()    { tty-rtd $@; }
#
tty-app-status() { tty-app status get; }
tty-app-status-up() { tty-app status set up; }
tty-app-reset-icnow() { qeval tty-app reset 44444 start; }
tty-app-cache-status() { qeval tty-app cachestatus; }
tty-app-cache-reset() { 
  [[ -z "$@" ]] && echo-error "usage: tty-app-cache-reset CACHE_NAME" && return 1
  qeval tty-app resetcache $@
}
tty-app-cache-reset-flex() { 
  qeval tty-app resetcache FlexValue
  qeval tty-app resetcache FLEX_VALUE2
}
tty-app-cache-reset-properties() { 
  qeval tty-app resetcache Property
  qeval tty-app resetcache PROPERTY_VALUE
  qeval tty-app resetcache Hierarchy.properties
}
tty-app-cache-reset-rules() { 
  qeval tty-app resetcache Rule
  qeval tty-app resetcache RuleType
  qeval tty-app resetcache RuleSet
  qeval tty-app resetcache RulesInRuleSet
}
#
tty-api-status() { tty-api status get; }
tty-api-status-up() { tty-api status set up; }
#
tty-rtd-status() { tty-rtd status get; }
tty-rtd-status-up() { tty-rtd status set up; }

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
