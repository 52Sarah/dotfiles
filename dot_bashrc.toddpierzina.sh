#!/usr/bin/env bash

# For all interactive shells (basically at a command prompt), Bash reads, in order:
# .bash_profile || .bash_login || .profile; once it finds one it stops looking.
# Non-interactive shells read the $BASH_ENV file, if any (this file).

.bashrc.USER() {

  # local tick_prefix= && [[ -e "$HOME/.tick.bashrc.$USER" ]] && tick_prefix='[.bashrc.$USER]'
  # .tickeval "$tick_prefix" 'printf -- "-- START -- \$_=[%s] \$-=[%s] PID,PPID,COMMAND,COMM=[%s]\n" "$_" "$-" "$(ps -o pid,ppid,command,comm -p $PPID | tail -n -1)"'

  # Put my homemade scripts and other miscellany here at the start of the classpath.
  [[ -d "$HOME/bin" && ! "$PATH" =~ $HOME/bin ]] && export PATH="$HOME/bin:$PATH"


  # Expand stdin '~' to value of $HOME, or compress value of $HOME to ~
  tilde-expand() { sed -E -e "s:\\~:$HOME:g"; }
  tilde-compress() { sed -E -e "s:\\$HOME:\\~:g"; }

  # Expand/compress user's home folder to/from the literal string '$HOME' (for writing commands to a script file, generally)
  home-expand() { sed -E -e "s:\\\$HOME:$HOME:g"; }
  home-compress() { sed -E -e "s:$HOME:\\$HOME:g"; }


  # Concatenate trimmed lines from stdin onto a single line, delimited by $1 [, ]
  join-lines() {
    local delim="${1:-, }" && shift
    local not1st=0
    sed -E -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | \
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
