#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# ch-bash-profile's .bash_profile runs this user-specific script if it exists.


# Don't show the 'zsh is the default shell' message.
export BASH_SILENCE_DEPRECATION_WARNING=1


# Leverage the CCHH startup tick for debugging
if [[ -e "$HOME/.tick.bash_profile.$USER" ]]; then
  export CCHH_BASH_STARTUP_PROFILE=1
  _tick() { 
    cchh_bash_startup_tick "[.bash_profile.$USER]" "$@" 2>> "$HOME/.tick.log"
  }
  _tickeval() { # delayed evaluation
    cchh_bash_startup_tick "[.bash_profile.$USER]" "$(eval "$@")" 2>> "$HOME/.tick.log"
  }
  _tick "----"
else
  unset CCHH_BASH_STARTUP_PROFILE
  _tick() { :no_op; }
  _tickeval() { :no_op; }
fi


# Put my homemade scripts and other miscellany here at the start of the classpath.
[[ -d "$HOME/bin" && ! "$PATH" =~ $HOME/bin ]] && export PATH="$HOME/bin:$PATH"


# error, info, verbose and debug levels; uses SH_ vars which can be set pre-execution or generally via -q, -v and -d
iecho() { ((SH_QUIET)) || echo "$@"; return 0; }
vecho() { ((SH_VERBOSE || SH_DEBUG)) && echo "$@"; return 0; }
decho() { ((SH_DEBUG)) && echo "$@"; return 0; }
eecho() { >&2 echo "$@"; return 0; }  # to stderr


set -o vi
export EDITOR=vim
export CLICOLOR=1 CLICOLOR_FORCE=1

# See: https://ss64.com/bash/less.html
export LESS='--quit-at-eof --quit-if-one-screen --hilite-search --LONG-PROMPT --RAW --squeeze --HILITE-UNREAD --no-init --shift=.25'
export LESSEDIT='subl --new-window --wait --stay %f\:%lm'

shopt -s extglob

# WHen closing a session, add to history instead of overwriting
shopt -s histappend

shopt -s cdspell

# Store multi-line commands as one line in history
shopt -s cmdhist


# Ignore repeated lines and lines starting with ' '
export HISTCONTROL=ignoreboth
export HISTSIZE=100000
export HISTFILESIZE=$HISTSIZE
export HISTTIMEFORMAT=' %F %T  '

# Exclude from tab completion
export FIGNORE='DS_Store:Icon?'


# -o show owner (-l includes group), -h human file sizes, -F suffix (/@)
alias ll='ls -ohF'
alias lltr='ls -ohFtr'
alias llsr='ls -ohFSr'
alias la='ls -AohF'
alias lA='ls -aohF'
alias latr='ls -AohFtr'

# Think "ll and la but narrower": cut out permissions, link count and owner.
# $ ls -ohF
# total 520
# -rw-r--r--  1 toddpierzina   1.2K Mar 10 11:33 README.md
lln() {
  # $1: permissions
  # $2: inode count
  # $3: owner
  # $4: size
  # $5: date/time
  # $6: filename
  ls -oF "$@" |\
  sed -E \
    -e '/^total .+$/d' \
    -e 's/^([^ ]{9,}) +([[:digit:]]+) +([^ ]+) +([^ ]+) ([^ ]+ +[^ ]+ +[^ ]+) +(.+)$/\4'$'\t''\5'$'\t''\6/' |\
  awk -F$'\t' \
    '{printf "%12'$'\'''d  %s  %s\n", $1, $2, $3}'
}
lan() { lln -A "$@"; }

# Display permissions in octal, from: http://askubuntu.com/a/152005
# I've tried to figure out how this works but have no fucking clue.
lso() {
    ls -ohF "$@" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}';
    ls -ohF "$@" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}';
}

alias nfind='find -L . -name '
alias pfind='find -L . -path '
alias rfind='find -L -E . -regex '

# Oops, return to where I was, if possible.
uncd() {
    [[ -z "$OLDPWD" ]] && eecho 'uncd: cannot determine prior directory' && return 1
    [[ ! -d "$OLDPWD" ]] && eecho 'uncd: $OLDPWD: prior directory no longer exists' && return 1
    cd "$OLDPWD"
}

# Make specified, or all in PWD, shell scripts executable.
chx() {
    local opt_verbose=$(( SH_VERBOSE ))
    [[ "$1" =~ ^(-v|--verbose)$ ]] && shift && opt_verbose=1
    
    local files=("$@")
    [[ ! "$1" ]] && files=(*.sh) && opt_verbose=1

    (( opt_verbose )) && opt_verbose="-vv" || opt_verbose=
    chmod $opt_verbose +x "${files[@]}"
}

# history-grep
hg() { if [[ -z "$1" ]]; then history; else history | grep -E "$*"; fi }


#
### PS1 COMMAND LINE PROMPT
#
# - if unset, leave unset (non-interactive shell)
# - if last command was in error, display "!" prefix before "$" and before line sep
# - `history -a` explicitly flushes the session history to the history file
# __git_ps1 shows the current git branch, if any, and is configured below
# - \u = user, \h = hostname, \w = working dir
#
prompt_command() {
  local prev_status=$?
  [[ -z "$PS1" ]] && return 0

  history -a
  local _pprefix && ((prev_status)) && _pprefix="!\$" || _pprefix="\$"
  export PS1="\\w $_pprefix "
  # export PS1='--\n$(__git_ps1 "[%s]") \w $_pprefix '
  # export GITBR="$(git branch --show-current 2> /dev/null)"
  # __git_ps1 "$_sep\n" " \w $_pprefix\$ " "[%s]"'
}
export PROMPT_COMMAND='prompt_command'


#
###  GIT
#
# Enable git prompt and completion if installed.
#
_setup_git() {
  ! type -t git &>/dev/null && _tick "git not installed" && return 0
  _tickeval 'echo "using $(git --version)"'

  alias g='git'
  
  export __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
  if [[ -e "$__GIT_PROMPT_DIR/gitprompt.sh" ]]; then
    _tick "using git-prompt in $__GIT_PROMPT_DIR"
    export GIT_PROMPT_ONLY_IN_REPO=1
    export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
    export GIT_PROMPT_END_USER='\n\w \$ '
    export GIT_PROMPT_START_USER='_LAST_COMMAND_INDICATOR_'
    # export GIT_PROMPT_SHOW_UPSTREAM=1
    # export GIT_PROMPT_THEME=Custom # use custom theme specified in file GIT_PROMPT_THEME_FILE (default ~/.git-prompt-colors.sh)
    # export GIT_PROMPT_THEME_FILE=~/.git-prompt-colors.sh
    # export GIT_PROMPT_THEME=Solarized # use theme optimized for solarized color scheme
    . "$__GIT_PROMPT_DIR/gitprompt.sh"
  else
    _tick "not using git-prompt"
  fi
  _tick "PS1: [$PS1]; PROMPT_COMMAND=[$PROMPT_COMMAND]"

  # if [[ -e "$HOME/.git-prompt.sh" ]]; then
  #   export GIT_PS1_SHOWDIRTYSTATE=1 GIT_PS1_SHOWUNTRACKEDFILES=1 GIT_PS1_SHOWUPSTREAM=1 GIT_PS1_SHOWCOLORHINTS=1
  #   export GIT_PS1_STATESEPARATOR='|' GIT_PS1_DESCRIBE_STYLE='branch' GIT_PS1_HIDE_IF_PWD_IGNORED=1
  #   . "$HOME/.git-prompt.sh"
  #   _tick "loaded git-prompt, PS1=$PS1"
  # fi
  if [[ -e "$HOME/.git-completion" ]]; then
    _tick "loading git completion from $HOME"
    . "$HOME/.git-completion"
  fi
  complete -p | grep -E -q 'git$' && _tick "loaded git cli completion" || _tick "not using git completion"
}
_setup_git


#
### JAVA/JENV
#
_setup_java() {
  ! type -t jenv &>/dev/null && _tick "jenv not installed" && return 0

  if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
    _tick "jenv already initialized"
  else
    _tick "initializing jenv"
    eval "$(jenv init -)"
    [[ ! "$PATH" =~ \.jenv/bin ]] && export PATH="$HOME/.jenv/bin:$PATH"
    _tick "initialized jenv, PATH: [$PATH]"
  fi
  _tickeval 'echo "using $(jenv --version), version=$(jenv version)"'
  
  _tick "trying to set JAVA_HOME from jenv"
  local javahome="$(jenv javahome)"
  if [[ -z "$javahome" || ! -d "$javahome" || -d "$javahome/bin" ]]; then
    _tick "jenv reports a non-existent or invalid JAVA_HOME: [$javahome]"
  else
    [[ -n "$JAVA_HOME" ]] && tick "changing JAVA_HOME from [$JAVA_HOME]"
    export JAVA_HOME="$javahome"
  fi
  _tick "using JAVA_HOME: [$JAVA_HOME]"
}
_setup_java


#
### PYTHON
#
# Set up Python aliases, tools and completion if installed.
_setup_pyenv() {
  ! type -t pyenv &>/dev/null && _tick "pyenv not installed"
  if [[ "$(type -t pyenv 2>/dev/null)" == "function" ]]; then
    _tick "pyenv already initialized"
  else
    _tick "initializing pyenv"
    export PYENV_HOME="$HOME/.pyenv"
    [[ ! $"PATH" =~ $PYENV_HOME/bin ]] && export PATH="$PYENV_HOME/bin:$PATH" && _tick "PATH: [$PATH]"
    eval "$(pyenv init -)"
  fi
  _tickeval 'echo "using $(pyenv --version 2>/dev/null), version=$(pyenv version)"'
}
#
_setup_python() {
  ! type -t python &>/dev/null && _tick "python not installed" && return 0

  _tickeval 'echo "using python version: $(python --version)"'
  _tickeval 'echo "using pip version: $(pip --version)"'

  _tick "initializing pip completion"
  eval "$(python -m pip completion --bash)"
  complete -p | grep -E -q 'pip$' && _tick "loaded pip cli completion"
}
_setup_pyenv
_setup_python


#
### MAVEN
#
# "Maven List", describe the plugins, phases and goals for a given project or projects.
# Created based on https://stackoverflow.com/a/35610377/529256
#
[[ -e "${MAVEN_HOME:-$HOME/.m2}/settings.xml" ]] && \
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


is_valid_symlink() {
    [[ -z "$1" ]] && eecho "usage: is_broken_link link" && return 1
    [[ -L "$1" && -e "$1" ]] 
}


# Inspect $1 and, using javascript-like truthy rules, return status 0 (true) or 1 (false).
# Usage: parse_bool [--echo] value
# If --echo is specified, true or false is echoed to stdout; else just the status is returned.
# Examples, in each case leaving some_var == 1 (if value is true) or empty (false).
# - parse_bool "true" && some_var=1
# - some_var=$(parse_bool --echo "true")
# Truthiness:
# - false: <unset>, "", "0", "false", "no", "null" or "undefined"
# - true:  any non-blank that doesn't evaluate to false is true
parse_bool() {
  local do_echo && [[ "$1" =~ -?-e(cho)? ]] && do_echo=1 && shift
  local val=$(tr '[a-z]' '[A-Z]' "$1"); shift

  # ret=0: true; ret=1: false; but echo 1 for true, nothing for false. Nice.
  local ret=0
  [[ -z "$val" || "$val" =~ ^(0|f|false|off|no|null|undefined)$ ]] && ret=1

  if ((do_echo)); then
    ((ret)) && echo 'false' || echo 'true'
  fi
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

# Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
join_lines() {
    delim="${1:-, }"
    sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
}


# Usage: [ms places] [format]
datetime_plus_ms() {
  local places="${1:-3}" && shift
  local format="${1:-%D %T}" && shift
  local ms="$(perl - <<-'EOF'
    use Time::HiRes qw(time);
    my $t = time;
    printf "%06d\n", ($t - int($t)) * 1000000;
EOF
)00000"
  date +"$format.${ms:0:$places}"
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

# For each link in @$, echo OKAY or ERROR. If --quiet is specified, only show ERRORs.
checkln() {
    local USAGE="checkln [--recursive] [--quiet] [link ...]${CR}       default link is each link/dir in PWD"
    local maxdepth='-maxdepth 1' SH_QUIET=$SH_QUIET
    while [[ "$1" =~ ^--?.+$ ]]; do
        case "$1" in
            -r|--recursive) maxdepth='';;
            -q|--quiet)     SH_QUIET=1;;
            *) eecho "$USAGE" && return 1;;
        esac
        shift
    done

    local files=("$@")
    [[ ! "$1" ]] && files=(.* *)

    # Loop over each incoming argument, executing find on each.
    for file in "${files[@]}"; do
        if [[ -L "$file" ]]; then
            find "$file" $maxdepth -type l | sort |\
            while read -r link; do
                [[ ! -L "$link" ]] && continue
                local target="$(readlink "$link")"
                if [[ -e "$target" ]]; then
                    (( !SH_QUIET )) && printf "    OK  %s -> %s\n" "$link" "$target"
                else
                    printf " ERROR  %s -> %s\n" "$link" "$target"
                fi
            done
        elif [[ ! -e "$file" ]]; then
            eecho "checkln: $file: file or directory does not exist" && return 1
        fi
    done
}


alias .reload-shell='exec $SHELL -l'
alias .rls='.reload-shell'

alias .reload-bash-profile='. $HOME/.bash_profile'
alias .rlbp='.reload-bash-profile'

alias .reload-bash-profile-user='. $HOME/.bash_profile.$USER'
alias .rlbpu='.reload-bash-profile-user'


_tick
unset CCHH_BASH_STARTUP_PROFILE CCHH_BASH_STARTUP_PROFILE_LAST_ENTRY
