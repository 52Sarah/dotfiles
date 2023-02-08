#!/usr/bin/env bash

# If .do-tick() is true, .tick logs to ~/.tick.log.
# Then it also echoes to stdout/stderr if TICK_STDOUT/TICK_STDERR is set.
# Optional .tick options:
#   --scriptname  used with '.tick' to determine whether this script's ticks should fire
#   --eval        evaluate expression before echoing it (good for potentially expensive messages)
#   --vars        log each variable given along with its value

# Return true (0) if tick is not disabled AND/OR is enabled for this script ($1).
.do-tick() {
  local scriptf="$1"
  local scriptv="${1//./dot_}"
  if [[ -n "$scriptv" ]]; then
    [[ -n "$(echo $TICK_${scriptv}_DISABLED)" || -e ~/.tick${scriptf}.disabled ]] && return 1
    [[ -n "$(echo $TICK_${scriptv}_ENABLED)" || -e ~/.tick${scriptvf}.enabled ]] && return 0
  fi
  [[ -n "$TICK_DISABLED" || -e ~/.tick.disabled ]] && return 1
  [[ -n "$TICK_ENABLED" || -e ~/.tick.enabled ]] && return 0
  return 1
}

.tick() {
  local script_name= opt_eval= opt_vars=
  while [[ "$1" =~ ^- ]]; do case "$1" in
    -s|--script) script_name="$2"; shift 2;;
    -e|--eval) opt_eval=1; shift;;
    -v|--vars) opt_vars=1; shift;;
    *) >&2 echo ".tick: $1: invalid option" && return 1;;
  esac; done
  .do-tick "$script_name" || return 1

  local msg=
  if ((opt_eval)); then
    msg="$(eval "$@")"
  elif ((opt_vars)); then
    for var in $@; do msg="$msg $var=${!var}"; done
  else
    msg="$@"
  fi

  # If delta is 10+ seconds, presume we've re-executed .tick in a new train of thought
  local datetime_ms="$(datetime-plus-ms 3 '%D %T')" epoch_ms="$(datetime-epoch-ms)" delta=0
  if ((TICK__LAST_MS)); then
    delta=$((epoch_ms - TICK__LAST_MS))
    ((delta >= 10000)) && delta=0
  fi
  if ((! delta)); then
    TICK__INDENT=0
    printf "\n" >> ~/.tick.log
  fi
  export TICK__LAST_MS=$epoch_ms

  # unindent for [finish]
  ((TICK__INDENT >= 2)) && [[ "$msg" =~ ^\[(finish|end|FINISH-FILE|END-FILE)\] ]] && ((TICK__INDENT -= 2))

  local tick_line="$(printf "%s +%4d %-13s %${TICK__INDENT}s%s" "$datetime_ms" "$delta" "$script_name" "" "$msg")"
  echo "$tick_line" >> ~/.tick.log
  ((TICK_STDOUT)) &&  echo "$tick_line"
  ((TICK_STDERR)) && >&2 echo "$tick_line"

  # indent for [start]
  [[ "$msg" =~ ^\[(start|START-FILE)\] ]] && ((TICK__INDENT += 2))

  return 0
}


# usage: [ms places] [format]
datetime-plus-ms() {
  local places="${1:-3}" && shift
  local format="${1:-%D %T}" && shift
  local ms="$(perl -e 'use Time::HiRes qw(time); my $t = time; printf "%06d", ($t - int($t)) * 1000000;')00000"
  date +"$format.${ms:0:$places}"
}

datetime-epoch-ms() {
  perl -e 'use Time::HiRes qw(time); printf "%d", time * 1000;'
}


.ticklog-tail()  { qeval tail $@ ~/.tick.log; }
.ticklog-less()  { qeval less $@ ~/.tick.log; }
.ticklog-rm()    { qeval rm -v $@ ~/.tick.log; }

alias .reload-tick='qeval . ~/.tick.sh'
