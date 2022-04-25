#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# In case there is anything bash-specific, I'll use .bash_profile.
#
# All non-interactive shells inherit environment variables BUT NOT FUNCTIONS. Further, by default Bash
# doesn't load ANY login files unless BASH_ENV is set to one; then it calls it when, for instance, a script
# gets run. It gets set to .bashrc before calling .bashrc from here.


# If debugging is not enabled, overwrite __echo with a no-op
. $HOME/.__login.debug ".bash_profile" --reset-datetime || __echo() { :; }
__echo "----------------"
__echo "[.bash_profile] starting; pid: $$, ppid: $PPID, -='$-', SHLVL=$SHLVL, PS1='$PS1'"


# Source .bashrc if present
export BASH_ENV="$HOME/.bashrc"
[[ -e "$BASH_ENV" ]] && . "$BASH_ENV"


set -o vi
export EDITOR=vim
export CLICOLOR=1

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

#
### PS1 COMMAND LINE PROMPT
#
# - if unset, leave unset (non-interactive shell)
# - if last command was in error, display "!" prefix before "$" and before line sep
# - `history -a` explicitly flushes the session history to the history file
# __git_ps1 shows the current git branch, if any, and is configured below
# - \u = user, \h = hostname, \w = working dir
#
reset_prompt() {
  [[ -z "$PS1" ]] && return 0
  # export PROMPT_COMMAND='(($?)) && _pprefix="!\$" || _pprefix="\$"; history -a'
  # export PS1='--\n$(__git_ps1 "[%s]") \w $_pprefix '
  export GIT_BRANCH="$(git branch --show-current 2> /dev/null)"
  export PROMPT_COMMAND='(($?)) && _pprefix="!" _sep="!..." || _pprefix= _sep="____"; \
  history -a; \
  export GIT_BRANCH="$(git branch --show-current 2> /dev/null)"; \
  __git_ps1 "$_sep\n" " \w $_pprefix\$ " "[%s]"'
}
reset_prompt
__echo "[.bash_profile] set prompt to PS1='$PS1'"


#
###  AWS
#
[[ -d "$HOME/.aws" ]] && \
aws.read.credentials() {
  export AWS_CREDENTIALS="$HOME/.aws/credentials"
  [[ ! -s "$AWS_CREDENTIALS" ]] && 1>&2 iecho "aws.read.credentials: $AWS_CREDENTIALS not found or empty" && return 1

  export AWS_ACCESS_KEY_ID="$(awk -F= '/^aws_access_key_id=/ {print $2}' $AWS_CREDENTIALS)"
  export AWS_SECRET_ACCESS_KEY="$(awk -F= '/^aws_secret_access_key=/ {print $2}' $AWS_CREDENTIALS)"
  export AWS_SESSION_TOKEN="$(awk -F= '/^aws_session_token=/ {print $2}' $AWS_CREDENTIALS)"
  
  (( ! SH_QUIET )) && for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
    printf '# %-22s %s\n' "${var}:" "${!var}"
  done
} && \
SH_QUIET=1 aws.read.credentials && \
__echo "[.bash_profile] executed aws.read.credentials"
#
# Enable aws cli completion.
command -v aws_completer &>/dev/null && complete -C '/usr/local/bin/aws_completer' aws
complete -p | grep -E -q 'aws$' && __echo "[.bash_profile] loaded aws cli completion"

#
###  GIT
#
alias g='git'
#
# Enable git prompt and completion if installed.
# https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
#   - GIT_PS1_SHOWDIRTYSTATE=1        unstaged (*), staged (+)
#   - GIT_PS1_SHOWUNTRACKEDFILES=1    untracked (%)
#   - GIT_PS1_SHOWUPSTREAM=1          behind (<), ahead, (>), diverged, (<>), caught up (=)
#                                     instead of 1, value of 'verbose [name]' gives number of commits and upstream name
#   - GIT_PS1_DESCRIBE_STYLE='branch' controls what detached commits are shown relative to; e.g., "branch" is next newer branch or tag
#   - GIT_PS1_HIDE_IF_PWD_IGNORED=1   if PWD is an ignored directory, suppress the git prompt
#
if [[ -e "$HOME/.git-prompt.sh" ]]; then
  export GIT_PS1_SHOWDIRTYSTATE=1 GIT_PS1_SHOWUNTRACKEDFILES=1 GIT_PS1_SHOWUPSTREAM=1 GIT_PS1_SHOWCOLORHINTS=1
  export GIT_PS1_STATESEPARATOR='|' GIT_PS1_DESCRIBE_STYLE='branch' GIT_PS1_HIDE_IF_PWD_IGNORED=1
  . "$HOME/.git-prompt.sh"
  __echo "[.bash_profile] loaded git-prompt, PS1=$PS1"
fi
safe_source_script "$HOME/.git-completion.sh"
complete -p | grep -E -q 'git$' && __echo "[.bash_profile] loaded git cli completion"

#
### JAVA/JENV
#
if ! type -t jenv &>/dev/null; then
  __echo "[.bash_profile] jenv not installed"
else
  if [[ "$(type -t jenv 2>/dev/null)" == "function" ]]; then
    __echo "[.bash_profile] jenv already initialized"
  else
    __echo "[.bash_profile] initializing jenv"
    eval "$(jenv init -)"
    export PATH="$HOME/.jenv/bin:$PATH"
    __echo "[.bash_profile] initialized jenv, PATH=$PATH"
  fi
  __echo "[.bash_profile] setting JAVA_HOME from jenv"
  export JAVA_HOME="$(jenv javahome)"
fi
__echo "[.bash_profile] using JAVA_HOME=$JAVA_HOME"

#
### MAVEN
#
safe_source_script "/usr/local/etc/bash_completion.d/maven"
complete -p | grep -E -q 'mvn$' && __echo "[.bash_profile] loaded mvn cli completion"

#
### POSTGRES
#
export POSTGRES_HOME="/usr/local/opt/postgresql@10"
if [[ ! -e "$POSTGRES_HOME/bin/psql" ]]; then
  unset POSTGRES_HOME
elif [[ ! "$PATH" =~ bin/psql ]]; then
  export PATH="$POSTGRES_HOME/bin:$PATH"
  __echo "[.bash_profile] added Postgres to PATH, PATH=$PATH"
fi
__echo "[.bash_profile] using POSTGRES_HOME=$POSTGRES_HOME"

#
### PYTHON
#
# Set up Python aliases, tools and completion if installed.
if ! type -t python &>/dev/null; then
  __echo "[.bash_profile] python not installed"
else
  # Avoid pip/python version mismatch message.
  alias python='python3'
  alias pip='python3 -m pip'
  alias venv='python3 -m venv'

__echo "[.bash_profile] using Python version: $(python --version)"
__echo "[.bash_profile] using pip version: $(pip --version)"

  # init the "toxx" helper functions which operate on multiple tox.ini files at a time.
  safe_source_script "$HOME/bin/toxx.sh"

  __echo "[.bash_profile] initializing pip completion"
  eval "$(python -m pip completion --bash)"
  complete -p | grep -E -q 'pip$' && __echo "[.bash_profile] loaded pip cli completion"
fi
#
# Initialize pyenv and add shims to PATH.
if ! type -t pyenv &>/dev/null; then
  __echo "[.bash_profile] pyenv not installed"
else
  if [[ "$(type -t pyenv 2>/dev/null)" == "function" ]]; then
    __echo "[.bash_profile] pyenv already initialized"
  else
    __echo "[.bash_profile] initializing pyenv"
    export PYENV_HOME="$HOME/.pyenv"
    export PATH="$PYENV_HOME/bin:$PATH"
    eval "$(pyenv init -)"
    __echo "[.bash_profile] initialized pyenv, version: $(pyenv --version 2>/dev/null)"
  fi
fi
#
# from https://stackoverflow.com/a/57972514/160955
[[ -d "$HOME/.pyenv/versions" ]] && \
pyenv-brew-relink() {
  rm -fv "$HOME/.pyenv/versions/*-brew"
  for i in $(brew --cellar python)/*; do
    echo "...linking $i"
    ln -sv --force $i $HOME/.pyenv/versions/${i##/*/}-brew;
  done
}


# -o show owner (-l includes group), -h human file sizes, -F suffix (/@)
alias ll='ls -ohF'
alias llt='ls -ohFt'
alias lltr='ls -ohFtr'
alias lls='ls -ohFS'
alias llsr='ls -ohFSr'
alias la='ls -AohF'
alias lA='ls -aohF'
alias latr='ls -AohFtr'
alias lat='ls -AohFt'

# Think "ll and la but narrower": cut out permissions, link count and owner
lln() {
    #ls -ohF "$@" | sed -E -e '/^total .+$/d' -e 's/^.+ .+ .+ (.+) (.+ .+ .+) (.+)$/\1'$'\t''\2'$'\t''\3/'
    local -a args=("$@")
    [[ ${#args[@]} = 0 ]] && args=(.* *) # default to all files in current folder
    file_info 'size mdate suffixed_name target' "${args[@]}"
}
lan() {
    local -a args=("$@")
    [[ ${#args[@]} = 0 ]] && args=(.* *)
    file_info 'size mdate suffixed_name target' "${args[@]}"
}

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

# Show my numeric public (wide area network) ip
alias myip="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'; dig +short myip.opendns.com @resolver1.opendns.com"


# View man results in sublime.
mans() {
    type subl >& /dev/null || eecho "mans: no 'subl' command line app; using native man"
    man "$@" | col -b | subl --stay &
}


is_image_file() { [[ "$1" =~ ^.+\.(jpe?g|JPE?G|png|PNG)$ ]]; }
is_video_file() { [[ "$1" =~ ^.+\.(mov|MOV|avi|AVI|m4v|M4V|mp4|MP4)$ ]]; }


# Perform the prefixed command only on the newest file(s) in the given folder (or PWD).
ll-new() {
    local lines="10"
    [[ "$1" =~ "^-n" ]] && local lines="$2" && shift 2
    ls -ohtr "$@" | tail -n "$lines"
}
cat-new() {
    local d="${1:-$PWD}"
    local f="$d/$(ls -1tr "$d" | tail -n 1)"
    iecho "cat $f ..."
    cat "$f"
}
cd-new() {
    local d="${1:-$PWD}"
    local f="$d/$(ls -1trF "$d" | grep -E '/$' | tail -n 1)"
    iecho "cd $f ..."
    cd "$f" || return 1
}
head-new() {
    local d="${1:-$PWD}"; shift
    local lines="${1:-10}"; shift
    local f="$d/$(ls -1tr "$d" | tail -n 1)"
    iecho "head $f ..."
    head -n "$lines" "$f"
}
open-new() {
    local d="${1:-$PWD}"
    local f="$d/$(ls -1tr "$d" | tail -n 1)"
    iecho "open $f ..."
    # shellcheck disable=SC2015  # && and ||
    is_macos && open "$f" || vi "$f"
}

# Change directory to the given link's target, either the file's parent or the directory itself.
cd-ln() {
    local link="$1"
    local target="$(readlink "$link")"
    if [[ -d "$target" ]]; then
        cd "$target"
    else
        cd "$(dirname "$target")"
    fi
    return #status of cd
}

# If any listed file is a symlink, operate on its target
cp-ln() {
    local opts=()
    while [[ -n "$1" ]]; do
        local opt="$1"
        [[ -L "$opt" ]] && opt="$(readlink "$opt")" && iecho "cpln: $1 -> $opt"
        opts+=("$opt")
        shift
    done
    #shellcheck disable=2068 #double quote array expansion
    cp -pv ${opts[@]}
}

# If any listed file is a symlink, operate on its target
mv-ln() {
    local cmd
    while [[ -n "$1" ]]; do
        local opt="$1"
        [[ -L "$opt" ]] && opt="$(readlink "$opt")" && iecho "mvln: $1 -> $opt"
        cmd="$cmd \"$opt\""
        shift
    done
    eval "mv -v $cmd"
}

# Show directory of the given link's target, either the file's parent or the directory itself.
ls-ln() {
    [[ -z "$1" ]] && eecho "usage: lsln symlink [...]" && return 1
    local sw=()
    while [[ "$1" =~ ^- ]]; do
        sw+=("$1"); shift
    done
    local i
    for link in "$@"; do
        vecho "lsln: link[$((i++))]=$link"
        [[ ! -L "$link" ]] && vecho "lsln: $link: not a symlink, skipping" && continue
        local target="$(readlink "$link")"
        local target_file
        if [[ ! -d "$target" ]]; then
            target_file="$target"
            target="$(dirname "$target")"
        fi
        iecho
        [[ "$target_file" ]] && iecho "$(tilde_compress "$target_file") => .. => $(tilde_compress "$target")"
        local c="ls ${sw[*]} $(tilde_compress "$target")"
        iecho_and_eval "$c"
    done
}
ll-ln() { ls-ln -ohtr "$@"; }

# Touch each symlink to match its target's modification date.
# Usage: touchln [--quiet | --verbose] link1 [...]
touch-ln() {
    if [[ "$1" ~= -r|-R ]]; then
      shift
      local dirs=($@)
      (( ! ${#dirs[@]} )) && dirs+=("$PWD")
      for dir in "${dirs[@]}"; do
          for link in $(find "$dir" -type l | sort); do
              touchln "$link"
          done
      done
    else
      local count=0
      for link in "$@"; do
          [[ "$link" =~ ^-?-q(uiet)?$ ]] && SH_QUIET=1 && unset SH_VERBOSE && continue
          [[ "$link" =~ ^-?-v(erbose)?$ ]] && SH_VERBOSE=1 && unset SH_QUIET && continue
          [[ ! -e "$link" ]] && eecho "touchln: ${link}: no such file" && return 1
          [[ ! -L "$link" ]] && vecho "touchln: ${link}: not a symlink" && continue
          local target="$(readlink "$link")"
          [[ "$(file_modified_seconds "$link")" = "$(file_modified_seconds "$target")" ]] && vecho "touchln: $link: mtime already matches" && continue
          touch -h "$link" -r "$target"
          ((count++))
          [[ -z "$SH_QUIET" ]] && ls -ohF -d "$link"
      done
      ((!count)) && return 1
      vecho "touchln: updated $count links"
    fi
}

touch-dir() {
  [[ -z "$1" ]] && eecho "usage: touchdir [-R] dir [...]" && return 1
  if [[ "$1" ~= -r|-R ]]; then
    shift
    local dirs=("$@")
    [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
    for dir in "${dirs[@]}"; do
        # local subdirs="$(find "$dir" -depth ! -type f)"
        # vecho "touchdir_R: for $dir, found subdirs: $subdirs"
        # for subdir in $subdirs; do
        find "$dir" -depth ! -type f -print |\
        while read -r subdir; do
            # vecho "touchdir_R: calling touchdir for subdir='$subdir'"
            touchdir "$subdir"
        done
        # vecho "touchdir_R: calling touchdir for dir='$dir'"
        touchdir "$dir"
    done
  else
    local count=0 SH_QUIET="$SH_QUIET" SH_VERBOSE="$SH_VERBOSE"
    for dir in "$@"; do
        vecho "touchdir: dir='$dir'"
        [[ "$dir" =~ ^-?-q(uiet)?$ ]] && SH_QUIET=1 && SH_VERBOSE= && continue
        [[ "$dir" =~ ^-?-v(erbose)?$ ]] && SH_VERBOSE=1 && SH_QUIET= && continue
        [[ ! -e "$dir" ]] && eecho "touchdir: $dir: no such directory" && return 1
        [[ ! -d "$dir" ]] && vecho "touchdir: $dir: not a directory" && continue

        local newest_child_name="$(ls -A1t "$dir/"| head -n 1)"
        # vecho "touchdir: newest_child_name = $newest_child_name"
        [[ -z "$newest_child_name" ]] && vecho "touchdir: empty directory: $dir" && continue
        local newest_child="$dir/$newest_child_name"

        [[ "$(file_modified_seconds "$dir")" == "$(file_modified_seconds "$newest_child")" ]] && vecho "touchdir: $dir: mtime already matches $newest_child" && continue
        iecho "Updating mtime of ${dir/$HOME/~} from $(file_info 'mdate mtime' "$dir") to match $newest_child_name, $(file_info 'mdate mtime' "$newest_child")"

        touch -h -r "$newest_child" "$dir"
        ((count++))
    done
    ((!count)) && return 1
    vecho "INFO: touchdir: updated $count directories"
  fi
}


# find . -name $1, then echo the first result in sorted order
find-1() {
  local name="$1" && shift
  local find_opts="$*"
  [[ -z "$name" ]] && eecho "ERROR: Usage: find-1 name NAME" && return 1

  local c="find . -name '$name' ${find_opts} -print -quit | sort -s | head -n 1"
  #decho_vars name find_opts c

  local path="$(eval "$c")"
  [[ -n "$path" && -e "$path" ]] && echo "$path" && return 0

  [[ -n "$path" ]] && eecho "find-1: $path: Invalid path, somehow"
  return 1
}

cd-f() {
    local path="$(find-1 "$1" -type d)"
    [[ -z "$path" ]] && eecho "cdf: $1: No such file or directory" && return 1

    vecho_and_eval "cd '$path'"
}

headf() {
    local lines=10
    [[ "$1" = "-n" ]] && lines=$2 && shift 2

    local path="$(find-1 "$1" -type f)"
    [[ -z "$path" ]] && eecho "headf: $1: No such file or directory" && return 1

    vecho_and_eval "head -n $lines '$path'"
}

cat-f() {
    local path="$(find-1 "$1" -type f)"
    [[ -z "$path" ]] && eecho "catf: $1: No such file" && return 1

    vecho_and_eval " cat '$path'"
}


# Delete 0-byte files. If $1 == -r recurse; else only check files directly in the target folders.
# If no folders are specifed, default to PWD.
# Usage: rm0 [-r] [dir...]
rm-0() {
    local maxdepth="-maxdepth 1"
    [[ "$1" =~ -[rR] ]] && maxdepth= && shift

    for d in "${@:-.}"; do
        [[ ! -d "$d" ]] && eecho "rm0: missing or non-folder: $d" && return 1
        iecho_and_eval "find $d $maxdepth -size 0  -print -delete"
    done
}



# Display selected info from a jar's manifest.
# If --all is $1, show the entire manifest.
jar-info() {
    if ! typeof_command "unzip"; then
        eecho "jar-info: unzip is not installed"
        return 1
    fi

    [[ "$1" =~ --?a(ll)? ]] && local opt_all=1 && shift

    local jar_file="$1"
    [[ -z "$jar_file" ]] && eecho "jar-info: missing jar_file operand" && return 1
    [[ ! -e "$jar_file" ]] && eecho "jar-info: $jar_file: not found" && return 1

    if [[ -z "$opt_all" ]]; then
        unzip -c "$jar_file" "META-INF/MANIFEST.MF" | grep -E -i -e "build-jdk" -e "Implementation-(Title|Version)" -e "Bundle-(SymbolicName|Doc-URL)"
    else
        unzip -c "$jar_file" "META-INF/MANIFEST.MF"
    fi
}

# Check each archive recursively from PWD for the given filename expression.
# $1 - filename expression
# $2 - archive type, default 'zip'
zip-find() {
    if ! typeof_command "unzip"; then
        eecho "zip-find: unzip is not installed"
        return 1
    fi

    local filename_expr="$1"; shift
    [[ -z "$filename_expr" ]] && eecho "zip-find: missing filename_expr operand; usage: zip-find filename_expr [archive_type]" && return 1

    local archive_type="${1:-zip}"; shift
    [[ "${archive_type:0:1}" = "." ]] && archive_type="${archive_type:1}"

    # shellcheck disable=0
    find . \
        -name "*.$archive_type"-exec sh -c "unzip -l '{}' | grep -i -e '$filename_expr' -e 'Archive:'" \; \
    | \
    grep -B 1 "$filename_expr" \
    | \
    sort
}
jar-find() {
    zip-find "$1" "jar"
}

# Rename all files in a given directory, by substituting NEW_TEXT for OLD_TEXT;
# regular expressions allowed. Files not macthing OLD_TEXT are left alone.
# Usage: xmv ...
#   old_text  - text to find and replace
#   new_text - replacement text, or blank to simply remove old_text
#   dir  - optional, directory, default is PWD
#   limit - optional, max number of files
xmv() {
    local old_text="$1" && shift
    local new_text="$1" && shift
    local dir="${1:-.}" && shift
    local limit=${1:-0}
    decho_vars old_text new_text dir limit

    [[ -z "$old_text" ]] || [[ -z "$new_text" ]] && eecho "usage: xmv old new [dir]" && return 1

    local sed_cmd="s/^(.*)${old_text}(.*)$/\\1${new_text}\\2/g"
    decho_vars sed_cmd

    for old_name in $dir/*; do
        decho_vars old_name
        local new_name="$(echo "$old_name" | sed -E -e "$sed_cmd")"
        [[ "$old_name" = "$new_name" ]] && continue
        decho_vars new_name
        local mv_cmd="mv -v \"$dir/$old_name\" \"$dir/$new_name\""
        decho_vars mv_cmd
        wecho --quiet "$mv_cmd"
        (( --limit <= 0 )) && break
    done
}

# Recursively report cksum values and sizes in tab-delimited form:
#   path TAB size TAB cksum TAB mdate [TAB image_cdate TAB image_size]
cksum-R() {
    local dirs=("$@")
    [[ -z "$1" ]] && dirs=("$PWD")
    decho_vars dirs

    local IFS="${CR}"
    for dir in "${dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue
        decho '--------'; decho_vars dir

        find -L "$dir" -type f \! -empty \! -name '.DS_Store' |\
        sort |\
        while read -r f; do
            decho_vars f
            local mdate= image_cdate= image_size=
            mdate="$(file_info 'mdate' $f)"
            if (is_image_file "$f" || is_video_file "$f"); then
                image_cdate="$(exiftool -S -CreateDate "$f" | sed -E 's/^[^:]+\: //')" # yyyy:MM:dd hh:mm:ss
                image_cdate="${image_cdate:0:4}-${image_cdate:5:2}-${image_cdate:8:2}T${image_cdate:11:8}" # yyyy-MM-dd'T'hh:mm:ss
                image_size="$(exiftool -S -ImageSize "$f" | sed -E 's/^[^:]+\: //')"
            fi
            decho_vars mdate image_cdate image_size

            cksum "$f" |\
            awk -v FILE="$(tilde_compress "$f")" \
                -v MDATE="$mdate" \
                -v IMAGE_CDATE="$image_cdate" \
                -v IMAGE_SIZE="$image_size" \
                '{printf "\"%s\"\t%d\t%d\t%s\t%s\t%s\n", FILE, $2, $1, MDATE, IMAGE_CDATE, IMAGE_SIZE}'
        done
    done
}


# Recursively list size in kb, modification date, and name, sorted by date ascending.
# Usage: $0 [root [pattern]]
lltr-R() {
    local root="${1:-$PWD}"; shift
    local patt="$1"; shift

    local find_cmd=("find")
    is_macos && find_cmd+=("-E")
    find_cmd+=("\"$root\"")
    is_macos || find_cmd+=("-regextype posix-extended")
    find_cmd+=("! -type l")
    [[ -n "$patt" ]] && find_cmd+=("-name '$patt'")
    find_cmd+=("! -regex '.*/(bin|BUILD|DIST|.*\\.BAK).*'")
    if is_macos; then
        find_cmd+=("-exec stat -t '%F %T' -f '%Sm %8z"$'\t'"%N' {} \\;")
    else
        find_cmd+=("-printf '%TY-%Tm-%Td %TH:%TM\\t%p\\n'")
    fi
    decho_vars root patt find_cmd

    vecho_and_eval "${find_cmd[*]}" \
    | \
    awk \
        -v FS=$'\t' \
        -v HOME="$HOME" \
        -v PWD="$PWD"  \
        '{gsub(PWD,".",$2); gsub("^" HOME,"~",$2); printf "%s  %s\n", $1, $2};' \
    | \
    sort --stable
}

# Display counts of files, directories and links in each directory, computed recursively.
# Default is every directory in PWD, all files.
# Options:
#   -q, --quiet     disable most output (inherits and locally overrides SH_QUIET)
#   -v, --verbose   enable verbose output (inherits and locally overrides SH_VERBOSE)
#   -i, --include   glob of filenames to include (passed to 'find -name')
#   -e, --exclude   glob of filenames to exclude (passed to '! find -name')
count-f() {
    local SH_QUIET="$SH_QUIET"
    local SH_VERBOSE="$SH_VERBOSE"

    # Detect any leading options; read and consume
    local opt_includes opt_excludes
    while [[ -n "$1" ]]; do
        local opt="$1"
        vecho "count-f: opt: $opt"
        [[ "$opt" =~ ^-?-q(uiet)?$ ]] && SH_QUIET=1 && unset SH_VERBOSE && shift && continue
        [[ "$opt" =~ ^-?-v(erbose)?$ ]] && SH_VERBOSE=1 && unset SH_QUIET && shift && continue
        [[ "$opt" =~ ^-?-i(nclude)?$ ]] && opt_includes="$opt_includes -name '$2'" && shift 2 && continue
        [[ "$opt" =~ ^-?-e(xclude)?$ ]] && opt_excludes="$opt_excludes ! -name '$2'" && shift 2 && continue
        break
    done

    local directories=( "$@" )
    # shellcheck disable=SC2207  # quote command output into array
    [[ ${#directories} == 0 ]] && IFS="${CR}" directories=( $(ls -1Ad {.??,}*) )  # all files, including hidden files, except '..'
    vecho "count-f: directories: ${#directories}"

    for dir in "${directories[@]}"; do
        [[ ! -d "$dir" ]] && vecho "count-f: ${dir}: not a directory" && continue
        [[ -L "$dir" ]] && vecho "count-f: ${dir}: symlink to directory not followed" && continue

        for find_type in f d l; do
            local c="find '$dir' -mindepth 1 -type $find_type $opt_includes $opt_excludes"
            local ${find_type}_count="$(eval "$c" | wc -l)"
        done

        # shellcheck disable=SC2154  # var referenced but not assigned
        printf '%5d %4d/ %3d@  %12s  %s  %s\n' \
            "$f_count" "$d_count" "$l_count" \
            "$(local bytes="$(du -s "$dir" | cut -f1)"; commafy "$bytes")" \
            "$(file_info 'mdate mtime' "$dir")" \
            "$dir"
    done
}

# Nice wrapper around du, showing nice size numbers but also sorting.
# usage: size-f [dir ...]
size-f() {
    local dirs
    [[ "$1" ]] && dirs=("$@") || dirs=(*)
    
    local tmp="$TMPDIR/size-f.csv"
    rm -f "$tmp"
    
    local IFS=$'\t'
    for dir in $(find . -maxdepth 1 -type d -exec printf '%s\t' '{}' \;); do
        [[ ! -e "$dir" ]] && eecho "size-f: directory not found: $dir" && return 1
        local bytes=$(du -s "$dir" | awk '{print $1}')
        local nice_bytes="$(nice_byte_size $bytes)"
        printf '%12s\t%-8s\t%s\n' "$bytes" "$nice_bytes" "$dir" >> "$tmp"
    done
    if [[ -e "$tmp" ]]; then
        echo ""
        sort -n < "$tmp"
        rm -f "$tmp"
    fi
}


type realpath >& /dev/null || \
realpath() {
  while [[ "${1:0:1}" = "-" ]]; do
      [[ "$1" = "-v" ]] && local VERBOSE=1 && shift && continue
      [[ "$1" = "-t" ]] && local TILDE=1 && shift && continue
  done
  local target="${1:-$PWD}" && shift
  [[ -n "$VERBOSE" ]] && echo "target = $target"

  [[ -L "$target" ]] && eecho "$(readlink "$target")" && return 0

  local path="$(cd "$(dirname "$target")" || return 1; pwd)"
  [[ -n "$VERBOSE" ]] && echo "path   = $path"
  local lhs="$path/$(basename "$target")"
  [[ -n "$VERBOSE" ]] && echo "lhs    = $lhs"
  lhs="$(sed -E "s:/+:/:g" <<<"$lhs")"
  [[ -n "$VERBOSE" ]] && echo "lhs    = $lhs"
  local rhs=""
  while true; do
    [[ -n "$VERBOSE" ]] && echo "  ........"
    [[ -n "$VERBOSE" ]] && echo "  lhs    = $lhs"
    [[ -n "$VERBOSE" ]] && echo "  rhs    = $rhs"

    [[ -d "$lhs" ]] && lhs="$(cd "$lhs" || return 1; pwd)"  #normalize ., ..
    if [[ -L "$lhs" ]]; then
      local ret="$(readlink "${lhs}")"
      [[ -n "$rhs" ]] && ret+="/${rhs}"
      [[ -n "$TILDE" ]] && ret="${ret/$HOME/\~}"
      echo "$ret"
      return 0
    fi

    local leaf="${lhs##*/}"  # ##*/ = after last /, or input if no /
    [[ -n "$VERBOSE" ]] && echo "  leaf   = $leaf"
    if [[ "$lhs" = "/" ]] || [[ "$lhs" = "$leaf" ]]; then
      local ret="${lhs}/${rhs}" && [[ -z "$rhs" ]] && ret="${lhs}"
      [[ -n "$TILDE" ]] && ret="${ret/$HOME/\~}"
      echo "$ret"
      return 0
    fi

    lhs="${lhs%/*}"  # %/* = before last /
    [[ "$leaf" = "." ]] && continue
    [[ -n "$rhs" ]] && rhs="${leaf}/${rhs}" || rhs="${leaf}"
  done
}

# Usage: xgrep [-d dir --no-log|-nl] pattern [--include|-i EXT1 [--include|-i EXT2] ...] [--exclude EXT1 [--exclude EXT2] ...]
#   -d dir  - optional root directory, default is PWD
#   --no-logs - exclude .log, .out, .csv
#   --include EXT [, EXT2, ... ]  - file extensions to limit search to
#   --exclude EXT [, EXT2, ... ]  - file extensions to exclude
#   PATT    - extended regex to search for
# Always omit .* directories
xgrep() {
    decho "\$ xgrep $*"

    read -r -d '' USAGE <<-EOF
usage:
$ xgrep PATT1 [PATT2 ...] [--dir DIR] [--all-files] [--all-folders]
[--exclude EXT1] [--exclude EXT2 ...] [--include EXT1] [--include EXT2 ...]
[--exclude-dir DIR1] [--exclude-dir DIR2 ...] [--include-dir DIR1] [--include-dir DIR2 ...]
or:
$ xgrep PATT1 [PATT2 ...] [-d DIR] [-a]
[-e EXT1] [-e EXT2 ...] [-i EXT1] [-i EXT2] ...]
[-ed DIR1] [-ed DIR2 ...] [-id DIR1] [-id DIR2] ...]
where:
--dir DIR defaults to PWD (.)
--all-files does NOT add log-like extensions to the exlcude extension list: .log .log.*  .out .out.*  .csv .csv.*
--all-folders does NOT add hidden, BAK, etc. folders to the exclude directory list
-a implies both --all-files and --all-folders
--verbose/-v sets SH_VERBOSE; --debug sets SH_DEBUG; --quiet/-q sets SH_QUIET
EOF

    local root_dir='.' all_files='' all_folders=''
    local patterns=() ext_incl=() ext_excl=() dir_incl=() dir_excl=()
    while [[ -n "$1" ]]; do
        local opt="$1" && shift
        decho "xgrep: arg: '$opt'"
        case "$opt" in
            -d* | --dir )
            local root_dir="$1"
            shift
            ;;
            --all-files )
            all_files=1
            ;;
            --all-folders )
            all_folders=1
            ;;
            -a )
            all_files=1
            all_folders=1
            ;;
            -e | --exclude )
            ext_excl+=("$1")
            shift
            ;;
            -i | --include )
            ext_incl+=("$1")
            shift
            ;;
            -ed | --exclude-dir )
            dir_excl+=("$1")
            shift
            ;;
            -id | --include-dir )
            dir_incl+=("$1")
            shift
            ;;
            -v* | --verbose )
            SH_VERBOSE=1
            unset SH_QUIET SH_DEBUG
            ;;
            --debug )
            SH_DEBUG=1 SH_VERBOSE=1
            unset SH_QUIET
            ;;
            -q* | --quiet )
            SH_QUIET=1
            unset SH_VERBOSE SH_DEBUG
            ;;
            -* )
            eecho "xgrep: illegal option $opt"
            eecho "$USAGE"
            return 1
            ;;
            * )
            patterns+=("$opt")
            ;;
        esac
    done
    [[ ${#patterns} -eq 0 ]] && eecho "xgrep: missing pattern" && eecho "$USAGE" && return 1
    ## decho_vars --prefix "  " --quote patt root_dir no_logs ext_excl ext_incl SH_VERBOSE SH_QUIET

    [[ -z "$all_files" ]] && ext_excl+=(".log\\*" ".out\\*" ".csv\\*")
    [[ -z "$all_folders" ]] && dir_excl+=("\\*/.\\*" "\\*.BAK\\*" "\\*.cache" )

    local grep_cmd=()
    grep_cmd+=("-E")     # -E extended regexp
    grep_cmd+=("-iIR")   # -i case insensitive; -I ignore binary files; -R recursive
    grep_cmd+=("'$root_dir'")

    for patt in "${patterns[@]}"; do
        grep_cmd+=("-e" "'${patt}'")
    done
    for ext in "${ext_excl[@]}"; do
        grep_cmd+=("--exclude" "\\*${ext}")
    done
    for ext in "${ext_incl[@]}"; do
        grep_cmd+=("--include" "\\*${ext}")
    done
    for dir in "${dir_excl[@]}"; do
        grep_cmd+=("--exclude-dir" "${dir}")
    done
    for dir in "${dir_incl[@]}"; do
        grep_cmd+=("--include-dir" "${dir}")
    done
    vecho_vars --prefix "  " --quote grep_cmd

    c="grep ${grep_cmd[*]}"
    iecho_and_eval "$ $c"
}


# Move file $1 to folder/file $2, then create symlink to it in its original place.
mv-and-ln() {(
    set -o errexit
    local USAGE="usage: mv-and-ln [--force] orig_file target_file"

    local opt_force='-n'
    [[ "$1" =~ ^-?-f(orce)?$ ]] && opt_force='-f' && shift

    local orig_file="$1"; shift
    [[ -z "$orig_file" ]] && eecho "$USAGE" && return 1
    [[ ! -e "$orig_file" ]] && eecho "mv-and-ln: no such file or directory: $orig_file" && return 1
    [[ -L "$orig_file" ]] && eecho "mv-and-ln: orig_file cannot be a link: $orig_file" && return 1

    # If target is a directory, append the name of orig file to it since the ln command will expect the full path
    # (rather than implicitly creating a child file inside it).
    local target_file="$1"; shift
    [[ -z "$target_file" ]] && eecho "$USAGE" && return 1
    if [[ -d "$target_file" ]]; then
        target_file="$target_file/$(basename "$orig_file")"
    fi
    [[ "$opt_force" = '-n' && -e "$target_file" ]] && eecho "mv-and-ln: : $target_filetarget_file already exists" && return 1

    decho "mv $opt_force -v \"$orig_file\" \"$target_file\""
    decho "ln -s -v \"$target_file\" \"$orig_file\""
    iecho -n "mv: " && mv $opt_force -v "$orig_file" "$target_file"
    iecho -n "ln: " && ln -s -v "$target_file" "$orig_file"

    vecho_and_eval "ls -ohF -d  \"$target_file\" \"$orig_file\""
)}

# Usage 1: swap a link and its target file
# Usage 2: move a target file to a new location, then create a link in its old location to the new
swap-ln() {(
    set -o errexit
    local USAGE="usage: swap-ln [--backup --quiet] link"$'\n'"       swap-ln --create [--force --backup --quiet] source target"

    local opt_create= opt_backup= opt_force= SH_QUIET=$SH_QUIET mv_f_switch= v_switch="-v"
    while [[ "$1" =~ ^--?.+$ ]]; do
        case "$1" in
            -b|--backup) opt_backup=1;;
            -c|--create) opt_create=1;;
            -f|--force)  opt_force=1; mv_f_switch="-f";;
            -q|--quiet)  SH_QUIET=1; v_switch="";;
            *) eecho "$USAGE" && return 1;;
        esac
        shift || true
    done

    # each usage requires at least one arg
    [[ ! "$1" ]] && eecho "$USAGE" && return 1

    if ((!opt_create)); then
        # for SWAP, make sure only the link was specified, and it is an existing, valid symlink
        local link="$1" || true
        [[ "$target" ]] && eecho "$USAGE" && return 1
        [[ ! -L "$link" ]] && eecho "swap-ln: $link: not a symlink" && return 1
        [[ ! -e "$link" ]] && eecho "swap-ln: $link: not a valid symlink" && return 1
    else
        # for CREATE AND SWAP, make sure target was specified, source is an existing regular file or
        # directory, and target does not exist or it exists but --force was specified
        local source="$1" && shift || true
        local target="$1" && shift || true
        [[ ! "$target" ]] && eecho "$USAGE" && return 1
        [[ -L "$source" ]] && eecho "swap-ln: $source: source file is a link" && return 1
        [[ ! -e "$source" ]] && eecho "swap-ln: $source: no such file or directory" && return 1
        [[ -e "$target" ]] && ((!opt_force)) && eecho "swap-ln: $target: target file exists (--force overwrites)" && return 1
    fi
    
    if ((!opt_create)); then
        # for CREATE AND SWAP, verify link
        local target_file="$(readlink "$link")"
        
        ((opt_backup)) && iecho -n "bak_link: " && iecho_and_eval "bak -m \"$link\""
        ((opt_backup)) && iecho -n "bak_file: " && iecho_and_eval "bak \"$target_file\""
        
        iecho -n " rm_link: " && iecho_and_eval "rm $v_switch \"$link\""
        iecho -n " mv_file: " && iecho_and_eval "mv $v_switch \"$target_file\" \"$link\""
        iecho -n " mk_link: " && iecho_and_eval "ln -s \"$link\" \"${target_file}\""
        iecho -n "touchln:  " && iecho_and_eval "touchln \"${target_file}\""

    else
        # for CREATE, remove the target if it exists, mv the source and link it
        [[ -e "$target" ]] && ((opt_force)) && iecho -n "rm: " && iecho_and_eval "rm -rf $v_switch \"$target\""
        iecho -n "mv: " && iecho_and_eval "mv $mv_f_switch $v_switch \"$source\" \"$target\""
        iecho -n "ln: " && iecho_and_eval "ln -s $v_switch \"$target\" \"$source\""
        ((!SH_QUIET)) && ls -ohF -d "${source}"
        return
    fi
)}

# For each link in @$, echo OKAY or ERROR. If --quiet is specified, only show ERRORs.
check-ln() {
    local USAGE="check-ln [--recursive] [--quiet] [link ...]${CR}       default link is each link/dir in PWD"
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
            eecho "check-ln: $file: file or directory does not exist" && return 1
        fi
    done
}


# Echo whatever was piped in to stdout, so it can be assigned via $().
# Return 0 if there was something piped in; else 1.
from_stdin() {
    [[ ! -p /dev/stdin ]] && return 1
    read -r piped_in
    echo -n "${piped_in}"
}

file_opened() {
    local file=$1
    [[ -z $file ]] && eecho "ERROR: file_opened: no file specified" && exit 1
    [[ ! -e $file ]] && echo "ERROR: file_opened: file not found: '$file'" && exit 1
    local dir=$(dirname "$file")
    local bname=$(basename "$file")
    nopen=$(sudo lsof +d "$dir" | grep -c "$bname")
    decho_vars file dir bname nopen
    [[ -n "$nopen" && $nopen -gt 0 ]] && return 0 || return 1
}

# $1 is seconds since epoch; return 2017-12-21, or "null" if seconds is 0 or null
iso_date() {
    local s="${1:-0}"
    [[ "$s" = "0" ]] && echo "null" && return 0
    if is_macos; then
        date -r "$s" +'%Y-%m-%d' || return 1
    else
        date --date="@$s" +'%Y-%m-%d' || return 1
    fi
}
# $1 is seconds since epoch; return 16:45:00, or "null" if seconds is 0 or null
iso_time() {
    local s="$1"
    [[ "$s" = "0" ]] && echo "null" && return 0
    if is_macos; then
        date -r "$s" +'%H:%M:%S' || return 1
    else
        date --date="@$s" +'%H:%M:%S' || return 1
    fi
}


file_modified_seconds() {
    if is_macos; then
        stat -f '%m' "$@"
    else
        stat -c '%Y' "$@"
    fi
}

file_info() {
    local all_fields="user size bdate btime cdate ctime mdate mtime adate atime size name basename suffixed_name target"
    local USAGE=$(cat <<-EOF
    usage: file_info 'flag_1 flag_2 ... flag_n' file [...]
           (literally including the single quotes around the flags)
           where flags are 1+ of [$all_fields]
EOF
    )

    [[ ! "$1" ]] && eecho "$USAGE" && return 1
    # shellcheck disable=2206  # quote to avoid split
    local -a fields=( $1 ) && shift
    ## decho_vars all_fields fields

    local files=( "$@" )
    if [[ ${#files[*]} = 0 ]]; then
        decho "file_info: no file()s) specified; using .* *"
        files=( .* * )
    fi

    for file in "${files[@]}"; do
        [[ "$SH_VERBOSE" ]] && eecho -n "$file "
        [[ ! -e "$file" ]] && eecho "file_info: file not found: $file" && return 1

        if is_macos; then
            eval "$(stat -s "$file" || return 1)"  # put a dozen+ fields into env, all starting w 'st_'
        else
            eval "$(stat --format='st_uid=%u st_size=%s st_birthtime=%W st_ctime=%Z st_mtime=%Y st_atime=%X' "$file" || return 1)"
        fi

        local out=()
        for f in  ${fields[*]}; do
            case $f in
                user*)     out+=("$(id -nu "$st_uid" || return 1)")  ;;
                size*)     out+=("$(printf "%7d" "$st_size")")  ;;
                bdate*|birthdate*)    out+=("$(iso_date "$st_birthtime" || return 1)")  ;;
                btime*|birthtime*)    out+=("$(iso_time "$st_birthtime" || return 1)")  ;;
                cdate*)    out+=("$(iso_date "$st_ctime" || return 1)")  ;;
                ctime*)    out+=("$(iso_time "$st_ctime" || return 1)")  ;;
                mdate*)    out+=("$(iso_date "$st_mtime" || return 1)")  ;;
                mtime*)    out+=("$(iso_time "$st_mtime" || return 1)")  ;;
                adate*)    out+=("$(iso_date "$st_atime" || return 1)")  ;;
                atime*)    out+=("$(iso_time "$st_atime" || return 1)")  ;;
                name*)     out+=("$(CLICOLOR_FORCE=1 ls -1dA "$file")")  ;;
                basename*) out+=("$(basename "$file" || return 1)")  ;;
                suffixed_name*)
                out+=("$(CLICOLOR_FORCE=1 ls -1dAF "$file")")  ;;
                target*)
                if target="$(readlink "$file")"; then
                    out+=("-> $target")
                else
                    out+=(" ")
                fi
                ;;
                *)  eecho "file_info: invalid option '$f'; must specify 1+ of $all_fields"; return 1 ;;
            esac
            ## decho_vars out
        done
        echo "${out[@]}"
    done
}


# Reverse lookup environment variable, using complete value.
# $1 - value to match
# $2 - optional pattern to exclude
vne() {
    local value="$1"; shift
    local exclude="$1"

    #env | awk -F'=' -v v="$value" 'BEGIN {s=1}  $0 ~ ".*=" v "$" {print $1; s=0; exit}  END {exit s}'
    local c="env | grep -E '=${value}\$' | awk -F'=' ' {print \$1;}'"
    [[ -n "$exclude" ]] && c="$c | grep -E -v '$exclude'"
    #decho "$c"

    local var=$(eval "$c")
    [[ -n "$var" ]] && echo "$var"
}

# Using pwd (or $1 if specified), replace the longest string possible with an environemnt variable.
pwd_vne() {
    local dir="${1:-$PWD}"
    local prefix="${1:-$dir}"
    local suffix=""
    #eecho_vars --quote prefix suffix
    while [[ "$prefix" =~ [^/]+/[^/]+ ]]; do
        local v="$(vne "$prefix" 'PWD|HOME')"
        #eecho_vars --quote v
        if [[ -n "$v" ]]; then
            echo "${v}${suffix}"
            return 0
        fi
        suffix="/${prefix##*/}${suffix}"
        prefix="${prefix%/*}"
        #eecho_vars --quote prefix suffix
    done
    echo "$dir"
    return 1
}

# Toggle prompt between "long" (normal) \w working directory and "short",
# substituting in the longest matching env var via pwd_vne.
# Prefix shortened _prompt_pwd with "$" so we know how to toggle.
ps1() {
    echo_vars -t 'IN' _prompt_pwd PS1 PROMPT_COMMAND
    if [[ "$_prompt_pwd" =~ ^\$.+$ ]]; then
        # short -> restore original
        reset_ps1
    else
        # from original prompt -> short
        export PS1="${PS1/\\w/\$_prompt_pwd}"
        export PROMPT_COMMAND="$PROMPT_COMMAND; _prompt_pwd=\"\\\$\$(pwd_vne)\""
    fi
    echo_vars -t 'OUT' _prompt_pwd PS1 PROMPT_COMMAND
}

# Add a .BAK.YYYYMMDD suffix, using the file's modification date or now if --now.
# If file is a folder, first update its modification date, then copy/move it.
# Ignore any .BAK files in backup set.
bak() {
    local USAGE="usage: bak [--move --now --overwrite --ignore-errors --verbose] [--target dir] file [...]"$'\n'"       where --now means use current date, not mdate"
    local opt_move=0 opt_now=0 opt_overwrite=0 opt_ignore_errors=0 opt_target='' SH_VERBOSE="$SH_VERBOSE"
    while [[ "$1" ]]; do
        case "$1" in
            -m | --move)  opt_move=1 && shift;;
            -n | --now)  opt_now=1 && shift;;
            -o | --overwrite)  opt_overwrite=1 && shift;;
            -i | --ignore-errors)  opt_ignore_errors=1 && shift;;
            -v | --verbose)  SH_VERBOSE=1 && shift;;
            -t|-d | --target|--dir)
                shift
                opt_target="$1" && shift
                [[ ! "$opt_target" ]] && eecho "bak: missing target for --target"$'\n'"$USAGE" && return 1
                ;;
            *) break
        esac
    done
    [[ ! "$1" ]] && eecho "$USAGE" && return 1

    local dstamp=''
    ((opt_now)) && dstamp=$(date +'%Y%m%d')

    # cp: -p preserve times, etc.; -n don't overwirte; -P no symlinks are followed; -R recursive
    # mv: -n don't overwirte
    local verb="cp -p -P -R";
    ((opt_move)) && verb="mv"
    ((!opt_overwrite)) && verb="$verb -n"
    ((SH_VERBOSE)) && verb="$verb -v"

    local nothing_bakked=1
    for f in "$@"; do
        if [[ ! -e "$f" ]]; then
            eecho "bak: $f: no such file or directory"
            ((opt_ignore_errors)) && continue || return 1
        fi
        
        [[ "$f" =~ .+\.BAK.[[:digit:]]{8,} ]] && iecho "bak: $f: ignoring BAK file" && continue
        
        if ((!opt_now)); then
            [[ -d "$f" ]] && SH_VERBOSE= touchdir_R "$f"
            tstamp=$(iso_date $(stat -s "$f" | egrep -o st_mtime=[[:digit:]]+ | cut -d'=' -f2))
            tstamp="${tstamp//-/}"  #yyymmdd
        fi

        local bak_dir="$(dirname "$f")"
        local bak_name="$(basename "$f").BAK.$tstamp"
        if [[ -d "$opt_target" ]]; then
            bak_dir="$opt_target"
        elif [[ "$opt_target" ]]; then
            bak_dir="$(dirname "$opt_target")"
            bak_name="$(basename "$opt_target")"
        fi
        local bak_file="$bak_dir/$bak_name"

        if [[ -e "$bak_file" ]]; then
            ((!opt_overwrite)) && eecho "bak: $bak_file: exists, use --overwrite to overwrite" && return 1
            iecho "bak: $bak_file: exists, will be overwritten"
        fi

        vecho_and_eval "$verb \"$f\" \"$bak_file\""
        nothing_bakked=0
    done

    return $nothing_bakked
}

# Rename a *.BAK.YYYYMMDD suffix file to the original name; if target exists, first 'bak' it.
unbak() {
    for f in "$@"; do
        [[ -z "$f" ]] && eecho "ERROR: Usage: unbak file" && return 1
        [[ ! -f "$f" ]] && eecho "ERROR: File not found: $f" && return 1
        [[ ! "$f" =~ .+\.BAK\.[0-9]{8} ]] && eecho "ERROR: File not in *.BAK.yyyymmdd format: $f" && return 1
        local orig_name="${f:0:-13}"
        [[ -f "$orig_name" ]] && bak -m "$orig_name"
        wecho mv -v "$f" "$orig_name"
    done
}


# Convenience version of [[ -e "file*" ]] since test won't take wildcards/globs.
glob_exists() {
    [[ -z "$1" ]] && return 1
    ls "$@" >& /dev/null
}

# Print the machine's physical memory size; units specified as $1:
#  -bytes, -kilobytes (default), -megabytes, -gigabytes
memsize() {
    local units="${1/-/}"; shift
    [[ -z "$units" ]] && units="k"

    local kb
    if is_macos; then
      kb=$(( $(sysctl hw.memsize | cut -d' ' -f2) / 1024 ))
    else
      kb=$( awk -e '/MemTotal/ {print $2}' /proc/meminfo)
    fi

    case "$units" in
        b*)  echo "$(( kb * 1024))" ;;
        k*)  echo "$kb" ;;
        m*)  echo "$(( kb / 1024))" ;;
        g*)  echo "$(( kb / (1024 * 1024) ))" ;;
        *)   >&2 echo "memsize: invalid units: $units"; return 1 ;;
    esac
    return 0
}

# Write a script, "mk_links.sh", to re-create each soft link in the given folder.
# Useful to create links on a separate server.
links_to_sh() {
    local USAGE="usage: links_to_sh [--force] [--recursive] [--verbose|--quiet] [root] [script_name]${CR}       root defaults to PWD; script_name to 'mk_links.sh'"

    local opt_force= opt_recursive= root="." script_name="mk_links.sh"
    local SH_QUIET="$SH_QUIET" SH_VERBOSE="$SH_VERBOSE" SH_DEBUG="$SH_DEBUG"
    while [[ "$1" =~ ^--?.+$ ]]; do
        case "$1" in
            -f|--force)     opt_force=1;;
            -r|--recursive) opt_recursive=1;;
            -v|--verbose)   SH_VERBOSE=1; SH_QUIET=;;
            -d|--debug)     SH_DEBUG=1; SH_VERBOSE=1; SH_QUIET=;;
            -q|--quiet)     SH_QUIET=1; SH_VERBOSE=; SH_DEBUG=;;
            *) eecho "$USAGE" && return 1
        esac
        shift
    done
    [[ "$1" ]] && root="$1" && shift
    [[ "$1" ]] && script_name="$1" && shift

    [[ ! -d "$root" ]] && eecho "links_to_sh: directory does not exist: $root" && return 1
    
    local sh_file="$root/$script_name"
    [[ ! "$opt_force" && -e "$sh_file" ]] && eecho "links_to_sh: script already exists: $sh_file." && return 1
    rm -f "$sh_file"
    touch "sh_file"

    echo '#!/usr/bin/env bash' >> "$sh_file"
    # shellcheck disable=SC2016  # $ inside ''
    echo 'opt_force="$1"  # -f to add to ln -s command' >> "$sh_file"

    # Can't modify variables in subshell, so count lines in file.
    local sh_lines=$(wc -l "sh_file" | awk '{print $1}')

    local maxdepth= 
    (( ! opt_recursive )) && maxdepth="-maxdepth 1"
    find "$root" $maxdepth -type l | sort |\
    while read -r link; do
        local link_dir="$(dirname "$link")"
        local real_file="$(home_compress "$(readlink "$link")")"
        vecho_vars -t "${CR}LINK $link" link_dir real_file
        
        [[ "$link_dir" != "." ]] && echo "mkdir -pv \"$link_dir\"" >> "$sh_file"
        echo "ln -sv \$opt_force \"$real_file\" \"$(basename "$link")\"" >> "$sh_file"
    done

    local sh_lines_after=$(wc -l "$sh_file" | awk '{print $1}')
    (( sh_lines == sh_lines_after )) && eecho "No links." && return 1

    chx "$sh_file"
    
    if [[ ! "$SH_QUIET" ]]; then
        echo ""
        
        ls -lhF "$sh_file"

        echo ""
        echo "----------------------------------------"
        cat "$sh_file"
        echo "----------------------------------------"
        echo ""
    fi
}

# Create a shell script with commands needed to re-create all current hotkeys
# defined in the Keyboard prefs pane, App Shortcuts.
#
#   usage: export_hotkeys.sh [-v] [out_file]
#          Default output_file is hotkeys-YYYYMMDD.sh
export_hotkeys() {
    [[ "$1" = "-v" ]] && local SH_VERBOSE=1 && shift
    local OUT="$1"
    [[ -z "$OUT" ]] && OUT="hotkeys-$(date +'%Y%m%d').sh"

    echo '#!/usr/bin/env bash' > "$OUT"

    defaults find NSUserKeyEquivalents | \
    sed \
    -e "s/Found [0-9]* keys in domain '\\([^']*\\)':/defaults write \\1 NSUserKeyEquivalents '/" \
    -e "s/    NSUserKeyEquivalents =     {//" \
    -e "s/};//" -e "s/}/}'/" >> "$OUT"

    echo killall cfprefsd >> "$OUT"
    chmod a+x "$OUT"

    iecho "Wrote $(grep -E -c '=.+;$' "$OUT") key mappings to $OUT"
}


# svn info returns, e.g., Working Copy Root Path: /Users/tpierzina/svn/ucp/ucp-alfresco-liferay/ucp-olc-2017
branch_name() {
    local dir="${1:-.}"
    local root_path=$(svn info "$dir" 2> /dev/null | grep "Working Copy Root Path:")
    [[ -z "$root_path" ]] && vecho "ERROR: Cannot determine working copy root path" && return 1
    echo "${root_path##*/}"  # after last /
}


# Apply a CSS selector to the results of the given URL or file.
# Requires html-xml-utils; macOS: brew install html-xml-utils
cssgrep() {
    local FN_USAGE="usage: cssgrep url 'selector' [--inner | --outer]"

    if (! which hxnormalize >& /dev/null); then
        eecho "cssgrep: html-xml-utils must be installed; try 'brew install html-xml-utils'"
        return 1
    fi

    local in="$1"; shift
    [[ -z "$in" ]] && eecho "$FN_USAGE" && return 1
    local selector="$1"; shift
    [[ -z "$selector" ]] && eecho "$FN_USAGE" && return 1
    local inner_opt=""
    [[ "$1" =~ -i ]] && inner_opt="-c"  #content only

    # hxnormalize:
    # -x xml conventions, empty elements are written with /> at the end
    # -l 240 max line length, allow for length strings without breaking
    #
    # hxselect:
    # -c content only ("innerHtml")
    # -s separator between matches
    hxnormalize -x -l 240 "$in" | hxselect $inner_opt -s '\n' "$selector"
}


# # TODO: not working, 9/26/18
# du_sorted() {
#     local files="$*"
#     [[ -z "$files" ]] && files="$(ls -1)"
#     vecho "du_sorted: files: $files"
#     local IFS=$'\t'; du -s "$files" | sort -n | while read sz nm; do
#         echo "sz: [$sz], nm: [$nm]"
#     done
# }

# video's dimensions, returned as "height=H \n width=W"
which ffprobe >& /dev/null && \
vdim() {
  local USAGE="usage: vdim video_file"
  local v_file="$1"; shift
  [[ -z "$v_file" ]] && eecho "$USAGE" && return 1
  [[ ! -e "$v_file" ]] && eecho "vdim: $v_file: no such file" && return 1
  ffprobe \
      -hide_banner \
      -v error \
      -select_streams v:0 \
      -show_entries stream=width,height "$v_file" \
  | \
  grep -E "^height=|^width="
}


alias .reload-bash-profile='. $HOME/.bash_profile'
alias .rlbp='.reload-bash-profile'

# Source over-engineered shell variables and aliases.
# Load over-engineered shell functions and aliases.
if ls $HOME/.bash_profile__* >& /dev/null; then
  __echo "[.bash_profile] sourcing files: $(tilde_compress $HOME/.bash_profile__*)"
  for dotpath in $HOME/.bash_profile__*; do
  __echo "[.bash_profile] sourcing $(tilde_compress $dotpath)"
  . "$dotpath"
  done
else
  __echo "[.bash_profile] no $(tilde_compress $HOME)/.bash_profile__* files to parse"
fi


__echo "[.bash_profile] finished"$'\n'

# [[ -e "$HOME/.iterm2_shell_integration.bash" ]] && . "$HOME/.iterm2_shell_integration.bash"
