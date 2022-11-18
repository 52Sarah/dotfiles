#!/usr/bin/env bash

# If .do-tick() is true, .tick logs to ~/.tick.log.
# Then it also echoes to stdout/stderr if TICK_STDOUT/TICK_STDERR is set.
# Optional .tick options:
#   --scriptname  used with '.tick' to determine whether this script's ticks should fire
#                 (if omitted then ignore this check)
#   --eval        evaluate expression before echoing it (good for potentially expensive messages)
#   --vars        log each variable given along with its value

# Return true (0) if ~/.tick.enabled or .tick${sname}.enabled exists; e.g., .tick.bashrc.enabled
.do-tick() {
  [[ -e ~/.tick.enabled ]] && return 0
  [[ -z "$1" ]] && return 1
  [[ -e ~/.tick$1 ]]
}

.tick() {
  local sname= opt_eval= opt_vars=
  while [[ "$1" =~ ^- ]]; do case "$1" in
    -s|--script) sname="$2"; shift 2;;
    -e|--eval) opt_eval=1; shift;;
    -v|--vars) opt_vars=1; shift;;
    *) >&2 echo ".tick: $1: invalid option" && return 1;;
  esac; done
  .do-tick "$sname" || return 1

  local msg=
  if ((opt_eval)); then
    msg="$(eval "$@")"
  elif ((opt_vars)); then
    for var in $@; do msg="$msg $var=${!var}"; done
  else
    msg="$@"
  fi

  # If delta is longer than 5 seconds, presume we've re-executed .tick via .bashrc, most likely
  local epoch_ms=$(datetime-epoch-ms) delta=0
  ((TICK_LAST_MS)) && delta=$((epoch_ms - TICK_LAST_MS))
  ((delta > 5000)) && epoch_ms=
  export TICK_LAST_MS=$epoch_ms

  # unindent for [finish]
  ((${#TICK_INDENT} >= 2)) && [[ "$msg" =~ ^\[(FINISH|finish).+ ]] && export TICK_INDENT="${TICK_INDENT:0:((${#TICK_INDENT}-2))}"

  printf '+%4d %s %12s %s%b\n' $delta "$(datetime-plus-ms 3 '%D %T')" "$sname" "$TICK_INDENT" "$msg" >> ~/.tick.log
  # printf '%s %s %s%b\n' "$(date +'%D %T')" "$sname" "$TICK_INDENT" "$msg" >> ~/.tick.log
  if ((TICK_STDOUT)) || ((TICK_STDERR)); then
    # local tick_line=$(printf '.tick  %s %s %s%b\n' "$(datetime-plus-ms 3 '%T')" "$sname" "$TICK_INDENT" "$msg")
    local tick_line="$(printf '+%4d %s %12s %s%b' $delta "$(datetime-plus-ms 3 '%D %T')" "$sname" "$TICK_INDENT" "$msg")"
    ((TICK_STDOUT)) &&  echo "$tick_line"
    ((TICK_STDERR)) && >&2 echo "$tick_line"
  fi

  # indent for [start]
  [[ "$msg" =~ ^\[(START|start).+ ]] && export TICK_INDENT="$TICK_INDENT  "
  return 0
}

  # usage: [ms places] [format]
datetime-plus-ms() {
  local places="${1:-3}" && shift
  local format="${1:-%D %T}" && shift
  local ms="$(perl - <<-'EOF'
    use Time::HiRes qw(time);
    my $t = time;
    printf "%06d", ($t - int($t)) * 1000000;
  EOF
  )00000"
  date +"$format.${ms:0:$places}"
}

datetime-epoch-ms() {
  echo "$(perl - <<-'EOF'
    use Time::HiRes qw(time);
    printf "%d", time * 1000;
  EOF
  )"
}

.ticklog-tail()  { tail $@ ~/.tick.log; }
.ticklog-less()  { less $@ ~/.tick.log; }
.ticklog-rm()    { rm -v $@ ~/.tick.log; }
alias .tt='.ticklog-tail'  .tl='.ticklog-less'  .tr='.ticklog-rm'

test-tick() {
  
}

alias .reload-tick='. ~/.tick.sh'  .rlt='.reload-tick'


