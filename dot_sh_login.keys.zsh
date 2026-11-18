#!/usr/bin/env zsh

# Shell-agnostic functions for managing macOS applicatioon shortcut keys.
.sh-login-keys-wrapper() {
  local dot_fname='.sh_login.keys'

  # Do not execute scripts if they have already been run this session and are not modified since.
  .dot-ok-to-skip ~/$dot_fname && return 

  .reload-sh-login-keys() {
    .dot-reset-mtimes
    eval-quiet source ~/$dot_fname
  }

  .tick-sh-login-keys() { .tick -s $dot_fname "$SHELL \$\$=$$ $@"; }
  .tick-start-line .tick-sh-login-keys $dot_fname


  function keys() {
    local USAGE="usage: keys [--list] or keys --add domain key_string"
    if [[ -z "$1" ]] || matches "$1" '^(-l|--list)$'; then
      keys-list
    elif matches "$1" '^(-a|--add)$' && [[ -n "$3" ]]; then
      keys-add "$2" "$3"
    else
      echo-error "$USAGE" && return 1
    fi
  }

  function keys-list() {
    echo-debug 'START keys-list'
    local domain=''
    defaults find NSUserKeyEquivalents 2>&1 | while read line; do
      echo-debug "LINE: $line"
      if matches "$line" "^Found 1 keys in domain '.+': \{\$"; then
        echo-debug "DOMAIN"
        domain="$(sed -E -n "s/^Found 1 keys in domain '(.+)': {\$/\\1/p" <<< "$line")"
        echo-debug "DOMAIN=$domain"
      # # "033Actions033Markdown033Markdown List" = "@$8";
      elif matches "$line" "^\"033.+\" = \".+\";\$"; then
        echo-debug "MENU KEY_STRING"
        local menu="$(sed -E -n 's/^"033(.+)" = ".+";$/\1/p' <<< "$line")"
        echo-debug "  MENU=$menu"
        local key_string="$(sed -E -n 's/^"033.+" = "(.+)";$/\1/p' <<< "$line")"
        echo-debug "  KEY_STRING=$key_string"
        local key_names="${key_string//\@/[⌘] + }"
        local key_names="${key_names//\^/[^] + }"
        local key_names="${key_names//\$/[Shift] + }"
        local key_names="${key_names//\~/[⌥] + }"
        printf "  keys --add %-40s %-60s %-16s  # %s\n" "'$domain'" "'${menu//033/->}'" "'$key_string'" "$key_names"
      else
        echo-debug "IGNORE"
      fi
    done
    echo-debug 'FINISH keys-list'
  }

  function keys-add() {
    echo "keys-add $1 $2"
  }

  # if ((_DOT_SKIP_ONYX_SETUP)); then
  #   .tick-sh-login-keys "[skip] Onyx: _DOT_SKIP_ONYX_SETUP"
  # elif ! is-shell-interactive; then
  #   .tick-sh-login-keys "[skip] Onyx: shell is not interactive"
  # else
  #   .setup-onyx() {
  #     .tick-sh-login-keys "[start] Onyx initialization"

  #     .tick-sh-login-keys " [end] Onyx initialization"
  #   }
  #   .setup-onyx
  # fi

  .dot-store-mtime ~/$dot_fname
  .tick-sh-login-keys "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
}
.sh-login-keys-wrapper && unset -f .sh-login-keys-wrapper
