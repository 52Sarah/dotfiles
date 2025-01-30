#!/usr/bin/env zsh

if [[ -z "$_DOT_ZSHRC_MTIME" ]] || (( $(stat -L -f '%m' ~/.zshrc) > _DOT_ZSHRC_MTIME )); then

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

zshrc-wrapper() {

  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  # _TICK_x variables control its behavior; all default to false/0/off.
  # export _TICK_OFF= _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
  is-defined .tick || . ~/.tick.sh
  .tick-zshrc() { .tick -s '.zshrc' $@; }
  .tick-zshrc "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zshrc)" #, \$PATH=[$PATH]"


  # Private env vars, etc. can be in the optional file ~/.secrets.
  if [[ -e ~/.secrets ]]; then
    source ~/.secrets
    .tick-zshrc '... read ~/.secrets'
  fi

  # Put my homemade scripts and other miscellany here at the start of the classpath.
  if ! matches "$PATH" "$HOME/bin(:|$)"; then
    path-prepend "$HOME/bin"
    .tick-zshrc '... prepended $HOME/bin to PATH'
  fi

  ### START: Zsh-specific settings from zshrc.zsh-template
  #
  export ZSH="$HOME/.oh-my-zsh"

  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
  ZSH_THEME=eastwood

  # Uncomment the following line if pasting URLs and other text is messed up.
  # DISABLE_MAGIC_FUNCTIONS="true"

  zstyle ':omz:update' mode auto      

  # Uncomment the following line if you want to disable marking untracked files
  # under VCS as dirty. This makes repository status check for large repositories
  # much, much faster.
  # DISABLE_UNTRACKED_FILES_DIRTY="true"

  # Uncomment the following line if you want to change the command execution time
  # stamp shown in the history command output.
  # You can set one of the optional three formats:
  # "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
  # or set a custom format using the strftime function format specifications,
  # see 'man strftime' for details.
  # HIST_STAMPS="mm/dd/yyyy"

  # Would you like to use another custom folder than $ZSH/custom?
  # ZSH_CUSTOM=/path/to/new-custom-folder

  # Standard plugins can be found in $ZSH/plugins/
  # Custom plugins may be added to $ZSH_CUSTOM/plugins/
  # See: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
  plugins=(asdf)
  # plugins+=(ssh git git-prompt)
  # plugins+=(macos)
  # plugins+=(colored-man-pages)
  # plugins+=(sublime)
  # plugins+=(mvn)
  .tick-zshrc "... loaded zsh plugins: $plugins"

  # aws docker jira kubectl kubectx
  # brew alias-finder common-aliases command-not-found history-substring-search systemd
  # jsontools
  # lpass
  # vscode
  # node nvm pip yarn
  # react-native

  source $ZSH/oh-my-zsh.sh

  # Compilation flags
  # export ARCHFLAGS="-arch $(uname -m)"

  # Set personal aliases, overriding those provided by Oh My Zsh libs,
  # plugins, and themes. Aliases can be placed here, though Oh My Zsh
  # users are encouraged to define aliases within a top-level file in
  # the $ZSH_CUSTOM folder, with .zsh extension. Examples:
  # - $ZSH_CUSTOM/aliases.zsh
  # - $ZSH_CUSTOM/macos.zsh
  
  #
  ### FINISH: Zsh-specific settings from zshrc.zsh-template

  #
  ### Interactive shell options.
  #
  # ## expansion and globbing
  setopt EXTENDED_GLOB
  # setopt BAD_PATTERN  # print error msg for bad glob pattern
  # setopt CASE_GLOB    # glob case-sensitive
  # setopt CASE_MATCH   # regex case-sensitive
  # setopt CASE_PATHS   # paths case-sensitive
  # setopt GLOB         # perform globbing
  # setopt GLOB_SUBST   # enable globbing after parameter substitution
  # setopt NO__MATCH    # if glob has no matches, error
  #
  # ## input/output
  setopt PATH_SCRIPT          # check current directory for script, then command path
  #
  # ## job control
  setopt LONG_LIST_JOBS
  # setopt MONITOR      # allow job control
  #
  # ## functions
  # setopt WARN_CREATE_GLOBAL   # warn if global parameter created in function
  # setopt WARN_NESTED_VAR      # warn if enclosing function parameter is set


  export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
  export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
  _QUIET=1 safe-source $HOME/configure_nexus_npm_token.sh

  #
  ### PWR-JUMPER
  #
  source $HOME/.pwrfunc.sh

  .tick-zshrc "[END-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH])"
}

#
### 'echo/printf' helpers
#   d* = only print to stderr if _DEBUG is set
#   v* = only print to stderr if _VERBOSE or _DEBUG is set
#   q* = always print to stdout unless _QUIET is set
#   e* = always print to stderr
# usage, e.g.: echo-verbose [--prefix 'line prefix'] text
echo-with-prefix() { 
  local prefix=; matches "$1" '^-p|--prefix$' && prefix="$2" && shift 2
  echo "$prefix$@"
}
echo-prefix() { echo-with-prefix $@; }
#
_debug()   { ((_DEBUG)); }
_verbose() { ((_DEBUG || _VERBOSE)); }
_quiet()   { ((_QUIET && !(_DEBUG || _VERBOSE))); }
_unquiet() { ((! _QUIET)); }
#
echo-stderr() { >&2 echo-with-prefix $@; }
echo-error()  { >&2 echo-with-prefix $@; }
echo-stdout() { echo-with-prefix $@; }
#
echo-debug()    { _debug && echo-with-prefix $@; }
echo-verbose()  { _verbose && echo-with-prefix $@; }
echo-quiet()    { _quiet || echo-with-prefix $@; }
echo-unquiet()  { _quiet || echo-with-prefix $@; }
#
eecho() { echo-error $@; }
decho() { echo-debug $@; }
vecho() { echo-verbose $@; }
qecho() { echo-quiet $@; }
#
decho-stderr() { >&2 echo-debug $@; }
vecho-stderr() { >&2 echo-verbose $@; }
qecho-stderr() { >&2 echo-quiet $@; }
#
eecho-debug()   { >&2 echo-debug $@; }
eecho-verbose() { >&2 echo-verbose $@; }
eecho-quiet()   { >&2 echo-quiet $@; }
eecho-unquiet() { eecho-quiet $@; }
#
#
printf-with-prefix() {
  local prefix=; [[ "$1" =~ -p ]] && prefix="$2" && shift 2
  printf "$prefix$@"
}
#
printf-error()  { >&2 printf-with-prefix $@; }
printf-stderr() { >&2 printf-with-prefix $@; }
printf-stdout() { printf-with-prefix $@; }
#
printf-debug()    { _debug && printf-with-prefix $@; }
printf-verbose()  { _verbose && printf-with-prefix $@; }
printf-quiet()    { ! _quiet && printf-with-prefix $@; }
printf-unquiet()  { printf-quiet $@; }
#
eprintf() { printf-error $@; }
dprintf() { printf-debug $@; }
vprintf() { printf-verbose $@; }
qprintf() { printf-quiet $@; }
#
dprintf-stderr()  { >&2 printf-debug $@; }
eprintf-debug()   { >&2 printf-debug $@; }
vprintf-stderr()  { >&2 printf-verbose $@; }
eprintf-verbose() { >&2 printf-verbose $@; }
qprintf-stderr()  { >&2 printf-quiet $@; }
eprintf-quiet()   { >&2 printf-quiet $@; }

#
### Echo (and bubble) return status ($?) as-is, or use $1 for 0, $2 for non-0.
echo-status() {
  local status=$?
  _debug && eecho-var status
  if ((status == 0)); then
    echo "${1:-0}"
  else
    echo "${2:-$status}"
  fi
  return $status
}
secho()        { echo-status $@; }
eecho-status() { >&2 echo-status $@; }

#
### List all variables on stdout matching $1 (globbing *, etc.) and their values.
#   Return error status if no such variable (as-is or glob expanded) is defined.
echo-glob() {
  [[ -z "$1" ]] && echo-stderr "usage: echo-glob patt [...]" && return 1
  local ret=1
  for patt in $@; do
    [[ ! "$patt" =~ \* ]] && patt="${patt}*"
    local indirect_vars="$(eval echo $(printf "\${(P)%s}" "$patt"))"
    [[ -z "$indirect_vars" ]] && printf '%s=\n' "$patt" && continue
    local IFS=' '
    for var in $indirect_vars; do
      printf "%s=%s\n" "$var" "${(P)var}"
      ret=0
    done
  done
  return $ret
}
gecho() { echo-glob $@; }
eecho-glob() { >&2 echo-glob $@; }
decho-glob() { _debug && echo-glob $@; }
vecho-glob() { _verbose && echo-glob $@; }
qecho-glob() { _quiet || echo-glob $@; }
#
# Replace newlines, carriage-returns and tabs with \n, \r and \t.
echo-unescape() {
  if [[ ! -t 0 ]]; then
    sed -E -n 'l;' \
    | join-lines '\\n' \
    | sed -E 's/\$(\\n)/\1/g; s/\$$//g;'
    return 0;
  fi
  [[ -z "$1" ]] && eecho 'usage: echo-unescape text [...] or echo-unescape <<< text' && return 1
  echo-unescape <<< $@
}
#
echo-var() {
  [[ -z "$1" ]] && echo-error usage: echo-var varname [...]
  local var value
  while [[ -n "$1" ]]; do
    var="$1"; shift 1
    value="${(P)var}"
    echo "$var: $value"
  done
}
eecho-var() { >&2 echo-var $@; }
decho-var() { _debug && echo-var $@; }
vecho-var() { _verbose && echo-var $@; }
qecho-var() { _quiet || echo-var $@; }
alias echo-vars=echo-var
alias eecho-vars=eecho-var
alias decho-vars=decho-var
alias vecho-vars=vecho-var
alias qecho-vars=qecho-var

#
### 'echo' / 'eval' helpers
#
# Always ECHO the given expression; but do not EVAL if _EVAL_WHATIF is set.
: ${_WHATIF_PREFIX:=#$}
eval-whatif() { ((_EVAL_WHATIF)) && echo "$_WHATIF_PREFIX" $@ || eval-echo $@; }
weval() { eval-whatif $@; }
#
# Conditionally echo the expression to stderr before executing it, using
# similar logic as echo-* and printf-*.
: ${_EVAL_ECHO_PREFIX:=\>$}
eval-echo() { 
  local _EVAL_ECHO_PREFIX=$_EVAL_ECHO_PREFIX
  matches "$1" '^-p|--prefix$' ]] && _EVAL_ECHO_PREFIX="$2" && shift 2
  >&2 echo "$_EVAL_ECHO_PREFIX $@"; 
  eval "$@"
}
eval-stderr()   { eval-echo $@; }
eval-error()    { eval-echo $@; }
eval-debug()    { if _debug; then eval-echo $@; else eval "$@"; fi; }
eval-verbose()  { if _verbose; then eval-echo $@; else eval $@; fi; }
eval-quiet()    { if _quiet; then eval $@; else eval-echo $@; fi; }
eval-unquiet()  { eval-quiet $@; }
#
eeval() { eval-echo $@; }
deval() { eval-debug $@; }
veval() { eval-verbose $@; }
qeval() { eval-quiet $@; }

# True if $1 is any kind of executable: alias, keyword, function, builtin, file
is-defined() {
  [[ -z "$1" ]] && echo-error "usage: is-defined command" && return 1
  type $1 >&/dev/null
}

# Source given file(s). If a file does not exist, echo-unquiet a warning and ignore.
safe-source() {
  [[ -z "$1" ]] && echo-stderr "usage: safe-source file [...]" && return 1
  while [[ -n "$1" ]]; do
    local script_path="$1"; shift
    if [[ ! -e "$script_path" ]]; then
      ((! _QUIET)) && echo-stderr "safe-source: $script_path: No such file"
    else
      eval-quiet . "$script_path"
    fi
  done
}

#
### du helpers
#
du-dir() {
  local USAGE="usage: du-dir [--depth n] [--units h|k|m|:properties :start  --info  --no-build-cache --no-configuration-cache --no-configure-on-demand] [dir]"
  local depth=1 units='h' dir='.'
  while [[ "$1" ]]; do case "$1" in
    -d|--depth) depth="$2" && shift 2;;
    -u|--units) units="$2" && shift 2;;
    *)          dir="${1:-$dir}" && shift 1 && break;;
  esac; done
  [[ ! -d "$dir" ]] && printf-stderr "du-dir: %s: no such directory\n%s\n" "$dir" "$USAGE" && return 1
  find -L "$dir" -type dir -d $depth -exec du -s -$units {} \;
}

#
### array/lines helpers
#
join-array() {
  local delim="$1" && shift
  local i_first=1
  decho-var delim i_first $@
  for i in $@; do
    vecho-var i
    [[ -n "$i_first" ]] && printf "%s" "$i" && unset i_first || printf "%s%s" "$delim" "$i"
  done
  printf '\n'
}
#
uniq-array() {
  local i_first=1
  decho-var delim i_first $@
  local buff=
  for i in $@; do
    vecho-var i
    if (( i_first )); then
      buff="$i"
      unset i_first
    else
        bu  ff="$(printf '%s\n%s' "$buff" "$i")"
    fi
  done
  echo "$buff" | sort -s | uniq
}
#
# Concatenate trimmed lines from stdin onto a single line, delimited by $1 (or '')
join-lines() {
    delim="${1:-}"
    sed -E -n -e 's/^[[:space:]]*(.+)[[:space:]]*$/\1/p' | while read -r ln; do [[ -n "$not1st" ]] && printf "%s" "$delim" || not1st=1; printf "%s" "$ln"; done; printf '\n'
}
# Split line(s) from stdin into separate lines, using $1 [,] as delimiter
split-lines() {
    local delim="${1:-,}"
    sed -E -e "s/([^$delim]*)$delim([^$delim]*)/\\1"\\$'\n'"\\2/g"
}


#
### path helpers
#
# List path variable's elements, 1 per line.
path-list() {
  local var=${1:-PATH}
  split-lines ':' <<< "${(P)var}"
}
path-echo() { qeval path-list $@; }
#
# Add given path element to the end of the variable, or move it there if already present.
# usage: path-append [--prepend] [var] path
path-append() {
  local opt_prepend=; [[ "$1" =~ -p ]] && opt_prepend='--prepend' && shift
  local var='PATH'; [[ -n "$2" ]] && var="$1" && shift
  [[ -z "$1" ]] && echo-stderr "usage: path-append [var] path" && return 1
  
  local elem="$1" && shift
  local elements="${(P)var}"
  if [[ -z "$elements" ]]; then
    export $var="$elem"
    return 0
  elif [[ "$elements" = "$elem" ]]; then
    return 0
  fi

  elems_minus_elem="$(sed -e 's!:'"$elem"':!:!g' <<< ":$elements:")"
  echo-debug "elems_minus_elem=[$elems_minus_elem]"
  printf-debug "$_EVAL_ECHO_PREFIX path-append %s %s %s\n" "$opt_prepend" "$var" "$elem" && eeval path-list elems_minus_elem
  if ((opt_prepend)); then
    eval-debug export $var="$elem${elems_minus_elem:0:((${#elems_minus_elem}-1))}"
  else
    eval-debug export $var="${elems_minus_elem:1}$elem"
  fi
}
path-prepend() { path-append --prepend $@; }


# The following functions operate on stdin OR $@; [[ -t 0 ]] is true if stdin is a terminal
# from: https://stackoverflow.com/a/30520299
#
# Does $1 match regex $2? Quoting works for Zsh and Bash.
matches() {
  [[ -z "$2" ]] && eecho "usage: matches text pattern" && return 1
  local text="$1" && shift
  local pattern="$*" && shift
  [[ "$text" =~ $pattern ]]
}
#
ends_with() {
  [[ -z "$2" ]] && echo-error "usage: ends_with [--verbose] text suffix_to_test" && return 1
  [[ "$1" =~ .*$2$ ]]
}
starts_with() {
  [[ -z "$2" ]] && echo-error "usage: starts_with [--verbose] text prefix_to_test" && return 1
  [[ "$1" =~ ^$2.*$ ]]
}
#
trim() {
  [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)[[:space:]]*/\1/g' && return 0
  trim <<< $@
}
rtrim() {
  [[ ! -t 0 ]] && sed -E -e 's/(.*)[[:space:]]*/\1/g' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: rtrim str [...], or ... | rtrim" && return 1
  rtrim <<< $@
}
ltrim() {
  [[ ! -t 0 ]] && sed -E -e 's/[[:space:]]*(.*)/\1/g' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: ltrim str [...], or ... | ltrim" && return 1
  ltrim <<< $@
}
#
upper() {
  [[ ! -t 0 ]] && tr '[:lower:]' '[:upper:]' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: upper word [...], or ... | upper" && return 1
  upper <<< $@
}
lower() {
  [[ ! -t 0 ]] && tr '[:upper:]' '[:lower:]' && return 0
  [[ -z "$1" ]] && >&2 echo "usage: lower word [...], or ... | lower" && return 1
  lower <<< $@
}
#
substring_before_first() {
  local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line%%${delim}*}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_before_first [--delim DELIM] text [DELIM], or ... | substring_before_first [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_before_first --delim "$delim" <<< "$1"
}
substring_before_last() {
  local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line%${delim}*}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_before_last [--delim DELIM] text [DELIM], or ... | substring_before_last [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_before_last --delim "$delim" <<< "$1"
}
substring_after_first() {
  local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line#*${delim}}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_after_first [--delim DELIM] text [DELIM], or ... | substring_after_first [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_after_first --delim "$delim" <<< "$1"
}
substring_after_last() {
  local delim='.'; matches "$1" '--delim|-d' && delim="$2" && shift 2
  [[ ! -t 0 ]] && read line && printf "%s\n" "${line##*${delim}}" && return 0
  [[ -z "$1" ]] && >&2 echo "usage: substring_after_last [--delim DELIM] text [DELIM], or ... | substring_after_last [--delim DELIM]" && return 1
  [[ -n "$2" ]] && delim="$2"
  substring_after_last --delim "$delim" <<< "$1"
}
#
# Expand '~' to value of $HOME, or compress value of $HOME to ~
tilde-compress() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'tilde-compress' '${path//$HOME/\~}' $@ && return 0
  [[ -z "$1" ]] && eecho "usage: tilde-compress path [...]" && return 1
  tilde-compress <<< $@
}
tilde-expand() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'tilde-expand' '${path//\~/$HOME}' && return 0
  [[ -z "$1" ]] && eecho "usage: tilde-expand path [...]" && return 1
  tilde-expand <<< $@
}
#
# Compress user's home folder to the literal string '$HOME' (for writing commands to a script file, generally)
home-compress() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'home-compress' '${path//$HOME/\$HOME}' $@ && return 0
  [[ -z "$1" ]] && eecho "usage: home-compress path [...]" && return 1
  home-compress <<< $@
}
home-expand() {
  [[ ! -t 0 ]] && tilde-home-compress-expand 'home-expand' '${path//\$HOME/$HOME}' $@ && return 0
  [[ -z "$1" ]] && eecho "usage: home-expand path [...]" && return 1
  home-expand <<< $@
}
#
# Convert stdin using the path_expr
tilde-home-compress-expand() {
  [[ -z "$2" ]] && eecho "usage: tilde-home-compress-expand ${1:-fn_name} path_expr" && return 1
  local fn_name="$1" && shift
  local path_expr="$1" && shift

  local delim= path=
  while read path; do
    printf '%s%s' "$delim" "$(eval "echo $path_expr")"
    delim=' '
  done
  printf '\n'
}


alias .reload-zshrc='qeval . ~/.zshrc'
alias .rlzrc='qeval .reload-zshrc'

zshrc-wrapper $@

export _DOT_ZSHRC_MTIME="$(stat -L -f '%m' ~/.zshrc)"
.tick-zshrc "[END-FILE] (\$\$=$$), mtime=$_DOT_ZSHRC_MTIME" #, \$PATH=[$PATH])"

fi