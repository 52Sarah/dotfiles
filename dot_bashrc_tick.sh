#!/usr/bin/env bash

.tick() { 
  local USAGE='usage: .tick[eval] -s script_name [msg|expr [...]]'
  [[ ! "$1" =~ ^-s|--script ]] && >&2 echo "$USAGE" && return 1
  local script_name="$2" && shift 2 && [[ -z "$script_name" ]] && echo "$USAGE" && return 1
  local dt="$(date +'%D %T')"
  printf "%s %-22s %s\n" "$dt" "$script_name" "$*" >> "$HOME/.tick.log"
}

# Like .tick but woth delayed evaluation of potentially expensive message
# Usage: .tickeval -s script_name [expr [...]]
.tickeval() {
  local sw="$1" nm="$2"
  shift 2
  .tick "$sw" "$nm" "$(eval "$*")"
}

.ttail() {
  local lines=${1:-20}; shift
  tail -n $lines ~/.tick.log
}
alias .trm='rm -v ~/.tick.log'

alias .rlbrt='. ~/.bashrc_tick'
