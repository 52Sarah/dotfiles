#!/usr/bin/env bash

docker.compose.overrides() {
  local orig_pwd=
  if [[ ! -s "./docker-compose.yaml" ]]; then
    if [[ ! -s "./local/docker-compose.yaml" ]]; then
      1>&2 echo "docker.compose.overwrite: cannot find docker-compose.yaml or local/docker-compose.yaml"
      return 1
    fi
    orig_pwd="$PWD"
    cd "./local"
  fi

  [[ -z "$1" ]] && 1>&2 echo "docker.compose.overwrite: usage: docker.compose.overwrite [file ...] compose_command [compose option ...]" && return 1

  local dc_options="-f docker-compose.yaml"
  while [[ "$1" ]] && local opt="$1" && shift; do
    ((SH_VERBOSE)) && echo "opt: '$opt'"

    if [[ "$opt" =~ ^(-a|--all)$ ]]; then
      for f in docker-compose.override.*.yaml; do
        dc_options="$dc_options -f "$f""
      done
      ((SH_VERBOSE)) && echo "dc_options: [$dc_options]"
    elif [[ "$opt" = '-v' ]]; then
      SH_VERBOSE=1 SH_QUIET=
    elif [[ "$opt" =~ ^(-q|--quiet)$ ]]; then
      SH_QUIET=1 SH_VERBOSE=
    elif [[ "$opt" =~ ^(-vv|--verbose)$ ]]; then
      SH_VERBOSE=1 SH_QUIET=
      dc_options="$dc_options --verbose"
    elif [[ -s "$opt" ]]; then
      dc_options="$dc_options -f "$opt""
      ((SH_VERBOSE)) && echo "dc_options: [$dc_options]"
    elif [[ -s "docker-compose.override.$opt.yaml" ]]; then
      dc_options="$dc_options -f 'docker-compose.override.$opt.yaml'"
      ((SH_VERBOSE)) && echo "dc_options: [$dc_options]"
    else
      local cmd="$opt"
      ((SH_VERBOSE)) && echo "cmd: '$cmd'"
      break
    fi

  done

  local cmd_options= #"--log-level WARN"
  while [[ "$1" ]]; do
    cmd_options="$cmd_options "$1""
    ((SH_VERBOSE)) && printf "cmd_opt: '%s'; cmd_options: [%s]" "$1" "cmd_options"
    shift
  done

  ((SH_QUIET)) || printf ">>> docker-compose  %s  %s  %s\n\n" "$dc_options" "$cmd" "$cmd_options"
  docker-compose $dc_options $cmd $cmd_options
}

docker.compose.overrides "$@"
