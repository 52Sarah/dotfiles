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
    ((_VERBOSE)) && echo "opt: '$opt'"

    if [[ "$opt" =~ ^(-a|--all)$ ]]; then
      for f in docker-compose.override.*.yaml; do
        dc_options="$dc_options -f "$f""
      done
      ((_VERBOSE)) && echo "dc_options: [$dc_options]"
    elif [[ "$opt" = '-v' ]]; then
      _VERBOSE=1 _QUIET=
    elif [[ "$opt" =~ ^(-q|--quiet)$ ]]; then
      _QUIET=1 _VERBOSE=
    elif [[ "$opt" =~ ^(-vv|--verbose)$ ]]; then
      _VERBOSE=1 _QUIET=
      dc_options="$dc_options --verbose"
    elif [[ -s "$opt" ]]; then
      dc_options="$dc_options -f "$opt""
      ((_VERBOSE)) && echo "dc_options: [$dc_options]"
    elif [[ -s "docker-compose.override.$opt.yaml" ]]; then
      dc_options="$dc_options -f 'docker-compose.override.$opt.yaml'"
      ((_VERBOSE)) && echo "dc_options: [$dc_options]"
    else
      local cmd="$opt"
      ((_VERBOSE)) && echo "cmd: '$cmd'"
      break
    fi

  done

  local cmd_options= #"--log-level WARN"
  while [[ "$1" ]]; do
    cmd_options="$cmd_options "$1""
    ((_VERBOSE)) && printf "cmd_opt: '%s'; cmd_options: [%s]" "$1" "cmd_options"
    shift
  done

  ! _quiet_on || printf ">>> docker-compose  %s  %s  %s\n\n" "$dc_options" "$cmd" "$cmd_options"
  docker-compose $dc_options $cmd $cmd_options
}

docker.compose.overrides $@
