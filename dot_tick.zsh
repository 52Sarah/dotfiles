#!/usr/bin/env zsh

# If .tick-enabled(), .tick logs to ~/.tick.log.
# Then it also echoes to stdout/stderr if .tick.stdout/err-enabled()
#
# Executes with Zsh or Bash.
# Dependencies are ONLY on .sh_bootstrap.
#
# Other .tick options:
#   --scriptname  used with '.tick' to determine whether this script's ticks should fire
#   --eval        evaluate expression before echoing it (good for potentially expensive messages)
#   --vars        log each variable given along with its value

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
#
.tick() {
  local script_name= opt_eval= opt_vars=
  while [[ "${1:0:1}" = '-' ]]; do case "$1" in
    -s|--script) script_name="$2"; shift 2;;
    -e|--eval) opt_eval=1; shift;;
    -v|--vars) opt_vars=1; shift;;
    *) echo-error ".tick: $1: invalid option" && return 1;;
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
  if ((_TICK_LAST_MS)); then
    delta=$((epoch_ms - _TICK_LAST_MS))
    ((delta >= 10000)) && delta=0
  fi
  if ! ((delta)); then
    _TICK_INDENT=0
    printf "\n" >> ~/.tick.log
  fi
  export _TICK_LAST_MS=$epoch_ms

  # unindent for [finish]
  if ((_TICK_INDENT >= 2)); then
    matches "$msg" '\[(finish|end|FINISH|END).*\]' >&/dev/null && ((_TICK_INDENT -= 2))
  fi

  local tick_line="$(printf "%s +%4d %-16s %${_TICK_INDENT}s%s" "$datetime_ms" "$delta" "$script_name" " " "$msg")"
  echo "$tick_line" >> ~/.tick.log
  .tick.stdout-enabled && echo "$tick_line"
  .tick.stderr-enabled && echo-stderr "$tick_line"

  # indent for [start]
  if matches "$msg" '\[(start|START).*\]'; then
     ((_TICK_INDENT += 2))
  fi
  return 0
}
#
.tick-start-line() {
  [[ -z "$2" ]] && echo-error "usage: .tick-start-line tick_fn dot_fname"
  local tick_fn=$1 dot_fname=$2
  $tick_fn "[START-FILE] shell:[$SHELL, $(shell-types)], \$PPID=$PPID, CMD='$(ps -o "command" -p $PPID | tail -1), mtime=$(file-mtime ~/$dot_fname)"
}
#
# Source the given file if it exists, logging before and after using the given .tick-* function.
.tick-and-source() {
  [[ -z "$2" ]] && echo-error "usage: .tick-and-source tick_fn sh_file"
  local tick_fn="$1" sh_file="$2"
  if [[ -e $sh_file ]]; then
    $tick_fn " ... reading $sh_file"
    source $sh_file
    $tick_fn " ... done reading $sh_file"
  fi
}

# usage: [ms places] [format]
datetime-plus-ms() {
  local places='3'; [[ -n "$1" ]] && places="$1" && shift
  local format='%D %T'; [[ -n "$1" ]] && format="$1" && shift
  local ms="$(perl -e 'use Time::HiRes qw(time); my $t = time; printf "%06d", ($t - int($t)) * 1000000;')00000"
  date +"$format.${ms:0:$places}"
}

datetime-epoch-ms() {
  perl -e 'use Time::HiRes qw(time); printf "%d\n", time * 1000;'
}


.ticklog-tail()  { touch ~/.tick.log; eval-quiet tail $@ ~/.tick.log; }
.ticklog-less()  { touch ~/.tick.log; eval-quiet less $@ ~/.tick.log; }
.ticklog-rm()    { eval-quiet rm -v $@ ~/.tick.log; }

alias .reload-tick='eval-quiet . ~/.tick'
