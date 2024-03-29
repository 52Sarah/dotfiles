#!/usr/bin/env bash

export _TICK_ON=1 _TICK_STDERR=1

nfails=0

test-echo-printf-verbose() {
  local cmd="$1"; shift
  for _VERBOSE in '' 0 1; do
    local out="$($cmd 'foo')"
    local pass=FAIL
    ((_VERBOSE)) && [[ "$out" = 'foo' ]] && pass=pass
    ! ((_VERBOSE)) && [[ -z "$out" ]] && pass=pass
    printf "%-5s: %s([%s],'foo'): '%s'\n" "$pass" "$cmd" "$_VERBOSE" "$out"
    [[ "$pass" == "FAIL" ]] && ((nfails++))
  done
}
test-echo-printf-verbose echo-verbose
test-echo-printf-verbose printf-verbose
echo '----'

test-echo-printf-quiet() {
  for _QUIET in '' 0 1; do
    local actual="$(echo_unquiet 'foo')"
    local pass=FAIL
    ! _quiet_on && [[ -z "$actual" ]] && pass=pass
    ! ! _quiet_on && [[ "$actual" = 'foo' ]] && pass=pass
    printf "%-5s: echo_unquiet([%s],'foo'): '%s'\n" "$pass" "$_QUIET" "$actual"
    [[ "$pass" == "FAIL" ]] && ((nfails++))
  done
}
test-echo-printf-quiet echo_unquiet
test-echo-printf-quiet printf-quiet
echo '----'

# echo-error()    { >&2 echo $@; }


test-echo-glob() {
  for input in 'XYZ' 'PATH' 'BASH_ARG' 'BASH_V*'; do
    local actual="$(echo-glob "$input")"
    local pass=FAIL
    if [[ "$input" = 'XYZ' ]]; then
      [[ -z "$actual" ]] && pass=pass
    elif [[ "$input" =~ \*$ ]]; then
      [[ "$actual" =~ ${input:0:-1} ]] && pass=pass
    else
      [[ "$actual" =~ $input ]] && pass=pass
    fi
    printf "%-5s: echo-glob([%s]):\n%s\n--\n" "$pass" "$input" "$actual"
    [[ "$pass" == "FAIL" ]] && ((nfails++))
  done
}
test-echo-glob


# printf-error()    { >&2 printf $@; }

test-substrings() {
  local fn_name="$1" input="$2" expected="$3"; shift 3
  local actual="$(eval echo "\$($fn_name '$input')")"
  local pass=FAIL; [[ "$expected" == "$actual" ]] && pass=pass
  printf "%-5s: %s('%s','.'): expected '%s', actual '%s'\n" "$pass" "$fn_name" "$input" "$expected" "$actual"
}
test-substrings substring_before_first  'd1/d2/d3/f1.f2.f3' 'd1/d2/d3/f1'
test-substrings substring_before_last   'd1/d2/d3/f1.f2.f3' 'd1/d2/d3/f1.f2'
test-substrings substring_after_first   'd1/d2/d3/f1.f2.f3' 'f2.f3'
test-substrings substring_after_last    'd1/d2/d3/f1.f2.f3' 'f3'

echo '----'



printf "========\nnfails: %d\n" $nfails


# # Replace newlines, carriage-returns and tabs with \n, \r and \t.
# echo-unescape() {
#   if [[ ! -t 0 ]]; then
#     sed -E -n 'l;' \
#     | join-lines '\\n' \
#     | sed -E 's/\$(\\n)/\1/g; s/\$$//g;'
#     return 0;
#   fi
#   [[ -z "$1" ]] && eecho 'usage: echo-unescape text [...] or echo-unescape <<< text' && return 1
#   echo-unescape <<< $@
# }



# ### 'echo'/'eval' helpers
# #
# # Conditionally echo the expression to stderr before executing it, using similar logic as echo-* and printf-*.
# : ${EVAL_ECHO_PREFIX:=\>$}
# eval-echo()     { >&2 echo "$EVAL_ECHO_PREFIX $@"; eval $@; }
# eval-verbose()  { >&2 echo-verbose "$EVAL_ECHO_PREFIX $@"; eval $@; }
# eval-quiet()    { >&2 echo_unquiet "$EVAL_ECHO_PREFIX $@"; eval $@; }
# eval-error()    { >&2 echo-error "$EVAL_ECHO_PREFIX $@"; eval $@; }
# #
# alias veval='eval-verbose'
# alias qeval='eval-quiet'
# alias eeval='eval-error'
# #
# # Always ECHO the given expression; but do not EVAL if _WHATIF is set.
# : ${EVAL_WHATIF_PREFIX:=#$}
# eval-whatif()   { ((_WHATIF)) && echo "$EVAL_WHATIF_PREFIX" $@ || eval-echo $@; }
# alias weval='eval-whatif'


# #
# ### 'find' helpers
# #   -L = follow symlinks
# #   -E = use extended (modern) regexes
# alias nfind='qeval find -L . -name'
# alias pfind='qeval find -L . -path'
# alias rfind='qeval find -L -E . -regex'


# #
# ### 'ls' helpers
# #
# # -A  show .* files except for '.'' and '..'
# # -d  list directories as plain files, not recursed
# #
# # -H  follow only symlink arguments
# # -L  follow all symlinks
# # -P  follow no symlinks
# #
# # -1  ("one") 1-column output
# # -l  ("el") use long form, show owner and group
# # -g  use long form, suppress owner
# # -o  use long form, suppress group
# # -h  use human-readable file sizes
# # -F  add file suffix [/, @, *, ...]
# #
# # -tr sort by time modified, old to new
# # -Sr sort by size, ascending
# #
# alias l1='qeval ls -1F'
# alias l1r='qeval l1 -r'
# #
# alias ll='ls -oghF'
# alias llt='qeval ll -t'
# alias lltr='qeval ll -tr'
# alias lls='qeval ll -S'
# alias llsr='qeval ll -Sr'
# #
# alias la='ll -A'
# alias lat='qeval la -t'
# alias latr='qeval la -tr'
# alias las='qeval la -S'
# alias lasr='qeval la -Sr'
# #
# alias l1d='qeval l1 -d'
# alias lad='qeval la -d'
# #
# # Think "ll and la but narrower": cut out permissions, link count and owner.
# #   $ ls -ohF
# #   total 520
# #   -rw-r--r--  1 toddpierzina   1.2K Mar 10 11:33 README.md
# # $1: permissions, $2: inode count, $3: owner, $4: size, $5: date/time, $6: filename
# lln() {
#   ls -oF $@ \
#   | sed -E \
#     -e '/^total .+$/d' \
#     -e 's/^([^ ]{9,}) +([[:digit:]]+) +([^ ]+) +([^ ]+) ([^ ]+ +[^ ]+ +[^ ]+) +(.+)$/\4'$'\t''\5'$'\t''\6/' \
#     -e "s:\\$HOME:\\~:g" \
#   | awk -F$'\t' \
#     '{printf "%12'$'\'''d  %s  %s\n", $1, $2, $3}'
# }
# alias lan='lln -A'
# #
# # Display permissions in octal, from: http://askubuntu.com/a/152005
# # I've tried to figure out how this works but have no fucking clue.
# lso() {
#   ls -ohF $@ \
#   | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' \
#   | sed -E -e "s:\\$HOME:\\~:g"
# }


# ### 'rm' helpers
# #
# # Delete the target of a symlink, then the symlink.
# rm-ln() {
#   local cmd="rm"
#   while [[ "$1" =~ ^- ]]; do cmd="$cmd $1" && shift; done

#   local link="$1" && shift
#   [[ -z "$link" ]] && eecho "usage: rmln [rm opts] symlink" && return 1
#   [[ ! -L "$link" ]] && eecho "rmln: $link: no such symlink" && return 1

#   local dest="$(readlink "$link")"
#   [[ ! -e "$dest" ]] && eecho "rmln: $link -> $dest: no such file or directory" && return 1
#   qeval "$cmd '$dest'"
# }


# #
# ### 'tail' helpers
# #
# alias t='tail'
# alias tf='tail -f'

# #
# ### path helpers
# #
# # Add given path element to the beginning of the variable, or move it there if already present.
# # usage: path-prepend [var] path
# path-prepend() {
#   local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
#   local elem="$1" && shift
#   local elements="${!var}"
#   [[ "$elements" = "$elem" ]] && return 0
#   local deduped_elems="$(sed -e 's!:'"$elem"':!:!g' <<< ":$elements:")"
#   export $var="$elem${deduped_elems:0:-1}"
# }
# #
# # List path variables' elements, 1 per line.
# path-list() {
#   ! (($#)) && echo-error 'usage: path-list PATHVAR [...]' && return 1
#   local var=${1:-PATH}
#   split-lines ':' <<< "${!var}"
# }
# alias path-echo='qeval path-list'


# # The following functions operate on stdin OR $@; [[ -t 0 ]] is true if stdin is a terminal
# # from: https://stackoverflow.com/a/30520299
# #
# trim() {
#   [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g' && return 0
#   [[ -z "$1" ]] && >&2 echo "usage: trim str [...], or ... | trim" && return 1
#   trim <<< $@
# }
# rtrim() {
#   [[ ! -t 0 ]] && sed -E -e 's/(.*)[[:space:]]*/\1/g' && return 0
#   [[ -z "$1" ]] && >&2 echo "usage: rtrim str [...], or ... | rtrim" && return 1
#   rtrim <<< $@
# }
# ltrim() {
#   [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)/\1/g' && return 0
#   [[ -z "$1" ]] && >&2 echo "usage: ltrim str [...], or ... | ltrim" && return 1
#   ltrim <<< $@
# }
# #
# upper() {
#   [[ ! -t 0 ]] && tr '[:lower:]' '[:upper:]' && return 0
#   [[ -z "$1" ]] && >&2 echo "usage: upper word [...], or ... | upper" && return 1
#   upper <<< $@
# }
# lower() {
#   [[ ! -t 0 ]] && tr '[:upper:]' '[:lower:]' && return 0
#   [[ -z "$1" ]] && >&2 echo "usage: lower word [...], or ... | lower" && return 1
#   lower <<< $@
# }

# # Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
# join-lines() {
#   local delim="${1:-, }" && shift
#   local not_1st=
#   sed -E -e 's/^ *(.+) *$/\1/;' \
#   | while read -r line; do
#       ((not_1st)) && printf "$delim" || not_1st=1
#       printf "%s" "$line"
#     done \
#   && printf '\n'
# }
# # Split line(s) from stdin into separate lines, using $1 [,] as delimiter
# split-lines() {
#     local delim="${1:-,}"
#     sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
# }


# # Source given file(s). If a file does not exist, echo_unquiet a warning and ignore.
# # Usage: safe-source [--quiet] file [...]
# safe-source() {
#   local _QUIET=$_QUIET
#   [[ "$1" =~ ^(-q|--quiet)$ ]] && _QUIET=1 && shift
#   [[ -z "$1" ]] && echo-error "usage: safe-source [--quiet] file [...]" && return 1
#   while [[ -n "$1" ]]; do
#     local script_path="$1"; shift
#     if [[ ! -e "$script_path" ]]; then
#       ! ! _quiet_on && echo-error "safe-source: $script_path: No such file"
#     else
#       eval-quiet . "$script_path"
#     fi
#   done
# }

# .tidy_system_path() {
#   local old_path="$PATH"

#   # Homebrew expects sbin to be in the path.
#   path-prepend PATH "/usr/local/sbin"

#   # Put my homemade scripts and other miscellany here at the start of the classpath.
#   path-prepend PATH "/usr/local/opt/gnu-tar/libexec/gnubin"
#   path-prepend PATH "$HOME/bin"
#   # echo "PATH_3: HOME, HOME/bin, /usr/local/opt/gnu-tar/libexec/gnubin"
#   # path-list PATH

#   [[ "$old_path" == "$PATH" ]] && return 0

#   .tick-bashrc ".tidy_system_path: PATH updated from:"
#   local IFS=:; for p in $old_path; do .tick-bashrc ": $p"; done
#   .tick-bashrc ".tidy_system_path: PATH updated to:"
#   local IFS=:; for p in $PATH; do .tick-bashrc ": $p"; done
# }
# #? .tidy_system_path
# #
# #!!!!!

# ####
# #

# # error, info, verbose and debug levels; uses _ vars which can be set pre-execution or generally via -q, -v and -d
# echo-info() { ! _quiet_on || echo $@; return 0; }
# echo-verbose() { ((_VERBOSE || _DEBUG)) && echo $@; return 0; }
# echo-debug() { ((_DEBUG)) && echo $@; return 0; }
# echo-error() { >&2 echo $@; return 0; }  # to error
# alias iecho=echo-info vecho=echo-verbose decho=echo-debug eecho=echo-error

# echo-eval()  {
#   local echo_level='echo'
#   [[ "$1" =~ -l|--level ]] && echo_level="echo-$2" && shift 2
#   $echo_level '>$ '$*
#   eval $*
# }
# eecho-eval() { echo-eval --echo eecho $@; }
# iecho-eval() { echo-eval --echo iecho $@; }
# vecho-eval() { echo-eval --echo vecho $@; }
# decho-eval() { echo-eval --echo decho $@; }

# # "What-if" echo: if _WHATIF env var is set, simply echo the given command; else ieval it.
# wecho-eval() {
#     local cmd="$*"
#     [[ -n "$_WHATIF" && ! "${_WHATIF,,}" =~ 0|false ]] && echo "# WHATIF> $cmd" && return 0
#     iecho-eval "$cmd"
# } && \
# alias wecho='wecho-eval'


# is-valid-symlink() {
#     [[ ! "$1" ]] && eecho "is_broken_link: missing argument" && return 1
#     [[ -L "$1" && -e "$1" ]] 
# }



# # Inspect $1 and, using javascript-like truthy rules, return status 0 (true) or 1 (false).
# # Usage: parse-bool [--echo] value
# # If --echo is specified, 1 or nothing is echoed to stdout; else just the status is returned.
# # Examples, in each case leaving some_var == 1 (if value is true) or empty (false).
# # - parse-bool "true" && some_var=1
# # - some_var=$(parse-bool --echo "true")
# # Truthiness:
# # - false: <unset>, "", "0", "false", "no", "null" or "undefined"
# # - true:  any non-blank that doesn't evaluate to false is true
# parse-bool() {
#     [[ "$1" =~ -?-e(cho)? ]] && do_echo=1 && shift
#     val="$1"; shift

#     # ret=0: true; ret=1: false; but echo 1 for true, nothing for false. Nice.
#     ret=0
#     [[ -z "$val" || "$val" =~ ^(0|false|no|null|undefined)$ ]] && ret=1

#     [[ -n "$do_echo" && $ret == 0 ]] && echo "1"
#     return $ret
# }

# join-array() {
#     local delim="$1" && shift
#     local i_first=1
#     [[ -n "$_DEBUG" ]] && echo_vars delim i_first $@
#     for i in $@; do
#         [[ -n "$_VERBOSE" ]] && eecho "i=$i"
#         [[ -n "$i_first" ]] && printf "%s" "$i" && unset i_first || printf "%s%s" "$delim" "$i"
#     done
#     printf '\n'
# }

# uniq-array() {
#     local i_first=1
#     [[ -n "$_DEBUG" ]] && eecho_vars delim i_first $@
#     local buff=
#     for i in $@; do
#         [[ -n "$_VERBOSE" ]] && eecho "i=$i"
#         if (( i_first )); then
#             buff="$i"
#             unset i_first
#         else
#             buff="$(printf '%s\n%s' "$buff" "$i")"
#         fi
#     done
#     echo "$buff" | sort -s | uniq
# }

# # Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
# join-lines() {
#     delim="${1:-, }"
#     sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
# }

# # Expand '~' to value of $HOME, or compress value of $HOME to ~
# tilde-compress() {
#   [[ -z "$1" ]] && eecho "usage: tilde-compress path [...]" && return 1
#   tilde-home-compress-expand 'tilde-compress' '${path/$HOME/\~}' $@
# }
# tilde-expand() {
#   [[ -z "$1" ]] && eecho "usage: tilde-expand path [...]" && return 1
#   tilde-home-compress-expand 'tilde-expand' '${path/\~/$HOME}' $@
# }
# #
# # Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
# home-compress() {
#   [[ -z "$1" ]] && eecho "usage: home-compress path [...]" && return 1
#   tilde-home-compress-expand 'home-compress' '${path/$HOME/\$HOME}' $@
# }
# home-expand() {
#   [[ -z "$1" ]] && eecho "usage: home-expand path [...]" && return 1
#   tilde-home-compress-expand 'home-expand' '${path/\$HOME/$HOME}' $@
# }
# #
# tilde-home-compress-expand() {
#   local fn_name="$1" && shift
#   local expr="$1" && shift
#   [[ -z "$1" ]] && eecho "usage: ${fn_name:-fn_name} path [...]" && return 1
#   local delim=
#   while [[ -n "$1" ]]; do
#     local path="$1" && shift
#     printf '%s%s' "$delim" "$(eval "echo $expr")"
#     delim=' '
#   done
#   printf '\n'
# }
# #
# ###

# alias .reload-bashrc='qeval . ~/.bashrc'

# .tick-bashrc "[END-FILE  ] (\$\$=[$$], \$_=[$_], \$PATH=[$PATH])"


# #? # Load over-engineered shell functions and aliases.
# #? if ls $HOME/.bashrc__* >& /dev/null; then
# #?   __echo "[.bashrc] sourcing files: $(tilde-compress $HOME/.bashrc__*)"
# #?   for dotpath in $HOME/.bashrc__*; do
# #?   __echo "[.bashrc] sourcing $(tilde-compress $dotpath)"
# #?   . "$dotpath"
# #?   done
# #? else
# #?   __echo "[.bashrc] no $(tilde-compress $HOME)/.bashrc__* files to parse"
# #? fi
