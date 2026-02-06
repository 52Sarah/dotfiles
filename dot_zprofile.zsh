#!/usr/bin/env zsh

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

zprofile-wrapper() {
  local dot_fname='.zprofile'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-zprofile() {
    unset "_DOT_MTIMES[.zprofile]"
    eval-quiet source ~/.zprofile
  }
  alias .rlzp='eval-verbose .reload-zprofile'

  is-command .tick || source ~/.tick.sh
  .tick-zprofile() { .tick -s ".zprofile" $@; }
  .tick-zprofile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' $HOME/.zprofile)"

  safe-source ~/.sh_profile


  # TODO can we remove this and let Zsh's internals handle whether to source it?
  [[ -e ~/.zshrc ]] && source ~/.zshrc


  # added by Snowflake SnowSQL installer v1.2
  local SNOWSQL_PKG="/Applications/SnowSQL.app/Contents/MacOS"
  if [[ -e "$SNOWSQL_PKG" ]]; then
    path-prepend "$SNOWSQL_PKG"
    .tick-zprofile " ... prepended $SNOWSQL_PKG to PATH"
  else
    .tick-zprofile " ... no $SNOWSQL_PKG to add to PATH"
  fi


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-zprofile "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname], PROMPT=[$PROMPT]"
}
zprofile-wrapper $@
unset -f zprofile-wrapper .tick-zprofile
