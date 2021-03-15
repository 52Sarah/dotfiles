#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Non-interactive shells read the $BASH_ENV file, if any (this file).

.bashrc.USER() {

  # Simple login file debugging, enabled if caller checks that ~/.tick.LOGINSCRIPT exists 
  # and sets prefix accordingly.
  #
  # Usage: .tick_bpu -s script_name [message [...]]
  .tick() { 
    local USAGE='usage: .tick[eval] -s script_name [msg|expr [...]]'
    [[ ! "$1" =~ ^-s|--script ]] && >&2 echo "$USAGE" && return 1
    local script_name="$2" && shift 2 && [[ -z "$script_name" ]] && echo "$USAGE" && return 1
    local dt="$(date +'%D %T')"
    printf "%s %-22s %s\n" "$dt" "$script_name" "$*" >> "$HOME/.tick.log"
  }
  #
  # Like .tick_bpu but woth delayed evaluation of potentially expensive message
  # Usage: .tickeval_bpu -s script_name [expr [...]]
  .tickeval() {
    local sw="$1" nm="$2"
    shift 2
    .tick "$sw" "$nm" "$(eval "$*")"
  }


  unset TICK_BASHRC_USER
  if type -t .tick >&/dev/null && [[ -e "$HOME/.tick.bashrc.$USER" ]]; then
    export TICK_BASHRC_USER='~/.bashrc.$USER'
    .tick_bru() { .tick -s "$TICK_BASHRC_USER" "$@"; }
    .tickeval_bru() { .tickeval -s "$TICK_BASHRC_USER" "$@"; }
  else
    .tick_bru() { :; }
    .tickeval_bru() { :; }
  fi

  .tickeval_bru 'printf -- "-- START -- \$-=[%s] PID,PPID,COMMAND=[%s] \$_=[%s]\n" "$-" "$(ps -o pid,ppid,command -p $PPID | tail -n -1)" "$_"'


  # Put my homemade scripts and other miscellany here at the start of the classpath.
  [[ -d "$HOME/bin" && ! "$PATH" =~ $HOME/bin ]] && export PATH="$HOME/bin:$PATH"


  # Expand stdin '~' to value of $HOME, or compress value of $HOME to ~
  tilde-expand() { sed -E -e "s:\\~:$HOME:g"; }
  tilde-compress() { sed -E -e "s:\\$HOME:\\~:g"; }

  # Expand/compress user's home folder to/from the literal string '$HOME' (for writing commands to a script file, generally)
  home-expand() { sed -E -e "s:\\\$HOME:$HOME:g"; }
  home-compress() { sed -E -e "s:$HOME:\\$HOME:g"; }

  trim() { sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g'; }
  rtrim() { sed -E -e 's/(.*)[[:space:]]*/\1/g'; }
  ltrim() { sed -E -e 's/[[:space:]]*(.*)/\1/g'; }

  # Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
  join-lines() {
    local delim="${1:-, }" && shift
    local not1st=0
    sed -E -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/;' | \
      while read -r ln; do
        ((not1st)) && printf "$delim" || not1st=1
        printf "%s" "$ln"
      done && \
      printf '\n'
  }
  # Split line(s) from stdin into separate lines, using $1 [,] as delimiter
  split-lines() {
      local delim="${1:-,}"
      sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
  }
  # List path variable's elements, one per line
  echo-p() {
    local var=${1:-PATH}
    split-lines ':' <<< "${!var}" | tilde-compress
  }


  # Usage: [ms places] [format]
  datetime-plus-ms() {
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


  alias .reload-bashrc-user='. $HOME/.bashrc.$USER'
  alias .rlbru='.reload-bashrc-user'
}
.bashrc.USER "$@"
