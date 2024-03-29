#!/usr/bin/env bash

link_home() {(
    set -o errexit

    local _VERBOSE="$_VERBOSE"
    [[ "$1" =~ -?-v(erbose)? ]] && _VERBOSE=1 && shift
    [[ "$_VERBOSE" ]] && _VERBOSE="-v"

    # ~
    for d in $DOTFILES/dot_*; do
        local hname="$(basename "$d")"
        hname="$HOME/.${hname:4}"  # minus 'dot_'
        hname="${hname%.sh*}"      # minus '.sh'
        ln -sf $_VERBOSE "$d" "$hname"
    done
)}
link_home $@
