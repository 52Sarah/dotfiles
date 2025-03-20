#!/usr/bin/env zsh

[[ -z "$_DOT_SH_MTIMES" ]] && typeset -A _DOT_SH_MTIMES
if [[ -z "$_DOT_SH_MTIMES[zprofile]" ]] || (( $(stat -L -f '%m' "$HOME/.zprofile") > _DOT_SH_MTIMES[zprofile] )); then

  # At startup, Zsh reads, in order, from:
  #   1. ~/.zshenv
  #   2. ~/.zprofile for login shells
  #   3. ~/.zshrc for interactive shells
  #   4. ~/.zlogin for login shells
  # See: https://zsh.sourceforge.io/Doc/Release/Files.html

  [[ -e ~/.sh_bootstrap_profile ]] && source ~/.sh_bootstrap_profile

  is-defined .tick || source ~/.tick.sh
  .tick-zprofile() { .tick -s ".zprofile" $@; }
  .tick-zprofile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' $HOME/.zprofile)"

  [[ -e ~/.zshrc ]] && source ~/.zshrc

  zprofile-wrapper() {
    .tick-zprofile "[START-WRAPPER] (\$\$=$$)"

    echo-error 'This space intentionally left blank.'

    .tick-zprofile "[END-WRAPPER] (\$\$=$$)"
  }
  zprofile-wrapper

  .reload-zprofile() {
    unset "_DOT_SH_MTIMES[zprofile]"
    eval-quiet source ~/.zprofile
  }
  alias .rlzp='veval .reload-zprofile'

  .source-extra-start-files '.zprofile'

  _DOT_SH_MTIMES+=(zprofile "$(stat -L -f '%m' $HOME/.zprofile)")
  .tick-zprofile "[END-FILE] (\$\$=$$), mtime=$_DOT_SH_MTIMES[zprofile], PROMPT=[$PROMPT]"
fi

