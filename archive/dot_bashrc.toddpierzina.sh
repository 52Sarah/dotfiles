#!/usr/bin/env bash

# For interactive/login shells, Bash reads, in order:
#   - ~/.bash_profile || ~/.bash_login || ~/.profile
#   - once it finds one it stops looking
# For non-interactive shells, Bash reads the $BASH_ENV file (usually ~/.bashrc).
#
# For any shells invoked as 'sh', Bash reads the $ENV file (usually ~/.profile).

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
type -t .tick >&/dev/null || . ~/.tick.sh
.tick-bashrc() { .tick -s .bashrc $@; }
# export TICK_STDERR= TICK_STDOUT= TICK_INDENT=

.tick-bashrc -e 'printf "[START-FILE ] ~/.bashrc \$\$=$$ \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$- fns=%d\n" $(declare -F | wc -l)'

# Welcome to Todd's ugly system of semi-global shell variables. These hopefully
# facilitate increased verbosity when troubleshooting without changing the scriopt.
# The hits include SH_QUIET, SH_VERBOSE, SH_WHATIF (if set then weval only echoes).
.bashrc-wrapper() {
  
  ### echo helpers
  #   v* = never print unless SH_VERBOSE is set
  #   q* = always print unless SH_QUIET is set
  #   e* = always print but also to stderr
  echo-verbose()  { ((SH_VERBOSE)) || return 0; echo "$@"; }
  echo-quiet()    { ((SH_QUIET)) && return 0; echo "$@"; }
  echo-stderr()   { >&2 echo "$@"; }
  echo-error()    { echo-stderr "$@"; }
  vecho(){ echo-verbose "$@"; }
  qecho(){ echo-quiet "$@"; }
  eecho(){ echo-stderr "$@"; }
  #
  # List all variables matching $1 (globbing *, etc.) and their values.
  echo-glob() {
    local patt="$1"; [[ -z "$patt" ]] && echo-stderr "usage: echo-glob patt" && return 1
    [[ ! "$patt" =~ [*?]$ ]] && patt="${patt}*"
    local IFS=' '; for var in $(eval echo $(printf "\${!%s}" "$patt")); do
      printf "%s=%s\n" "$var" "${!var}"
    done
  }
  gecho(){ echo-glob "$@"; }
  #
  # Replace newlines, carriage-returns and tabs with \n, \r and \t.
  echo-unescape() {
    sed -E -n 'l;' \
    | join-lines '\\n' \
    | sed -E 's/\$(\\n)/\1/g; s/\$$//g;'
  }
  uecho(){ echo-unescape $@; }
  
  ### printf helpers
  #
  printf-verbose()  { ((SH_VERBOSE)) || return 0; printf "$@"; }
  printf-quiet()    { ((SH_QUIET)) && return 0; printf "$@"; }
  printf-stderr()   { >&2 printf "$@"; }
  printf-error()    { printf-stderr "$@"; }
  vprintf(){ printf-verbose "$@"; }
  qprintf(){ printf-quiet "$@"; }
  eprintf(){ printf-stderr "$@"; }

  ### eval helpers
  #
  # Conditionally echo the expression before executing it, using similar logic as echo-* and printf-*.
  [[ -z "$EVAL_ECHO_PREFIX" ]] && export EVAL_ECHO_PREFIX='$'  # don't override if previously set
  eval-echo()     { >&2 echo "$EVAL_ECHO_PREFIX" "$@"; eval "$@"; }
  eval-verbose()  { >&2 echo-verbose "$EVAL_ECHO_PREFIX" "$@"; eval "$@"; }
  eval-quiet()    { >&2 echo-quiet "$EVAL_ECHO_PREFIX" "$@"; eval "$@"; }
  eval-stderr()   { >&2 echo-stderr "$EVAL_ECHO_PREFIX" "$@"; eval "$@"; }
  veval(){ eval-verbose "$@"; }
  qeval(){ eval-quiet "$@"; }
  eeval(){ eval-stderr "$@"; }
  #
  # Always ECHO the given expression; but do not EVAL if SH_WHATIF is set.
  eval-whatif()   { ((SH_WHATIF)) && echo '#$' "$@" || eval-echo "$@"; }
  weval() { eval-whatif "$@"; }

  ### find helpers
  #
  nfind(){ qeval find -L . -name $@; }
  pfind(){ qeval find -L . -path $@; }
  rfind(){ qeval find -L -E . -regex $@; }

  ### ls helpers
  #
  # -A  show .* files except for '.'' and '..'
  # -d  list directories as plain files, not recursed
  #
  # -H  follow only symlink arguments
  # -L  follow all symlinks
  # -P  follow no symlinks
  #
  # -1  ("one") 1-column output
  # -l  ("el") use long form, show owner and group
  # -g  use long form, suppress owner
  # -o  use long form, suppress group
  # -h  use human-readable file sizes
  # -F  add file suffix [/, @, *, ...]
  #
  # -tr sort by time modified, old to new
  # -Sr sort by size, ascending
  #
  l1()    { ls -1F "$@" | tilde_compress; }
  l1r()   { l1 -r "$@"; }
  #
  ll()    { ls -oghF "$@" | tilde_compress; }
  llt()   { ll -t "$@"; }
  lltr()  { ll -tr "$@"; }
  lls()   { ll -S "$@"; }
  llsr()  { ll -Sr "$@"; }
  #
  la()    { ll -A $@; }
  lat()   { la -t "$@"; }
  latr()  { la -tr "$@"; }
  las()   { la -S "$@"; }
  lasr()  { la -Sr "$@"; }
  #
  l1d()  { l1 -d "$@"; }
  lad()  { la -d "$@"; }
  lad()  { la -d "$@"; }
  #
  # Think "ll and la but narrower": cut out permissions, link count and owner.
  #   $ ls -ohF
  #   total 520
  #   -rw-r--r--  1 toddpierzina   1.2K Mar 10 11:33 README.md
  # $1: permissions, $2: inode count, $3: owner, $4: size, $5: date/time, $6: filename
  lln() {
    ls -oF $@ \
    | sed -E \
      -e '/^total .+$/d' \
      -e 's/^([^ ]{9,}) +([[:digit:]]+) +([^ ]+) +([^ ]+) ([^ ]+ +[^ ]+ +[^ ]+) +(.+)$/\4'$'\t''\5'$'\t''\6/' \
      -e "s:\\$HOME:\\~:g" \
    | awk -F$'\t' \
      '{printf "%12'$'\'''d  %s  %s\n", $1, $2, $3}'
  }
  lan() { lln -A $@; }
  #
  # Display permissions in octal, from: http://askubuntu.com/a/152005
  # I've tried to figure out how this works but have no fucking clue.
  lso() {
    ls -ohF $@ \
    | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' \
    | sed -E -e "s:\\$HOME:\\~:g"
  }

  ### 'mv' helpers
  #
  alias mvv='mv -v'

  ### 'rm' helpers
  #
  alias rmv='rm -v'
  #
  # Delete the target of a symlink, then the symlink.
  rmln() {
    local cmd="rm"
    while [[ "$1" =~ ^- ]]; do cmd="$cmd $1" && shift; done
  
    local link="$1" && shift
    [[ -z "$link" ]] && eecho "usage: rmln [rm opts] symlink" && return 1
    [[ ! -L "$link" ]] && eecho "rmln: $link: no such symlink" && return 1
  
    local dest="$(readlink "$link")"
    [[ ! -e "$dest" ]] && eecho "rmln: $link -> $dest: no such file or directory" && return 1
    qeval "$cmd '$dest'" || return 1
  }

  ### 'tail' helpers
  #
  alias t='tail'
  alias tf='tail -f'

  ### path helpers
  #
  # Add given path element to the beginning of the variable, unless already present.
  # usage: path-prepend [var] path
  path-prepend() {
    local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
    local val="${!var}"
    [[ ! "$val" =~ (^|:)$1(:|$) ]] && export $var="$1:$val"
  }
  #
  # List path variables' elements, 1 per line.
  path-list() {
    ((! $#)) && echo-stderr 'usage: path-list PATHVAR [...]' && return 1
    local var=${1:-PATH}
    split-lines ':' <<< "${!var}" | tilde_compress
  }
  alias pecho=path-list path-echo=path-list


  # The following functions operate on stdin OR $@; [[ -t 0 ]] is true if stdin is a terminal
  # from: https://stackoverflow.com/a/30520299
  #
  # Compress '~' to value of $HOME, or vice versa.
  tilde_compress() {
    [[ ! -t 0 ]] && sed -E -e "s:\\$HOME:\\~:g" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: tilde_compress path [...], or ... | tilde_compress" && return 1
    tilde_compress <<< "$@"
  }
  tilde-expand() {
    [[ ! -t 0 ]] && sed -E -e "s:\\~:$HOME:g" && return 0
    [[ -z "$1" ]] && >&2 echo "usage: tilde-expand path [...], or ... | tilde-expand" && return 1
    tilde-expand <<< "$@"
  }
  #
  trim() {
    [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: trim str [...], or ... | trim" && return 1
    trim <<< "$@"
  }
  rtrim() {
    [[ ! -t 0 ]] && sed -E -e 's/(.*)[[:space:]]*/\1/g' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: rtrim str [...], or ... | rtrim" && return 1
    rtrim <<< "$@"
  }
  ltrim() {
    [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)/\1/g' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: ltrim str [...], or ... | ltrim" && return 1
    ltrim <<< "$@"
  }
  #
  upper() {
    [[ ! -t 0 ]] && tr '[:lower:]' '[:upper:]' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: upper word [...], or ... | upper" && return 1
    upper <<< "$@"
  }
  lower() {
    [[ ! -t 0 ]] && tr '[:upper:]' '[:lower:]' && return 0
    [[ -z "$1" ]] && >&2 echo "usage: lower word [...], or ... | lower" && return 1
    lower <<< "$@"
  }

  # Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
  join-lines() {
    local delim="${1:-, }" && shift
    local not_1st=
    sed -E -e 's/^ *(.+) *$/\1/;' \
    | while read -r line; do
        ((not_1st)) && printf "$delim" || not_1st=1
        printf "%s" "$line"
      done \
    && printf '\n'
  }
  # Split line(s) from stdin into separate lines, using $1 [,] as delimiter
  split-lines() {
      local delim="${1:-,}"
      sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
  }

  # usage: [ms places] [format]
  datetime-plus-ms() {
    local places="${1:-3}" && shift
    local format="${1:-%D %T}" && shift
    local ms="$(perl - <<-'EOF'
      use Time::HiRes qw(time);
      my $t = time;
      printf "%06d", ($t - int($t)) * 1000000;
    EOF
    )00000"
    date +"$format.${ms:0:$places}"
  }

  datetime-epoch-ms() {
    echo "$(perl - <<-'EOF'
      use Time::HiRes qw(time);
      printf "%d", time * 1000;
    EOF
    )"
  }

  safe-source() {
    local opt_quiet=; [[ "$1" =~ ^(-q|--quiet) ]] && opt_quiet=1 && shift
    local script_path="$1"; shift
    [[ -z "$script_path" ]] && echo-stderr "usage: safe-source script" && return 1
    if [[ ! -e "$script_path" ]]; then
      ((! opt_quiet)) && echo-stderr "safe-source: $script_path: No such file"
      return 1
    fi
    . "$script_path"
  }

  .tidy_system_path() {
    local old_path="$PATH"
    # echo "PATH_0:"
    # path-list PATH

    # Homebrew expects sbin to be in the path.
    path-prepend PATH "/usr/local/sbin"
    # echo "PATH_1: /usr/local/sbin"
    # path-list PATH

    # Put Ruby 3 in front of system's 2.6.
    path-prepend PATH "/usr/local/opt/ruby/bin"
    # echo "PATH_2: /usr/local/opt/ruby/bin"
    # path-list PATH

    # Put my homemade scripts and other miscellany here at the start of the classpath.
    path-prepend PATH "/usr/local/opt/gnu-tar/libexec/gnubin"
    path-prepend PATH "$HOME/bin"
    path-prepend PATH "$HOME"
    # echo "PATH_3: HOME, HOME/bin, /usr/local/opt/gnu-tar/libexec/gnubin"
    # path-list PATH

    [[ "$old_path" == "$PATH" ]] && return 0

    .tick-bashrc ".tidy_system_path: PATH updated from:"
    local IFS=:; for p in $old_path; do .tick-bashrc ": $p"; done
    .tick-bashrc ".tidy_system_path: PATH updated to:"
    local IFS=:; for p in $PATH; do .tick-bashrc ": $p"; done
  }
  .tidy_system_path

  .setup-docker-dvm() {
    local dvm_sh='/usr/local/opt/dvm/dvm.sh'
    if ! type -t docker >&/dev/null; then
      # .tick-bashrc '.setup-docker-dvm: docker not installed'
      return 0
    elif type -t dvm >&/dev/null; then
      # .tick-bashrc '.setup-docker-dvm: dvm already loaded'
      return 0
    elif safe-source "$dvm_sh"; then
      .tick-bashrc ".setup-docker-dvm: loaded: $dvm_sh"
      return 0
    else
      .tick-bashrc "!! .setup-docker-dvm: $dvm_sh: No such file"
      return 1
    fi
  }
  .setup-docker-dvm


  alias .reload-bashrc='qeval . ~/.bashrc' .rlbrc='.reload-bashrc'

}
.bashrc-wrapper


.tick-bashrc -e 'printf "[FINISH-FILE] ~/.bashrc \$\$=$$ \$PPID=$PPID, \$SHLVL=$SHLVL, \$-=$- fns=%d\n" $(declare -F | wc -l)'
