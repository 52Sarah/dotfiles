#!/usr/bin/env bash

# For debugging login files; this file should be included at the top of each.
# The __echo function should be called only if debugging is enabled;
# it will echo its arguments and write to __login.log if one of the following is true:
#   - the SH_DEBUG env var is already set
#   - script is called with --debug as its $1
#   - existence of ~/.login.debug.enabled file
#   - existence of ~/$script.debug file, where $script is ".profile", etc.

__echo() {
  if [[ -z "$__DATETIME" ]]; then
    export __DATETIME="$(datetime_plus_ms 3)"
  fi
  echo "$__DATETIME  $*" >> "$HOME/__login.log" 
}

# Usage: [ms places] [format]
type -t datetime_plus_ms &>/dev/null || \
datetime_plus_ms() {
  local places="${1:-3}" && shift
  local format="${1:-%D %T}" && shift
  local ms="$(perl - <<-'EOF'
    use Time::HiRes qw(time);
    my $t = time;
    printf "%06d\n", ($t - int($t)) * 1000000;
EOF
)00000"
  date +"$format.${ms:0:$places}"
}

# return status 0 if debugging should be enabled
# Usage: dot___login_debug [--debug] [--reset-datetime] [script_name] [date/time]
dot___login_debug() {
  if [[ -z "$__DATETIME" || "$2" =~ -r|--reset-datetime ]]; then
    export __DATETIME="$(datetime_plus_ms 3)"
  fi
  [[ "$1" =~ -d|--debug ]] && return 0

  local script="$1" && shift
  
  [[ -n "$SH_DEBUG" ]] && return 0
  [[ -e "$HOME/.__login.debug" ]] && return 0

  [[ -z "$1" ]] && return 1
  [[ -n "$script" && -e "$script.debug" ]] && return 0
  
  return 1
}
dot___login_debug "$@"
