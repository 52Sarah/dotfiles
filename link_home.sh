#!/usr/bin/env bash

link_home() {(
    set -o errexit

    local SH_VERBOSE="$SH_VERBOSE"
    [[ "$1" =~ -?-v(erbose)? ]] && SH_VERBOSE=1 && shift
    [[ "$SH_VERBOSE" ]] && SH_VERBOSE="-v"

    # ~
    for d in $DOTFILES/dot_*; do
        local hname="$(basename "$d")"
        hname="$HOME/.${hname:4}"  # minus 'dot_'
        hname="${hname%.sh*}"      # minus '.sh'
        ln -sf $SH_VERBOSE "$d" "$hname"
    done
)}
link_home "$@"
