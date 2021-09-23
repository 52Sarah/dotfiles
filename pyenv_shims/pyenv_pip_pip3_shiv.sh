#!/usr/bin/env bash
set -e
[[ -n "$PYENV_DEBUG" ]] && set -x

program="${0##*/}"

if [[ "$program" == "pip" && -n "$PYENV_ROOT" && -e "$PYENV_ROOT/shims/pip3" ]]; then
  program="pip3"
fi

exec "/usr/local/opt/pyenv/bin/pyenv" exec "$program" "$@"
