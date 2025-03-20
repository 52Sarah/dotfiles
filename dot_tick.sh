#!/usr/bin/env bash

# Executes with Zsh or Bash.
# If .tick-enabled(), .tick logs to ~/.tick.log.
# Then it also echoes to stdout/stderr if .tick.stdout/err-enabled()
# Other .tick options:
#   --scriptname  used with '.tick' to determine whether this script's ticks should fire
#   --eval        evaluate expression before echoing it (good for potentially expensive messages)
#   --vars        log each variable given along with its value

[[ -e ~/.sh_bootstraprc ]] && source ~/.sh_bootstraprc

# Return true (0) if tick is not disabled AND/OR is enabled for this script ($1).
.tick-enabled() {
  local scriptf="$1"
  if [[ -n "$scriptf" ]]; then
    [[ -e ~/.tick${scriptf}.disabled ]] && return 1
    [[ -e ~/.tick${scriptf}.enabled ]] && return 0
  fi
  [[ -e ~/.tick.disabled ]] && return 1
  [[ -e ~/.tick.enabled ]] && return 0
  .tick.stdout-enabled && return 0
  .tick.stderr-enabled && return 0
  return 1
}
#
.tick.stdout-enabled() { [[ -e ~/.tick.stdout ]]; }
.tick.stderr-enabled() { [[ -e ~/.tick.stderr ]]; }

.tick() {
  local script_name= opt_eval= opt_vars=
  while [[ "${1:0:1}" = '-' ]]; do case "$1" in
    -s|--script) script_name="$2"; shift 2;;
    -e|--eval) opt_eval=1; shift;;
    -v|--vars) opt_vars=1; shift;;
    *) >&2 echo ".tick: $1: invalid option" && return 1;;
  esac; done
  .tick-enabled "$script_name" || return 0

  local msg=
  if ((opt_eval)); then
    msg="$(eval $@)"
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
  if ! ((delta)); then
    _TICK_INDENT=0
    printf "\n" >> ~/.tick.log
  fi
  export TICK__LAST_MS=$epoch_ms

  # unindent for [finish]
  if ((_TICK_INDENT >= 2)); then
    matches "$msg" '^\[(finish|end|FINISH|END)' >&/dev/null && ((_TICK_INDENT -= 2))
  fi

  local tick_line="$(printf "%s +%4d %-6s %${_TICK_INDENT}s%s" "$datetime_ms" "$delta" "$script_name" "" "$msg")"
  echo "$tick_line" >> ~/.tick.log
  .tick.stdout-enabled &&  echo "$tick_line"
  .tick.stderr-enabled && >&2 echo "$tick_line"

  # indent for [start]
  matches "$msg" '^\[(start|START)' >&/dev/null && ((_TICK_INDENT += 2))

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
