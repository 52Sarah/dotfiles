#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Our stuff is in .bash_profile.

# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1


# If debugging is not enabled, overwrite __echo with a no-op.
. $HOME/.__login.debug ".bashrc" || __echo() { :; }
__echo $"--------"
__echo "[.bashrc] starting; pid: $$, ppid: $PPID, -='$-', SHLVL=$SHLVL, PS1='$PS1'"


export ICLOUD="$HOME/iCloud"
export DRIVE="$HOME/Drive"
export DROPBOX="$HOME/Dropbox"

export BAK="$HOME/bak"
export BIN="$HOME/bin"
export DOTFILES="$HOME/dotfiles"
export NOTES="$HOME/notes"
export PREFS="$HOME/prefs"

export SUBLIME_PACKAGES="$HOME/Library/Application Support/Sublime Text 3/Packages"


# Put my homemade scripts and other miscellany here at the start of the classpath.
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# Simplify embeddeding newlines in strings and setting IFS.
CR=$'\n'

# error, info, verbose and debug levels; uses SH_ vars which can be set pre-execution or generally via -q, -v and -d
iecho() { ((SH_QUIET)) || echo "$@"; return 0; }
vecho() { ((SH_VERBOSE || SH_DEBUG)) && echo "$@"; return 0; }
decho() { ((SH_DEBUG)) && echo "$@"; return 0; }
eecho() { >&2 echo "$@"; return 0; }  # to stderr


#
### MAVEN
#
# "Maven List", describe the plugins, phases and goals for a given project or projects.
# Created based on https://stackoverflow.com/a/35610377/529256
#
[[ -e "${MAVEN_HOME:-$HOME/.m2}/settings.xml" ]] &&\
mvnl() {
  local SH_QUIET=$SH_QUIET SH_VERBOSE=$SH_VERBOSE
  local goal='list-phase' build_plan='clean,deploy' dirs= mvn_opts=

  while [[ -n "$1" ]]; do
    local opt="$1" && shift
    case "$opt" in
      -h|--help)
        echo "Lists the goals of mvn project(s) by phase in a table"
        echo
        echo "Usage:"
        echo "    mvnl [-v|--verbose | -q|--quiet]  -g|--goal goal  -b|--build_plan build_plan [mvn_opt ...] [dir ...]"
        echo
        echo "           --goal  The goal for the buildplan-maven-plugin (default: $goal)"
        echo "                   (possible values: list, list-plugin, list-phase)"
        echo
        echo "     --build_plan  The value of the buildplan.tasks parameter (default: $build_plan)"
        echo "                   (examples: 'clean,install', 'deploy', 'install', etc...) "
        echo
        echo "     [*directory]  The directories (with pom.xml files) to run the command in"
        return 0;;
      -v|--verbose)
          SH_VERBOSE=1;;
      -q|--quiet)
          SH_QUIET=1;;
      -b|--build_plan)
          build_plan="$1" && shift
          [[ -z "$build_plan" ]] && eecho "mvnl: -b|--build-plan requires a parameter, comma-separated tasks; e.g., 'clean,install', 'deploy', 'install'" && return 1
          ;;
      -g|--goal)
          goal="$1" && shift
          [[ -z "$goal" ]] && eecho "mvnl: -g|--goal requires a parameter, one of: [list, list-plugin, list-phase]" && return 1
          ;;
      -*)
          [[ -z "$mvn_opts" ]] && mvn_opts="$opt" || mvn_opts="$mvn_opts $opt";;
      *)
          local dir="$opt"
          [[ ! -d "$dir" ]] && eecho "mvnl: $dir: No such directory" && return 1
          [[ ! -e "$dir/pom.xml" ]] && eecho "mvnl: $dir: No pom.xml found" && return 1
          dir="$(tilde_compress "$dir")"
          [[ -z "$dirs" ]] && dirs="'$dir'" || dirs="$dirs '$dir'"
          ;;
    esac
  done

  [[ -z "$dirs" ]] && dirs="$PWD"
  vecho "goal='$goal', build_plan='$build_plan', dirs=[$dirs], mvn_opts=[$mvn_opts]"

  for dir in $dirs; do
    local mvn_cmd='mvn' && [[ -e "$dir/mvnw" ]] && mvn_cmd='./mvnw'
    iecho "cd $dir"
    pushd $dir > /dev/null
    iecho "$mvn_cmd fr.jcgay.maven.plugins:buildplan-maven-plugin:$goal -Dbuildplan.tasks=$build_plan $mvn_opts"
    $mvn_cmd fr.jcgay.maven.plugins:buildplan-maven-plugin:$goal -Dbuildplan.tasks=$build_plan $mvn_opts
    popd > /dev/null
  done
}


# If $1, $2 are --echo xecho then use 'xecho' instead of 'echo', where x is i, v, d or e
echo_and_eval()  {
    local echo_fn="echo"
    [[ "$1" == "--echo" ]] && echo_fn="$2" && shift 2
    local cmd="$(strip_prefix "$*" "$ ")"
    $echo_fn "$ $cmd"
    eval "$cmd"
}
eecho_and_eval() { echo_and_eval --echo eecho "$@"; }
iecho_and_eval() { echo_and_eval --echo iecho "$@"; }
vecho_and_eval() { echo_and_eval --echo vecho "$@"; }
decho_and_eval() { echo_and_eval --echo decho "$@"; }

# "What-if" echo: if WHAT_IF env var is set, simply echo the given command; else iecho then execute it.
wecho_and_eval() {
    local cmd="$*"
    [[ -n "$SH_WHATIF" && ! "${SH_WHATIF,,}" =~ 0|false ]] && echo "# WHATIF> $cmd" && return 0
    iecho_and_eval "$cmd"
} && \
alias wecho='wecho_and_eval'


is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_cygwin() { [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" =~ ^cygwin.* ]]; }
is_ubuntu() { grep -s "ID=.?ubuntu.?" /etc/os-release >& /dev/null; }
is_centos() { grep -E -s "ID=.?centos.?" /etc/os-release >& /dev/null; }
is_amazon() { grep -E -s "ID=.?amzn.?" /etc/os-release >& /dev/null; }


# If $1 is defined, echo "alias", "keyword", "function", "builtin" or "file".
# If not defined, echo "" and return error status.
typeof_command() {
    type -t "$1"
    return  # type -t fails silently if not defined
}

alias_defined() { [[ "$(typeof_command "$1")" = "alias" ]]; }
function_defined() { [[ "$(typeof_command "$1")" = "function" ]]; }
executable_exists() { [[ "$(typeof_command "$1")" = "file" ]]; }

is_valid_symlink() {
    [[ ! "$1" ]] && eecho "is_broken_link: missing argument" && return 1
    [[ -L "$1" && -e "$1" ]] 
}


# For each variable name, echo as "var = value"; display arrays and hashes nicely.
echo_vars() {
    local USAGE=$(cat <<-EOF
  echo_vars: usage: echo_vars [-e env_prefix] [-t title -p prefix -q quote -w nchars -h] var [var ...]
  In addition to switches, corresponding env vars can be set:
  -e --env-prefix ECHO_VARS_ENV_PREFIX  V for vecho, D for decho, W for wecho; prefix for env vars
  E.g., use VECHO_VARS_TITLE if env-prefix is 'V'
  -t --title      ECHO_VARS_TITLE       Row written above the loop, with no added indentation
  -p --prefix     ECHO_VARS_PREFIX      Text, often whitespace, to write at start of each line
  -q --quote      ECHO_VARS_QUOTE       Delimit each value with single quotes
  -w --width      ECHO_VARS_WIDTH       Minimum width for variable name; default is 8
  -h --home       ECHO_VARS_HOME        Substitue ~ for $HOME
  -n --noblanks   ECHO_VARS_NOBLANKS    Suppress blank/undefined variables
  -f --files      ECHO_VARS_FILES       Note existing filenames with [*] at end
  EOF
    )

    # Incoming environment variables act as defaults. The prefix allows the caller to have different
    # defaults in place for each command.
    if [[ "$1" =~ ^-e|^--env-prefix ]]; then
        ECHO_VARS_ENV_PREFIX="$2" && shift 2
    fi
    if [[ -n "$ECHO_VARS_ENV_PREFIX" ]]; then
        for var in  ECHO_VARS_TITLE ECHO_VARS_PREFIX ECHO_VARS_QUOTE ECHO_VARS_WIDTH ECHO_VARS_HOME ECHO_VARS_NOBLANKS; do
            # Excellent or horriblw bash scripting...basically doing this, for each ECHO_VARS_ variable (assuming prefix V):
            # if [[ -n "$VECHO_VARS_TITLE" ]]; then ECHO_VARS_TITLE="$VECHO_VARS_TITLE"; fi
            if [[ -n $(eval echo "\$$ECHO_VARS_ENV_PREFIX$var") ]]; then
                eval "${var}=\$$ECHO_VARS_ENV_PREFIX$var"
            fi
        done
        # decho "After ECHO_VARS_ prefix copying:"
        # [[ -n "$ECHO_VARS_ENV_PREFIX" ]] && decho "  ECHO_VARS_ENV_PREFIX = $ECHO_VARS_ENV_PREFIX"
        # [[ -n "$ECHO_VARS_TITLE" ]] && decho "  ECHO_VARS_TITLE = $ECHO_VARS_TITLE"
        # [[ -n "$ECHO_VARS_PREFIX" ]] && decho "  ECHO_VARS_PREFIX = $ECHO_VARS_PREFIX"
        # [[ -n "$ECHO_VARS_QUOTE" ]] && decho "  ECHO_VARS_QUOTE = $ECHO_VARS_QUOTE"
        # [[ -n "$ECHO_VARS_WIDTH" ]] && decho "  ECHO_VARS_WIDTH = $ECHO_VARS_WIDTH"
        # [[ -n "$ECHO_VARS_HOME" ]] && decho "  ECHO_VARS_HOME = $ECHO_VARS_HOME"
        # [[ -n "$ECHO_VARS_NOBLANKS" ]] && decho "  ECHO_VARS_NOBLANKS = $ECHO_VARS_NOBLANKS"
    fi

    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -t|--title )    ECHO_VARS_TITLE="$2" && shift  ;;
            -p|--prefix )   ECHO_VARS_PREFIX="$2" && shift  ;;
            -q|--quote )    ECHO_VARS_QUOTE=1  ;;
            -w|--width )    ECHO_VARS_WIDTH="$2" && shift  ;;
            -h|--home )     ECHO_VARS_SUB_HOME=1  ;;
            -n|--noblanks ) ECHO_VARS_NOBLANKS=1  ;;
            -f|--files )    ECHO_VARS_FILES=1  ;;
            -v|--verbose )  SH_VERBOSE=1  ;;
            -- )            break  ;;
            * )             eecho "Unexpected switch: '$1'" && return 1  ;;
        esac
        shift
    done
    [[ -z "$1" ]] && echo "$USAGE" && return 1

    ECHO_VARS_WIDTH=$(( - ${ECHO_VARS_WIDTH:-0} ))  #left-justify
    [[ -n "$ECHO_VARS_QUOTE" ]] && ECHO_VARS_QUOTE="'"
    # decho "After options parsed:"
    # decho "  ECHO_VARS_TITLE = $ECHO_VARS_TITLE"
    # decho "  ECHO_VARS_PREFIX = $ECHO_VARS_PREFIX"
    # decho "  ECHO_VARS_QUOTE = $ECHO_VARS_QUOTE"
    # decho "  ECHO_VARS_WIDTH = $ECHO_VARS_WIDTH"
    # decho "  ECHO_VARS_HOME = $ECHO_VARS_HOME"
    # decho "  ECHO_VARS_NOBLANKS = $ECHO_VARS_NOBLANKS"

    [[ -n "$ECHO_VARS_TITLE" ]] && echo "$ECHO_VARS_TITLE"
    for var in "$@"; do
        #local var="$(echo "$var" | xargs)"

        local var_typeof=$(eval "typeof $var")
        if [[ "$var_typeof" =~ undefined|null ]]; then
            [[ -z "$ECHO_VARS_NOBLANKS" ]] && printf "%s%${ECHO_VARS_WIDTH}s = %s\\n" "$ECHO_VARS_PREFIX" "$var" "<$var_typeof>"
            continue
        fi

        local var_array="$(eval "echo \$\\{${var}[@]\\}")"
        local var_array_length="$(eval "echo \$\\{#${var}[@]\\}")"
        local var_array_length_value="$(eval "echo $var_array_length")"
        ## decho "var: $var, _typeof: $var_typeof, _array: $var_array, _length: $var_array_length, _value: $var_array_length_value"

        local var_array_value="$(eval "echo $var_array")"
        [[ -n "$ECHO_VARS_SUB_HOME" ]] && var_array_value="${var_array_value/$HOME/\~}"
        local var_array_keys="$(eval "echo \$\\{!${var}[@]\\}")"
        local var_array_keys_value="$(eval "echo $var_array_keys")"
        ## decho "var: $var, _array_value: $var_array_value, _array_keys: $var_array_keys, _value: $var_array_keys_value"

        # empty array or hash
        if [[ $var_array_length_value -eq 0 && -z "$ECHO_VARS_NOBLANKS" ]]; then
            if [[ "$var_typeof" = "array" ]]; then
                printf "%s%${ECHO_VARS_WIDTH}s = %s\\n" "$ECHO_VARS_PREFIX" "$var" "[]"
                continue
            elif [[ "$var_typeof" = "hash" ]]; then
                printf "%s%${ECHO_VARS_WIDTH}s = %s\\n" "$ECHO_VARS_PREFIX" "$var" "{}"
                continue
            fi
        fi

        # scalar
        if [[ "$var_array_keys_value" = "0" ]]; then
            ## decho "scalar: var = $var, var_array_keys_value = '$var_array_keys_value'"
            if [[ -n "$var_array_value" || -z "$ECHO_VARS_NOBLANKS" ]]; then
                # note if this is an existing filename
                if [[ -n "$ECHO_VARS_FILES" && -e "$var_array_value" ]]; then
                    if [[ -L "$var_array_value" ]]; then
                        var_array_value="$var_array_value [l]"
                    elif [[ -d "$var_array_value" ]]; then
                        var_array_value="$var_array_value [d]"
                    else
                        var_array_value="$var_array_value [f]"
                    fi
                fi
                printf "%s%${ECHO_VARS_WIDTH}s = ${ECHO_VARS_QUOTE}%s${ECHO_VARS_QUOTE}\\n" \
                "$ECHO_VARS_PREFIX" "$var" "$var_array_value"
            fi
            continue
        fi

        # array or hash
        # local maxlen=$(( 0 - $ECHO_VARS_WIDTH))
        # for k in $(eval echo "$var_array_keys"); do
        #   [[ $maxlen -lt ${#k} ]] && maxlen=${#k}
        # done
        # decho -n "$ECHO_VARS_PREFIX" && echo -n "$var = "
        echo -n "$var "
        [[ "${var_array_keys_value:0:2}" = "0 " ]] && echo "[" || echo "{"
        for k in $(eval echo "$var_array_keys"); do
            local val_cmd="printf '%s' \"\${${var}[$k]}\""
            ## decho "echo_vars: val_cmd: '$val_cmd'"

            local val="$(eval "$val_cmd")"
            [[ -n "$SH_DEBUG" ]] && printf "echo_vars: k: '%s', val: '%s'\\n" "$k" "$val"

            # note if this is an existing filename
            if [[ -n "$ECHO_VARS_FILES" && -e "$val" ]]; then
                if [[ -L "$val" ]]; then
                    val="$val [l]"
                elif [[ -d "$val" ]]; then
                    val="$val [d]"
                else
                    val="$val [f]"
                fi
            fi
            printf "%s  %${ECHO_VARS_WIDTH}s : ${ECHO_VARS_QUOTE}%s${ECHO_VARS_QUOTE}\\n" \
            "$ECHO_VARS_PREFIX" "$k" "$val"
        done
        [[ "${var_array_keys_value:0:2}" = "0 " ]] && echo "$ECHO_VARS_PREFIX]" || echo "$ECHO_VARS_PREFIX}"

    done
}
iecho_vars() { [[ -z "$SH_QUIET" ]] && echo_vars -e I "$@"; return 0; }
eecho_vars() { >&2 echo_vars -e E "$@"; }
vecho_vars() { ([[ -n "$SH_VERBOSE"||-n "$SH_DEBUG" ]]) && echo_vars -e V "$@"; return 0; }
decho_vars() { [[ -n "$SH_DEBUG" ]] && echo_vars -e D "$@"; return 0; }

# Returns 1 of:
# - undefined
# - null
# - scalar
# - array
# - hash
# - unknown
typeof() {
    local var="$1"
    [[ -z "$var" ]] && eecho "usage: typeof var" && return 1

    read -r opt expr <<< "$(declare -p "$var" 2> /dev/null | cut -d' ' -f 2-3)"
    #decho "var=$var, opt=$opt, expr=$expr"
    [[ -z "$opt$expr" ]] && echo "undefined" && return 0
    [[ "$opt" = "-A" ]] && echo "hash" && return 0
    [[ "$opt" = "-a" ]] && echo "array" && return 0
    [[ "$expr" =~ .+=.+ ]] && echo "scalar" && return 0
    [[ "$expr" =~ .+ ]] && echo "null" && return 0
    echo "unknown"
}


# Inspect $1 and, using javascript-like truthy rules, return status 0 (true) or 1 (false).
# Usage: parse_bool [--echo] value
# If --echo is specified, 1 or nothing is echoed to stdout; else just the status is returned.
# Examples, in each case leaving some_var == 1 (if value is true) or empty (false).
# - parse_bool "true" && some_var=1
# - some_var=$(parse_bool --echo "true")
# Truthiness:
# - false: <unset>, "", "0", "false", "no", "null" or "undefined"
# - true:  any non-blank that doesn't evaluate to false is true
parse_bool() {
    [[ "$1" =~ -?-e(cho)? ]] && do_echo=1 && shift
    val="$1"; shift

    # ret=0: true; ret=1: false; but echo 1 for true, nothing for false. Nice.
    ret=0
    [[ -z "$val" || "$val" =~ ^(0|false|no|null|undefined)$ ]] && ret=1

    [[ -n "$do_echo" && $ret == 0 ]] && echo "1"
    return $ret
}

join_array() {
    local delim="$1" && shift
    local i_first=1
    [[ -n "$SH_DEBUG" ]] && echo_vars delim i_first "$@"
    for i in "$@"; do
        [[ -n "$SH_VERBOSE" ]] && eecho "i=$i"
        [[ -n "$i_first" ]] && printf "%s" "$i" && unset i_first || printf "%s%s" "$delim" "$i"
    done
    printf '\n'
}

uniq_array() {
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

strip_prefix() {
    text="$1" && shift
    prefix="$1" && shift
    ([[ -z "$text" ]] || [[ -z "$prefix" ]]) && eecho "ERROR: Usage strip_prefix text prefix" && return 1
    echo "$text" | sed -E -e "s:^${prefix//\:\\:}::; s:^${prefix//\$/\\$}::;"
}

# Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
join_lines() {
    delim="${1:-, }"
    sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
}

seconds_apart() {
    local before="$1" && shift
    local after="$1" && shift
    echo $(( $(date +%s -d "$after") - $(date +%s -d "$before") ))
}

# Scale memory numbers to TB/GB/MB/KB; $1 = bytes, $2 = places [1]
nice_byte_size() {
    local orig="$(from_stdin)"
    [[ -z "$orig" ]] && orig="$1" && shift
    local places="${1:-1}" && shift

    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+$ ]] && echo "$orig" && return 0

    local nice="$cleaned_orig"
    if [[ $nice -ge $((1024*1024*1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024*1024*1024)")\ TB
    elif [[ $nice -ge $((1024*1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024*1024)")\ GB
    elif [[ $nice -ge $((1024*1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024*1024)")\ MB
    elif [[ $nice -ge $((1024)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1024)")\ kb
    fi

    echo "$nice"
}

# Scale milliseconds to d/h/m/s; $1 = milliseconds, $2 = places [1]
nice_milliseconds() {
    local orig="$1"; shift
    local places="${1:-1}"; shift
    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+$ ]] && echo "$orig" && return 0

    local nice=$cleaned_orig
    if [[ $nice -gt $((1000*60*60*24)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60*60*24)")d
    elif [[ $nice -gt $((1000*60*60)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60*60)")h
    elif [[ $nice -gt $((1000*60)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000*60)")m
    elif [[ $nice -gt $((1000)) ]]; then
        nice=$(bc -l <<< "scale=$places; $nice/(1000)")s
    fi

    echo "$nice"
}

# Insert commas into large numbers
commafy() {
    local orig="$1"; shift
    cleaned_orig="${orig//,/}"
    [[ -z "$cleaned_orig" ]] && return 1
    [[ ! $cleaned_orig =~ ^[[:digit:]]+.*$ ]] && eecho "$orig" && return 1

    local nice=$cleaned_orig
    for i in {1..10}; do
        [[ ! $nice =~ [[:digit:]]{4,} ]] && break
        nice=$(echo "$nice" | sed -E 's/([[:digit:]])([[:digit:]]{3})([^[:digit:]]|$)/\1,\2\3/g;')
    done

    echo "$nice"
}

# Expand '~' to value of $HOME, or compress value of $HOME to ~
tilde_compress() {
  [[ -z "$1" ]] && eecho "usage: tilde_compress path [...]" && return 1
  tilde_home_compress_expand 'tilde_compress' '${path/$HOME/\~}' "$@"
}
tilde_expand() {
  [[ -z "$1" ]] && eecho "usage: tilde_expand path [...]" && return 1
  tilde_home_compress_expand 'tilde_expand' '${path/\~/$HOME}' "$@"
}
#
# Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
home_compress() {
  [[ -z "$1" ]] && eecho "usage: home_compress path [...]" && return 1
  tilde_home_compress_expand 'home_compress' '${path/$HOME/\$HOME}' "$@"
}
home_expand() {
  [[ -z "$1" ]] && eecho "usage: home_expand path [...]" && return 1
  tilde_home_compress_expand 'home_expand' '${path/\$HOME/$HOME}' "$@"
}
#
tilde_home_compress_expand() {
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
safe_source_script() {
  [[ -z "$1" ]] && eecho "usage: safe_source_script script_file" && return 1
  local script_file="$1" && shift
  [[ ! -e "$script_file" ]] && vecho "safe_source_script: script file '$script_file' not found, skipping" && return 0
  . "$script_file"
}

alias .reload-bashrc=". $HOME/.bashrc"
alias .rlbrc='.reload-bashrc'


# Load over-engineered shell functions and aliases.
ls $HOME/.bashrc__* >& /dev/null && \
  __echo "[.bashrc] sourcing files: $(tilde_compress $HOME/.bashrc__*)"
	for dotpath in $HOME/.bashrc__*; do
    __echo "[.bashrc] sourcing $(tilde_compress $dotpath)"
    . "$dotpath"
	done


__echo "[.bashrc] finished"
__echo $"--------"
