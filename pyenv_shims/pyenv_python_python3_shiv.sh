#!/usr/bin/env bash
set -e
[[ -n "$PYENV_DEBUG" ]] && set -x

program="${0##*/}"

if [[ "$program" == "python" && -n "$PYENV_ROOT" && -e "$PYENV_ROOT/shims/python3" ]]; then
  program="python3"
fi

exec "/usr/local/opt/pyenv/bin/pyenv" exec "$program" $@
