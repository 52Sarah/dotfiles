#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Our stuff is mainly in .bash_profile since this file is executed for every process.


# If debugging is not enabled, overwrite __echo with a no-op.
if [[ -e ~/.tick.enabled ]]; then
  __echo() { echo "$@"; }
else
  __echo() { :; }
fi
# . $HOME/.__login.debug ".bashrc" --reset-datetime || __echo() { :; }
__echo "[.bashrc] starting:  pid: $$, ppid: $PPID, -='$-', SHLVL=$SHLVL"


#? export ICLOUD="$HOME/iCloud"
export DRIVE="$HOME/Drive"

export BAK="$HOME/bak"
export BIN="$HOME/bin"
export DOTFILES="$HOME/dotfiles"
export NOTES="$HOME/notes"
export PREFS="$HOME/prefs"

#? export SUBLIME_PACKAGES="$HOME"'/Library/Application Support/Sublime Text 3/Packages'


# Put my homemade scripts and other miscellany here at the start of the classpath.
[[ -d "$HOME/bin" && ! "$PATH" =~ $HOME/bin ]] && export PATH="$HOME/bin:$PATH"


# error, info, verbose and debug levels; uses SH_ vars which can be set pre-execution or generally via -q, -v and -d
echo-info() { ((SH_QUIET)) || echo "$@"; return 0; }
echo-verbose() { ((SH_VERBOSE || SH_DEBUG)) && echo "$@"; return 0; }
echo-debug() { ((SH_DEBUG)) && echo "$@"; return 0; }
echo-error() { >&2 echo "$@"; return 0; }  # to stderr
alias iecho=echo-info vecho=echo-verbose decho=echo-debug eecho=echo-error

echo-eval()  {
  local echo_level='echo'
  [[ "$1" =~ -l|--level ]] && echo_level="echo-$2" && shift 2
  $echo_level '>$ '$*
  eval $*
}
eecho-eval() { echo-eval --echo eecho "$@"; }
iecho-eval() { echo-eval --echo iecho "$@"; }
vecho-eval() { echo-eval --echo vecho "$@"; }
decho-eval() { echo-eval --echo decho "$@"; }

# "What-if" echo: if SH_WHATIF env var is set, simply echo the given command; else ieval it.
wecho-eval() {
    local cmd="$*"
    [[ -n "$SH_WHATIF" && ! "${SH_WHATIF,,}" =~ 0|false ]] && echo "# WHATIF> $cmd" && return 0
    iecho-eval "$cmd"
} && \
alias wecho='wecho-eval'


is-valid-symlink() {
    [[ ! "$1" ]] && eecho "is_broken_link: missing argument" && return 1
    [[ -L "$1" && -e "$1" ]] 
}



# Inspect $1 and, using javascript-like truthy rules, return status 0 (true) or 1 (false).
# Usage: parse-bool [--echo] value
# If --echo is specified, 1 or nothing is echoed to stdout; else just the status is returned.
# Examples, in each case leaving some_var == 1 (if value is true) or empty (false).
# - parse-bool "true" && some_var=1
# - some_var=$(parse-bool --echo "true")
# Truthiness:
# - false: <unset>, "", "0", "false", "no", "null" or "undefined"
# - true:  any non-blank that doesn't evaluate to false is true
parse-bool() {
    [[ "$1" =~ -?-e(cho)? ]] && do_echo=1 && shift
    val="$1"; shift

    # ret=0: true; ret=1: false; but echo 1 for true, nothing for false. Nice.
    ret=0
    [[ -z "$val" || "$val" =~ ^(0|false|no|null|undefined)$ ]] && ret=1

    [[ -n "$do_echo" && $ret == 0 ]] && echo "1"
    return $ret
}

join-array() {
    local delim="$1" && shift
    local i_first=1
    [[ -n "$SH_DEBUG" ]] && echo_vars delim i_first "$@"
    for i in "$@"; do
        [[ -n "$SH_VERBOSE" ]] && eecho "i=$i"
        [[ -n "$i_first" ]] && printf "%s" "$i" && unset i_first || printf "%s%s" "$delim" "$i"
    done
    printf '\n'
}

uniq-array() {
    local i_first=1
    [[ -n "$SH_DEBUG" ]] && eecho_vars delim i_first "$@"
    local buff=
    for i in "$@"; do
        [[ -n "$SH_VERBOSE" ]] && eecho "i=$i"
        if (( i_first )); then
            buff="$i"
            unset i_first
        else
            buff="$(printf '%s\n%s' "$buff" "$i")"
        fi
    done
    echo "$buff" | sort -s | uniq
}

# Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
join-lines() {
    delim="${1:-, }"
    sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
}

# Expand '~' to value of $HOME, or compress value of $HOME to ~
tilde-compress() {
  [[ -z "$1" ]] && eecho "usage: tilde-compress path [...]" && return 1
  tilde-home-compress-expand 'tilde-compress' '${path/$HOME/\~}' "$@"
}
tilde-expand() {
  [[ -z "$1" ]] && eecho "usage: tilde-expand path [...]" && return 1
  tilde-home-compress-expand 'tilde-expand' '${path/\~/$HOME}' "$@"
}
#
# Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
home-compress() {
  [[ -z "$1" ]] && eecho "usage: home-compress path [...]" && return 1
  tilde-home-compress-expand 'home-compress' '${path/$HOME/\$HOME}' "$@"
}
home-expand() {
  [[ -z "$1" ]] && eecho "usage: home-expand path [...]" && return 1
  tilde-home-compress-expand 'home-expand' '${path/\$HOME/$HOME}' "$@"
}
#
tilde-home-compress-expand() {
  local fn_name="$1" && shift
  local expr="$1" && shift
  [[ -z "$1" ]] && eecho "usage: ${fn_name:-fn_name} path [...]" && return 1
  local delim=
  while [[ -n "$1" ]]; do
    local path="$1" && shift
    printf '%s%s' "$delim" "$(eval "echo $expr")"
    delim=' '
  done
  printf '\n'
}

# If $1 exists, source it; if not, exit quietly (with an optional verbose note)
safe-source-script() {
  [[ -z "$1" ]] && eecho "usage: safe-source-script script_file" && return 1
  local script_file="$1" && shift
  [[ ! -e "$script_file" ]] && vecho "safe-source-script: '$script_file': not found; skipping" && return 0
  . "$script_file"
}

alias .reload-bashrc=". $HOME/.bashrc"
alias .rlbrc='.reload-bashrc'


#? # Load over-engineered shell functions and aliases.
#? if ls $HOME/.bashrc__* >& /dev/null; then
#?   __echo "[.bashrc] sourcing files: $(tilde-compress $HOME/.bashrc__*)"
#?   for dotpath in $HOME/.bashrc__*; do
#?   __echo "[.bashrc] sourcing $(tilde-compress $dotpath)"
#?   . "$dotpath"
#?   done
#? else
#?   __echo "[.bashrc] no $(tilde-compress $HOME)/.bashrc__* files to parse"
#? fi


__echo "[.bashrc] finishing: pid: $$, ppid: $PPID"
