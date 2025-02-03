#!/usr/bin/env zsh

# if [[ -z "$_DOT_ZPROFILE_MTIME" ]] || (( $(stat -L -f '%m' ~/.zprofile) > _DOT_ZPROFILE_MTIME )); then

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -e ~/.sh_bootstrap ]] && source ~/.sh_bootstrap

# Simple login file debugging to ~/.tick.log and/or stdout/stderr.
# _TICK_x variables control its behavior; all default to false/0/off.
# export _TICK_OFF= _TICK_ON= _TICK_STDERR= _TICK_STDOUT=
export _TICK_INDENT=
. ~/.tick.sh
.tick-zprofile() { .tick -s '.zprofile' $@; }
.tick-zprofile "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.zprofile)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

if [[ -e ~/.zshrc ]]; then
  .tick-zprofile '... reading ~/.zshrc...'
  . ~/.zshrc
  .tick-zprofile '... read ~/.zshrc'
fi

zprofile-wrapper() {

  .tick-zprofile "[START-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

  # Shell scripts executed with sh will read this file.
  export ENV=~/.zprofile

  export EDITOR=vim
  export CLICOLOR=1

  # Uncomment to color output even when being piped.
  # Turning this on has an adverse interaction with a few tools.
  export CLICOLOR_FORCE=1

  export CASE_SENSITIVE="true"
  export ENABLE_CORRECTION="true"
  export COMPLETION_WAITING_DOTS="%F{white}waiting...%f"

  # See: https://ss64.com/bash/less.html
  # -#, --shift               Percent of screen to scroll right and left for wide files
  # -A, --SEARCH-SKIP-SCREEN  Search just after current line, not visible page
  # -F, --quit-if-one-screen  Do not display prompt for short files
  # -g, --hilite-search       Only hilite one search result
  # -i, --ignore-case         Ignore case unless pattern contains uppercase letters
  # -J, --status-column       Displays column at left for search matches
  # -m, --long-prompt         Prompts like 'more'; -M even more verbose
  # -n, --line-numbers        Suppress line numbers in prompt
  # -N, --LINE-NUMBERS        Show line numbers at start of each line
  # -q, --quit-at-eof         Exit second time at eof, not just with 'q'; -Q quits first time
  # -r, --raw-control-chars   Render all escape sequences properly; -R renders only colors
  # -s, --squeeze-blank-lines Consecutive blank lines shown as one
  # -S, --chop-long-lines     Truncate long lines, do not wrap
  # -w, --hilite-unread       Highlight "new" line after 1+ pages forward movement; -W after any 1+ lines
  # -X, --no-init             Do not clear screen when loading
  export LESS='--shift=.33 --SEARCH-SKIP --quit-if-one --status-column --LONG-PR --quit-at-eof --raw --squeeze --HILITE-UNREAD --no-init'
  export LESSEDIT='subl --new-window --wait --stay %f\:%lm'

  export HISTCONTROL=ignoreboth
  export HISTSIZE=100000
  export HISTFILESIZE=$HISTSIZE

  ### Login shell options
  #
  # ## changing directories
  setopt AUTO_CD        # if command is not defined, try to cd instead
  setopt AUTO_PUSHD     # cd pushes onto stack
  setopt PUSHD_IGNORE_DUPS
  setopt PUSHD_MINUS    # more intuitive +/- when moving to stack by position
  #
  # ## completion
  setopt ALWAYS_TO_END    # move cursor to end of word after any completion
  setopt COMPLETE_IN_WORD # complete from both ends of word
  #
  # ## history
  setopt NO__BANG_HIST        # do not perform ! history expansion
  setopt EXTENDED_HISTORY     # save timestamp and duration seconds to history file
  setopt HIST_EXPIRE_DUPS_FIRST
  setopt HIST_IGNORE_DUPS     # ignore subsequent identical lines
  setopt HIST_IGNORE_SPACE    # ignore lines beginning with space
  setopt HIST_VERIFY          # load line into buffer, do not execute immediately
  setopt SHARE_HISTORY
  #
  # ## input/output
  setopt CORRECT_ALL          # try to correct spelling of entire line
  setopt INTERACTIVE_COMMENTS # allow comments in interactive shells
  #
  # ## prompting
  setopt PROMPT_SUBST   # expansion and substitution are performed in prompts


  #
  ### 'ack' helpers
  #
  if is-defined ack; then
    alias ack-help-types='qeval ack --help-types'
    alias ack-java='qeval ack --type=java'; alias ackj='ack-java'
  fi

  #
  ### 'cd' helpers
  #
  # Change directory to the given link's target, either the file's parent or the directory itself.
  cd-ln() {
    local link="$1"; shift 1
    [[ -z "$link" ]] && echo-error "usage: cd-ln link_to_dir | link_to_file" && return 1
    [[ ! -e "$link" ]] && echo-error "cd-ln: $link: no such symlink" && return 1
    [[ ! -L "$link" ]] && echo-error "cd-ln: $link: not a symlink" && return 1
    local target="$(readlink "$link")"
    qeval cd "$link"
    if [[ -d "$target" ]]; then
        qeval cd "$target"
    else
        qeval cd "$(dirname "$target")"
    fi
  }

  #
  ### 'chmod' helpers
  #
  # Make specified, or all in PWD, shell scripts executable.
  chx() {
    local _VERBOSE=$((_VERBOSE))
    matches "$1" '^(-v|--verbose)$' && shift && _VERBOSE=1
    
    local files=($@)
    [[ ! "$1" ]] && files=(*.sh) && _VERBOSE=1

    ((_VERBOSE)) && _VERBOSE="-vv" || _VERBOSE=
    qeval chmod $_VERBOSE +x "${files[@]}"
  }

  #
  ### 'find' helpers
  #
  # -L = follow symlinks
  # -E = use extended (modern) regexes
  # alias nfind='qeval find -L -E . -name'
  alias pfind='qeval find -L -E . -path'
  alias rfind='qeval find -L -E . -regex'
  nfind() {
    local usage="usage: nfind [path ...] glob_pattern [find_expr ...]"
    [[ -z "$1" ]] && echo-error "$usage" && return 1
    local paths=
    while [[ -e "$1" ]]; do
      paths="$paths $1"; shift
    done
    [[ -z "$paths" ]] && paths="."
    qeval find -L -E $paths -name $@
  }

  #
  ### 'history' helpers
  #
  history-grep() {
    local USAGE='Usage: history-grep [--dates] [--num-lines lines] [--unique] [pattern]'
    local opt_dates=0 opt_num_lines=0 opt_unique=0 pattern='.*'
    while [[ -n "$1" ]]; do case "$1" in
      -d|--date*)     opt_dates=1; shift;;
      -n|--num-lines) opt_num_lines=$2; shift 2;;
      -u|--unique)    opt_unique=1; shift;;
      *)              pattern="$@";;
    esac; done
    [[ -z "$opt_num_lines" ]] && eprintf "history-grep: option requires a numeric argument: --num-lines\n$USAGE\n"
    local htf=; ((opt_dates)) && htf="$HISTTIMEFORMAT"
    
    local c="HISTTIMEFORMAT='$htf' history"
    ((opt_unique)) 
    [[ -n $@ ]] && c="c | egrep $@"
    ((opt_num_lines > 0)) && c="$c $opt_num_lines"
    qeval "$c | less"
  }
  alias hg='qeval history-grep'

  #
  ### 'less' helpers:
  # 
  alias l='less'
  #
  # Lines will NOT wrap, but CTRL-C, arrow keys can scroll left and right. Press 'F' to resume "tailing".
  alias less-trunc='qeval less --chop-long-lines +F'


  #
  ### 'ls' helpers
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
  alias l1='qeval ls -1F'
  alias l1r='qeval l1 -r'
  #
  alias ll='ls -oghF'
  alias llt='qeval ll -t'
  alias lltr='qeval ll -tr'
  alias lls='qeval ll -S'
  alias llsr='qeval ll -Sr'
  #
  alias la='ls -alhF'
  alias lA='ls -AlhF'
  alias lat='qeval la -t'
  alias latr='qeval la -tr'
  alias las='qeval la -S'
  alias lasr='qeval la -Sr'
  #
  alias lld='qeval ll -d'
  alias l1d='qeval l1 -d'
  alias lad='qeval la -d'
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
  alias lan='lln -A'
  #
  # Display permissions in octal, from: http://askubuntu.com/a/152005
  # I've tried to figure out how this works but have no fucking clue.
  lso() {
    ls -ohF $@ \
    | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}' \
    | sed -E -e "s:\\$HOME:\\~:g"
  }

  #
  ### 'nc' helpers:
  # 
  ncz() {
    [[ -z "$1" ]] && echo-error "Usage: ncz [host] port" && return 1
    local host= port=
    if [[ -n "$2" ]]; then
      host=$1
      port=$2
      shift 2
    else
      host=localhost
      port=$1
      shift 1
    fi
    
    veval nc -z $host $port $@
    
    local ret=$?
    if (( ! _QUIET )); then
      (( ret == 0 )) && echo "Active" || echo "Inactive"
    fi
    return $ret
  }

  #
  ### 'ps/pgrep' helpers
  #
  # Tidy way to pgrep but (1) include header, (2) exclude the egrep itself.
  # ps options:
  #   -A  display all processes (same as -e)
  #   -m  sort by mem usage (instead of pid)
  #   -r  sort by cpu usage (instead of pid)
  #   -o  specify output fields:
  #         user -    username (18c wide so we cut it down to 12)
  #         pid
  #         ppid
  #         start
  #         time
  #         %cpu
  #         %mem
  #         command - very long, so we limit line length to window size
  ps-grep() {
    local USAGE='Usage: ps-grep [--long] [patt...]'
    local opt_long=; matches "$1" '-l|--long' && opt_long=1 && shift 1

    local ps_cmd="ps -e -o user,pid,ppid,start,time"
    ((opt_long)) && ps_cmd="${ps_cmd},%cpu,%mem,command" || ps_cmd="${ps_cmd},comm"
    if [[ -n "$1" ]]; then
      ps_cmd="$ps_cmd | egrep -e 'USER\s+PID\s+PPID'"
      while [[ -n "$1" ]]; do
        ps_cmd="$ps_cmd -e '$1'" && shift 1
      done
    fi
    # ! ((opt_long)) && ps_cmd="$ps_cmd | awk '{printf(\"%-10s %5s %5s %5s %s\n\", \$1,\$2,\$3,\$4,\$8)}'"
    # ps_cmd="$ps_cmd | egrep -v -e '$$ .+ egrep -e USER'"
    ps_cmd="$ps_cmd | egrep -v -e ' egrep '"
    ps_cmd="$ps_cmd | head -n 15"
    qeval "$ps_cmd"
  }
  ps-java() {
    veval "ps-grep -l java | sed -E -n '/^USER/p; /^[[:alnum:]]+ +([[:digit:]]+ +){2}/ s/^([[:alnum:]]+ +([[:digit:]]+ +){2}([^[:space:]]+ +){4}([^[:space:]]+) +).*( ([a-z]+\.)+[A-Z][^.]+.*)$/\1 - \5/p;'" \
      | sed -E 's:\/Library\/Java\/JavaVirtualMachines\/::'
    # qeval "ps-grep -l java | sed -E -n '/^USER/p; /^[[:alnum:]]+ +([[:digit:]]+ +){2}/ s/^([[:alnum:]]+ +(?:[[:digit:]]+ +){2} +(?:[^[:space:]]+ +){4} +([^[:space:]]+) +).+$/\1/; p;'" # + \d+ +\d+/p;' #' +\w+ +\w+ +\w+ +'
    # qeval "ps-grep -l java | sed -E -n 's/^(USER.+)|([[:alnum:]]+ +([[:digit:]]+ +){2} +([[:digit:]]+ +){5} +.+)$/\2/; p;'" # + \d+ +\d+/p;' #' +\w+ +\w+ +\w+ +'
  }
  ps-java-pid-class() {
    [[ -z "$1" ]] && echo-error "Usage: ps-java-pid-class PID" && return 1
     qeval "ps -p $1 | sed -E -n -e 's/.+ ([a-z]+\.)+([A-Z][A-Za-z]+).*/\2/p'"
  }
  #
  # Show active port info: command, pid, ports
  # lsof:
  # -b    avoid blocking kernel functions
  # +cn   COMMAND column width
  # -i4   IPv4 only
  # -n    use host numeric addresses, not names
  # -P    use port numbers, not names
  # -w    suppress warning messages
  ps-ports-1() {
    qeval lsof -b +c 16 -i TCP -n -P -w $@
  }
  ps-ports-2() {
    ps-ports-1 $@ \
    | qeval egrep '^(java|idea) '
  }
  ps-ports-3() {
    ps-ports-2 $@ \
    | qeval egrep '^COMMAND|TCP.+:[0-9]{2,5} '
  }
  ps-ports-4() {
    ps-ports-3 $@ \
    | qeval egrep ' \((LISTEN|ESTABLISHED)\)$'
  }
  ps-ports-5() {
    ps-ports-4 $@ \
    | awk '{printf("%s %05d %s\n", $1, $2, $9);}'
    # | awk '{split($9,hostport,":"); printf("%s %s\n", $2, hostport[2]);}'
  }
  ps-ports() {
    ps-ports-5 $@ \
    | sort -k2 -k3
  }
  ps-ports-java-class() {
    printf "%-16s  %5d  %s\n" "COMMAND" "PID" "PORTS"
    ps-ports $@ \
    | while read cmd pid ports; do
      class="$(ps-java-pid-class $pid)"
      printf "%-16s %5d %-16s %s\n" "$cmd" "$pid" "$class" "$ports"
    done
  }

  ### 'rm' helpers
  #
  # Delete the target of a symlink, then the symlink.
  rm-ln() {
    local cmd="rm"
    while [[ "$1" =~ ^- ]]; do cmd="$cmd $1" && shift; done

    local link="$1" && shift
    [[ -z "$link" ]] && echo-error "usage: rmln [rm opts] symlink" && return 1
    [[ ! -L "$link" ]] && echo-error "rmln: $link: no such symlink" && return 1

    local dest="$(readlink "$link")"
    [[ ! -e "$dest" ]] && echo-error "rmln: $link -> $dest: no such file or directory" && return 1
    qeval $cmd '$dest'
  }

  #
  ### 'tail' helpers
  #
  alias t='tail'
  alias tf='tail -f'

  #
  ### terminal helpers
  #
  # toggle wrap/truncate
  alias term-wrap='qeval tput smam'
  alias term-trunc='qeval tput rmam'
  #
  # colored text, from https://www.shellhacks.com/bash-colors/
  echo-color() {
    local USAGE="Usage: echo-color [-n] black|red|green|brown|blue|purple|cyan|light-gray TEXT [...]"
    local opt_no_crlf=; [[ "$1" == "-n" ]] && opt_no_crlf='-n' && shift 1
    [[ -z "$2" ]] && echo-error "$USAGE" && return 1

    local color="$(lower $1)"; shift 1
    case "$color" in
      reset)  code=0;;
      black)  code=30;;
      red)    code=31;;
      green)  code=32;;
      brown)  code=33;;
      blue)   code=34;;
      purple) code=35;;
      cyan)   code=36;;
      gray)   code=37;;
      *) echo-error "echo-color: invalid color: $color"; return 1;
    esac
    echo -e $opt_no_crlf "\e[${code}m$@\e[0m"
  }

  #
  ### 'touch' helpers
  #
  # Update mtime of folders with latest mtime of its contents
  touchd() {
    [[ -z "$1" ]] && echo-error "usage: touchd dir [...]" && return 1
    local count=0 arg
    for arg in $@; do
        
        local dir="$arg"
        local dir_tilde="${dir/$HOME/~}"
        [[ ! -e "$dir" ]] && echo-error "touchd: $dir_tilde: no such directory" && return 1
        [[ ! -d "$dir" ]] && vecho "touchd: $dir_tilde: not a directory" && continue

        local newest="$(ls -A1t "$dir/" | head -n 1)"
        [[ -z "$newest" ]] && vecho "touchd: empty directory: $dir_tilde" && continue

        local dir_time="$(stat -f %Sm "$dir")"; [[ -z "$dir_time" ]] && return 1
        local newest_time="$(stat -f %Sm "$dir/$newest")"; [[ -z "$newest_time" ]] && return 1
        [[ "$dir_time" == "$newest_time" ]] && vecho "touchd: $dir_tilde: mtime already matches $newest: $newest_time" && continue
        echo "touchd: updating mtime of '$dir_tilde' ($dir_time) to match '$newest': $newest_time"

        # touch -h will update link's target instead of link
        qeval touch -r "$dir/$newest" "$dir"
        [[ -L "$dir" ]] && qeval touch -h -r "$dir/$newest" "$dir"
        
        ((count++))
    done
    ((!count)) && return 1
    vecho "touchd: updated $count directories"
  }
  #
  touchd-R() {
    local dirs=($@)
    [[ ${#dirs[@]} == 0 ]] && dirs=("$PWD")
    for dir in "${dirs[@]}"; do
        find "$dir" -depth ! -type f -print |\
        while read -r subdir; do
            qeval touchd "$subdir"
        done
        qeval touchd "$dir"
    done
  }


  #
  # glob/symlink helpers
  #
  glob-path-count() {
      [[ -z "$1" ]] && echo-error "usage: glob-path-count patt [...]" && return 1
      ls -1d $@ 2> /dev/null | wc -l
  }
  # Convenience version of [[ -e "file*" [&& ...] ]] since test won't take wildcards/globs.
  glob-path-exists() {
      [[ -z "$1" ]] && echo-error "usage: glob-path-exists patt" && return 1
      ls -1d $1 >& /dev/null
  }
  # First matching path for given pattern
  glob-path-first() {
      [[ -z "$1" ]] && echo-error "usage: glob-path-first patt" && return 1

      local save_clicolor_force=${CLICOLOR_FORCE}
      unset CLICOLOR_FORCE

      if local paths="$(ls -1d $1 2> /dev/null)"; then
        head -n 1 <<< "$paths"
        export CLICOLOR_FORCE=$save_clicolor_force
        return 0
      else
        export CLICOLOR_FORCE=$save_clicolor_force
        return 1
      fi
  }

  #
  ### symlink/ln helpers
  #
  ln-valid() {
    local USAGE="Usage: ln-valid [FILE ...]; default is *"
    
    local _QUIET= _VERBOSE=
    while [[ "$1" =~ ^-.+ ]]; do case "$1" in
      -q|--quiet)    _QUIET=1; _VERBOSE=; shift 1;;
      -v|--verbose)  _VERBOSE=1; _QUIET=; shift 1;;
      *) echo-error "$USAGE" && return 1
    esac; done
    
    local files="${@:-*}"
    local ret=0
    for link in $files; do
      local target=
      local status="OK"
      if [[ ! -L "$link" ]]; then
        ! ((_VERBOSE)) && continue
        status="NON-LINK"
      else
        target="$(readlink "$link")"
        [[ ! -e "$target" ]] && status="INVALID"
      fi
      local line="$(printf '%-9s %s -> %s\n' $status $link $target)"
      if [[ "$status" == "OK" ]]; then
        qecho "$line"
      elif [[ "$status" == "NON-LINK" ]]; then
        echo-color blue "$line"
      else
        ret=1
        echo-color red "$line"
      fi
    done
    return $ret
  }


  .bash_profile_sets() {
    .tick-zprofile -e 'printf "[start] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'

    # Usage: 'set -o name' enables "name" and 'set +o name' disables it. 
    # Some have a single letter equivalent following the same pattern.
    # The list below shows letter and name.
    #
    # Default enabled shell options/variables:
    #   $SHELLOPTS = braceexpand:emacs:hashall:histexpand:history:interactive-comments:monitor
    #   $- = himBH
    
    # toggled from defaults:
    set    +o emacs
    set    -o ignoreeof   # ctrl-d won't close session
    set    -o vi          # vi-style line editing

    # set -B -o braceexpand
    # set +e +o errexit
    # set +E +o errtrace
    # set +T +o functrace
    # set -h -o hashall     # remember command location in history
    # set -H -o histexpand  # !-style history substitution
    # set    -o history
    # set    -o interactive-comments
    # set -m -o monitor     # job control enabled
    # set +C +o noclobber   # "noclobber"--files cannot be overwritten by redirection
    # set +n +o noexec      # read commands but don't execute
    # set +u +o nounset     # treat unset variable substitution as error
    # set +t +o onecmd      # exit after executing one command
    # set +v +o verbose     # print shell lines as they are read
    # set +x +o xtrace      # print commands and args as they are executed
    # set -i                # indicates shell is interactive; read-only

    .tick-zprofile -e 'printf "[end] .bash_profile_sets (%s, %s)\n" $- $SHELLOPTS'
  }
  # .bash_profile_sets

  .bash_profile_shopts() {
    .tick-zprofile -e 'printf "[start] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
    
    # Usage: 'shopt -s optname' enables (SETS) the option; -u (UNSET) disables it.
    # Default enabled options: cdspell:checkwinsize:cmdhist:expand_aliases:extglob:
    #                          extquote:force_fignore:histappend:hostcomplete:interactive_comments:
    #                          login_shell:progcomp:promptvars:sourcepath
    # See: https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html

    # toggled from defaults:
    shopt -u cdable_vars            # if cd's arg is not a directory, try it as a variable
    shopt -s checkhash              # check hash table before a normal path search
    shopt -s dotglob                # include files starting with . in glob expansion
    
    # shopt -s cdspell                # automatically fix minor typos in dir names
    # shopt -s checkwinsize           # update LINES and COLUMNS after external commands
    # shopt -s cmdhist                # save multi line commands as one history entry
    # shopt -s expand_aliases         # in a non-interactive shell, expand aliases 
    # shopt -s extglob                # use extended pattern matching (https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html)
    # shopt -s extquote               # $'string' and $"string" quoting is performed within ${parameter} expansions
    # shopt -s force_fignore          # even if FIGNORE words are only options, ignore them
    # shopt -s histappend             # history list is appended when shell exits, not overwritten
    # shopt -s hostcomplete
    # shopt -s interactive_comments   
    # shopt -s login_shell            # indicates shell is interactive; read-only
    # shopt -s progcomp               # programmable completion enabled [on by default]
    # shopt -s promptvars             # prompt strings undergo param expansion, etc. [on by default]
    # shopt -s sourcepath             # . uses PATH to find file [on by default]

    # shopt -u compat31               # see https://www.gnu.org/software/bash/manual/html_node/Shell-Compatibility-Mode.html
    # shopt -u execfail               # a non-interactive shell will not exit if it cannot execute the file given to 'exec'; interactive shells do not exist in this case
    # shopt -u extdebug
    # shopt -u failglob               # patterns matching 0 files result in error
    # shopt -u gnu_errfmt
    # shopt -u histreedit
    # shopt -u histverify
    # shopt -u huponexit              # send SIGHUP to all jobs when shell exits
    # shopt -u lithist                # delimit multi-line commands with \n in history
    # shopt -u mailwarn
    # shopt -u no_empty_cmd_completion
    # shopt -u nocaseglob             # case-insensitive matching during globbing
    # shopt -u nocasematch            # case-insensitive case and [[ commands
    # shopt -u nullglob               # matchless patterns expand to null string, not the pattern
    # shopt -u restricted_shell       # indicates shell is restricted; read-only 
    # shopt -u shift_verbose          # shifting too far results in an error
    # shopt -u xpg_echo               # expand backslash-escape sequences

    .tick-zprofile -e 'printf "[end] .bash_profile_shopts (%s, %s)\n" $- $(shopt -s | cut -f1 | join-lines ':')'
  }
  # .bash_profile_shopts


  #
  ###  HOMEBREW
  #
  .setup-homebrew() {
    .tick-zprofile '[start] .setup-homebrew'
    if [[ ! -x /usr/local/bin/brew ]]; then
      .tick-zprofile "... homebrew not installed"
      .tick-zprofile "... execute: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      return 1
    fi

    ((_DEBUG)) && .tick-zprofile "... PATH before 'brew shellenv': [$PATH]"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
    ((_DEBUG)) && .tick-zprofile "... PATH after  'brew shellenv': [$PATH]"
    if [[ ! -d "$HOMEBREW_PREFIX" ]]; then
      .tick-zprofile "... homebrew 'shellenv' did not properly set \$HOMEBREW_PREFIX"
      return 1
    fi
    # Let path-prepend de-dupe the /usr/local/... paths.
    path-prepend PATH /usr/local/sbin
    path-prepend PATH /usr/local/bin
    .tick-zprofile "... \$HOMEBREW_PREFIX=$HOMEBREW_PREFIX"

    alias bs='qeval brew services'
    
    _QUIET=1 safe-source /usr/local/etc/bash_completion.d/brew && .tick-zprofile '... loaded brew completion' || .tick-zprofile '!!! failed to load brew completion'

    local gnu_getopt_home="$HOMEBREW_PREFIX/opt/gnu-getopt"
    if [[ -e "$gnu_getopt_home" ]]; then
      path-prepend PATH "$gnu_getopt_home/bin"
      .tick-zprofile "... prepended $gnu_getopt_home/bin to PATH"
    fi

    local openssl_home="$HOMEBREW_PREFIX/opt/openssl@1.1"
    if [[ -e "$openssl_home" ]]; then
      path-prepend PATH "$openssl_home/bin"
      .tick-zprofile "... prepended $openssl_home/bin to PATH"
    fi

    .tick-zprofile "[end] .setup-homebrew, PATH=$PATH"
  }
  ! ((_SKIP_HOMEBREW_SETUP)) && .setup-homebrew


  #
  ###  ITERM window/tab titles
  #
  .setup-iterm() {
    .tick-zprofile '[start] .setup-iterm'
    [[ "$TERM_PROGRAM" != "iTerm.app" ]] && .tick-zprofile "... iTerm2 not installed" && return 1

    if [[ -e "$HOME/.iterm2_shell_integration.bash" ]]; then
      source "$HOME/.iterm2_shell_integration.bash"
      export ITERM_BADGE="$ITERM_PROFILE"
      iterm2_print_user_vars() {
        iterm2_set_user_var badge "$ITERM_BADGE"
      }
    fi

    # From https://superuser.com/a/344397/17666
    # Note that tab and window take effect imediately; badge needs to wait for a prompt display
    iterm-text() {
      local USAGE="usage: iterm-text ${ITERM_BADGE:+--badge|}--tab|--window TEXT..."
      local mode= do_tab= do_window= do_badge= obj="tab and window"
      while [[ "$1" ]]; do case "$1" in
        -t|--tab)   do_tab=1; shift 1;;
        -w|--win*)  do_window=1; shift 1;;
        -b|--badge) do_badge=1; shift 1;;
        -*) echo-error "iterm-text: illegal option -- $1"
            echo-error $USAGE
            return 1;;
        *) break;;
      esac; done
      [[ -z "$do_tab$do_window$do_badge" ]] && do_tab=1 do_window=1 do_badge=${+ITERM_BADGE}
      local text="$@"
      [[ -z "$text" ]] && echo-error "$USAGE" && return 1

      ((do_tab))    && echo -ne "\e]1;$text\a"    && echo-verbose "Updated iTerm tab title to: $text"
      ((do_window)) && echo -ne "\e]2;$text\a"    && echo-verbose "Updated iTerm window title to: $text"
      ((do_badge))  && export ITERM_BADGE="$text" && echo-verbose "Updating iTerm badge to: $text"
    }
    alias itt='iterm-text'

    .tick-zprofile "[end] .setup-iterm, ITERM_PROFILE=$ITERM_PROFILE"
  }
  ! ((_SKIP_ITERM_SETUP)) && .setup-iterm


  #
  ###  GIT
  #
  .setup-git() {
    .tick-zprofile '[start] .setup-git'
    ! is-defined git && .tick-zprofile "[end] .setup-git: git not installed" && return 0

    .tick-zprofile "... using $(git --version)"

    # usage: git-alias [--max-count n] [patt]
    git-alias() {
      local USAGE="usage: git-alias [[--max-count] n] [patt]"
      local opt_patt='.+' opt_maxcount=999
      local _quiet=$_QUIET _verbose=$_VERBOSE
      while [[ -n "$1" ]]; do case "$1" in
        -q | --quiet)     _quiet=1; shift;;
        -v | --verbose)   _verbose=1; shift;;
        -n | --max-count) shift 1; 
                          if [[ -n "$1" ]]; then
                            opt_maxcount=$1; 
                            shift;
                          else
                            echo-error "usage: $USAGE"
                            return 1;
                          fi;;
        *) break;;
      esac; done
      [[ "$1" =~ ^[0-9]$ ]] && opt_maxcount=$1 && shift
      opt_patt="$@"

      git config --get-regexp "^alias\.${opt_patt}" \
        | head -n $opt_maxcount \
        | sed -E 's/^alias\.([^ ]+) +(.*)/\1\t\2/;'
    }
    #
    git-branch() {
      local branch_level=1; while [[ "$1" =~ [012] ]]; do branch_level="$1" && shift 1; done
      git branch --show-current 1>/dev/null || return 1

      c_br_remote="$(git config --get-color color.branch.remote)"
      c_br_current="$(git config --get-color color.branch.current)"
      c_commit="$(git config --get-color color.diff.commit)"

      c_green="$(git config --get-color color.blame.repeatedlines)"
      c_blue="$(git config --get-color color.branch.upstream)"
      c_white="$(git config --get-color color.decorate.stash)"
      c_red="$(git config --get-color color.status.untracked)"
      c_reset='%(color:reset)'

      f_sha="%(if)%(HEAD)%(then)$c_br_current*%(else)$c_commit %(end)%(objectname:short)$c_reset"
      f_track="$c_red%(if)%(upstream:track)%(then)[%(upstream:track)]%(end)$c_reset"
      f_track_short="$c_red%(if)%(upstream)%(then)%(align:2,left)[%(upstream:trackshort)]%(end)%(end)$c_reset"
      f_date="$c_white%(align:14,left)%(committerdate:format:%F %T)%(end)$c_reset"
      f_date_relative="$c_white%(align:20,left)%(committerdate:relative)%(end)$c_reset"
      f_date_short="$c_white%(align:14,left)%(committerdate:format:%D %H:%M)%(end)$c_reset"
      f_authorname_20="%(align:20,left)%(authorname)%(end)"
      f_branch="%(if)%(HEAD)%(then)$c_br_current%(else)%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)$c_br_remote%(else)$c_reset%(end)%(end)%(refname:short)$c_reset"
      f_comment="%(contents:subject)"
      f_upstream="$c_blue%(if)%(upstream)%(then)   [%(upstream:short)]%(end)$c_reset"
      f_branch_and_track_short="%(align:60,left)$f_branch%(if)%(upstream)%(then) $c_red%(align:2,left)[%(upstream:trackshort)]%(end)%(else)$c_reset%(end)%(end)"

      case "$branch_level" in
        0)  veval git branch --list --ignore-case --sort='-committerdate' \
              --format="\"$f_sha $f_date_relative $f_branch $f_track_short\"" \
              $@ | less
            ;;
        1)  veval git branch --list --ignore-case --sort='-committerdate' --column=never \
              --format="\"$f_sha  $f_date_short  $f_authorname_20 $f_branch_and_track_short $f_upstream $f_comment\"" $@ \
              | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
              | less
            ;;
        2)  veval git branch --list --ignore-case --sort='-committerdate' --column=never \
              --format="\"$f_sha  $f_date  $f_authorname_20 $f_branch_and_track_short $f_upstream $f_comment $f_track \"" $@ \
              | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
              | less
            ;;
        *)  echo-error "git-branch: unexpected level: $branch_level"
            return 1
            ;;
      esac
    }
    alias gbr='qeval "git-branch | egrep -v \"[A-Z]+\.(feature|hotfix)|(feature|hotfix)\.[A-Z]+\""'
    alias gbra='qeval git-branch 1'
    alias gbran='qeval git-branch 2' gbranc='gbran' gbranch='gbran'
    #
    alias gbr-rm='qeval git brrm'
    alias gbr-mv='qeval git brmv'
    alias gbr-cp='qeval git brcp'
    #
    git-branch-bak() {
      [[ -z "$GIT_BRANCH" ]] && echo-error "No current branch" && return 1
      [[ -n "$1" ]] && mmdd="$1" || mmdd="$(date +'%m%d')"
      qeval git brcp \"$GIT_BRANCH\" \"XXX.${GIT_BRANCH}.$mmdd\"
    }
    alias gbr-bak='qeval git-branch-bak'
    #
    git-branch-set-upstream() {
      qeval git branch --set-upstream-to "origin/$GIT_BRANCH" $@
    }
    git-branch-set-upstream-to() {
      qeval git branch --set-upstream-to "${@:-origin/$GIT_BRANCH}"
    }
    git-branch-unset-upstream() {
      qeval git branch --unset-upstream "${@:-origin/$GIT_BRANCH}"
    }
    #
    git-branches-with() {
      local _QUIET=$! _quiet_on _VERBOSE=$((_VERBOSE))
      local log_opts=
      while [[ "$1" ]]; do case "$1" in
        -q|--quiet)   _QUIET=1 _VERBOSE=0; shift 1;;
        -v|--verbose) _QUIET=0 _VERBOSE=1; shift 1;;
        -n|--max-count) log_opts="$log_opts $1 $2"; shift 2;;
        -{1,2,3,4,5,6,7,8,9}*) log_opts="$log_opts -n $1"; shift 1;;
        *) break;;
      esac; done
      [[ -z "$1" ]] && echo-error "usage: git-branches-with [-q|-v|-d] [-n count] file_glob" && return 1
      local file_glob="$@"
      veval git -P log --all -n 10 --date="iso-strict" --format=\"'%h %cd %cN'\" --color=never $log_opts -- $file_glob \
        | while read commit_sha commit_dt committer; do
            echo-verbose "$commit_sha | $commit_dt | $committer"
            veval git -P branch --all --list --contains=$commit_sha --format="\"%(committerdate:format:%F %H:%M) | %(refname:short)\""
          done \
        | sort -r -s \
        | uniq
    }
    alias gbw='qeval git-branches-with'
    #
    alias gco='qeval git checkout'
    alias gcod='qeval git checkout develop'
    alias gcom='qeval git checkout master'
    #
    git-checkout-remote-branch() {
      [[ -z "$1" ]] && echo-error "usage: git-checkout-remote-branch remote/branch_name" && return 1
      [[ ! "$1" =~ .+/.+ ]] && echo-error "usage: git-checkout-remote-branch remote/branch_name" && return 1
      local remote_branch="$1" && shift
      local remote_name="$(substring_before_first $remote_branch '/')"
      local branch_name="$(substring_after_first $remote_branch '/')"
      echo-verbose "$(echo-glob remote_branch remote_name branch_name)"
      qeval git checkout -b $branch_name $remote_name/$branch_name || return 1
      qeval git branch --set-upstream-to $remote_name/$branch_name
    }
    #
    git-commit-message() {
      local opts=
      while [[ "$1" =~ ^--?[a-z] ]]; do
        opts="$opts $1"
        shift
      done
      [[ -z "$1" ]] && echo-error "usage: git-commit-message 'message'" && return 1
      qeval git commit --message \"$@\" || return 1
      qeval git diff --stat=$COLUMNS HEAD^ | grep -E -v '[0-9]+ (files? changed|insertions?|deletions?)'
    }
    alias gcm='qeval git-commit-message'
    #
    alias gds='qeval git ds'
    alias gdss='qeval git dss'
    alias gdds='qeval git dds'

  # LOG/PRETTY FORMAT FIELDS
  # %h  - abbrev hash
  # %C  - color or reset
  # %cn - committer name; %cN via .mailmap
  # %ce - committer email; %cE via .mailmap
  # %cl - committer email local part; %cL via .mailmap
  # %cd - commit date in --date's format
  # %cr - commit date (relative)
  # %D  - ref name(s)
  # %s  - subject line
    git-log() {
      local log_level=1; [[ "$1" =~ ^[0123]$ ]] && log_level="$1" && shift 1
      git branch --show-current 1>/dev/null || return 1

      local hash_len=7

      c_reset='%C(reset)'
      c_commit="%C(yellow)"
      c_tag="%C(bold cyan)"
      c_white="%C(white)"

      f_hash="%<($hash_len)${c_commit}%h"
      f_author_name_mailmap="${c_reset}%<(18)%aN"
      f_author_name_mailmap_long="${c_reset}%<(22)%aN"
      f_author_name="${c_reset}%<(20)%an"
      f_commit_date_rel="${c_white}%<(12)%cr"
      f_commit_date_short="${c_white}%<(8)%cd"
      f_commit_date="${c_white}%cd"
      f_tags="${c_tag}%d"
      f_tags_short="${c_tag}%D"
      f_subject_line="${c_reset}%s"
      f_subject_line_white="${c_white}%s"
      f_body="${c_reset}%b"

      case "$log_level" in
        0)  hash_len=6
            veval git log -20 --abbrev=$hash_len --decorate=short --date='format:%D' \
              --format="\"$f_hash  $f_author_name_mailmap $f_commit_date_short $f_tags_short $f_subject_line$c_reset\"" $@ \
              | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
              | sed -E \
                -e 's/origin/$O/g' \
                -e 's/tag: ?/$T:/g' \
                -e 's/ -> /->/g' \
              | less
                # -e "s/$(git config --get user.name)/\$ME/g" \
              ;;
        1)  veval git log -20 --abbrev=$hash_len --date=human --use-mailmap \
              --format="\"$f_hash  $f_author_name_mailmap_long $f_commit_date_rel $f_tags $f_subject_line$c_reset\"" $@ \
              | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
              | sed -E \
                -e 's/origin/$O/g' \
                -e 's/tag: ?/$T:/g' \
                -e 's/ -> /->/g' \
              | less
              ;;
        2) veval git log -20 --abbrev=$hash_len --date=human --use-mailmap \
              --format="\"$f_hash  $f_author_name_mailmap_long  $f_commit_date_short $f_commit_date_rel $f_tags%n  $f_subject_line$c_reset\"" $@ \
              | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
              | sed -E \
                -e 's/origin/$O/g' \
                -e 's/tag: ?/$T:/g' \
                -e 's/ -> /->/g' \
              | less
            ;;
        3) veval git log -20 --abbrev=$hash_len --date=human --no-use-mailmap --stat \
              --format="\"$f_hash  $f_author_name_mailmap_long  $f_commit_date  $f_commit_date_rel$f_tags%n  $f_subject_line_white%n  $f_body$c_reset\"" $@ \
              | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
              | sed -E \
                -e 's/origin/$O/g' \
                -e 's/tag: ?/$T:/g' \
                -e 's/ -> /->/g' \
              | less
            ;;
        *)  echo-error "git-log: unexpected level: $log_level"
            return 1
            ;;
      esac
    }
    alias glo='qeval git-log'
    alias glog='qeval git-log 1'
    alias glogg='qeval git-log 2'
    alias gloggg='qeval git-log 3'

    git-log-me() {
      git-log $@ -999 | grep "'$(git config --get user.name)'"
    }
    alias glme='qeval git-log-me'
    #
    # cd into each given directory and perform a git pull --ff-only
    # usage: git-pulld [dir ...]
    git-pulld() {
      local dirs="$@"
      [[ -z "$dirs" ]] && dirs="$(find . -maxdepth 1 -type d)"

      local f1=1
      for d in $dirs; do
        ((f1)) && f1= || printf '\n'
        [[ ! -e "$d" ]] && echo-error "g-pulld: folder does not exist; aborting" && return 1
        [[ ! -e "$d/.git" ]] && echo-error "g-pulld: folder is not a git repo; bypassing $d" && continue
        cd "$d"
        printf '== %s %s\n' "$d" "$(git branch --show-current)"
        qeval git pull --ff-only
        cd ..
      done
    }
    #
    alias gpff='qeval git pff'
    #
    alias gr-dev='qeval git rebase develop'
    alias gr-mas='qeval git rebase master'
    alias gr-ab='qeval git rebase --abort'
    #
    alias gs='git stash'
    alias gsh='qeval git stash -h'
    alias gsl='qeval git stash list' 
    alias gsld='qeval git stash list --date=short' 
    alias gsa='qeval git stash apply' 
    alias gss='qeval git stash show'
    #
    git-stash-diff() {
      local index=0; [[ -n "$1" ]] && index=$1 && shift
      local index2=; [[ "$1" =~ ^[[:digit:]]+$ ]] && index2=$1 && shift
      local rev="stash@{$index}"
      local rev2=; [[ -n "$index2" ]] && rev2="stash@{$index2}"
      qeval git diff $rev $rev2 $@
    }
    git-stash-diff-stat() {
      local index=0; [[ -n "$1" ]] && index=$1 && shift
      local index2=; [[ "$1" =~ ^[[:digit:]]+$ ]] && index2=$1 && shift
      local rev="stash@{$index}"
      local rev2=; [[ -n "$index2" ]] && rev2="stash@{$index2}"
      qeval git diff --stat $rev $rev2 $@
    }
    alias gsd=git-stash-diff
    alias gsds=git-stash-diff-stat
    #
    git-status() {
      local status_level=1; [[ -n "$1" ]] && status_level="$1" && shift 1
      [[ ! "$status_level" =~ [0123] ]] && echo-error "usage: g-status [1|2|3]" && return 1
      git branch --show-current 1>/dev/null || return 1

      c_remote_branch="$(git config --get-color color.status.remotebranch)"
      c_stash="$(git config --get-color color.decorate.stash)"
      c_reset="$(git config --get-color '' reset)"
      
      case "$status_level" in

        0)  veval git -c advice.statusHints=false status --short $@ \
            | grep -E -v '^\#?\s*$' \
            | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;"
            ;;
        1)  veval git -c advice.statusHints=false status --column=dense --no-show-stash $@ \
            | grep -E -v '^\#?\s*$' \
            | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;"
            ;;
        2)  echo "#"
            veval git -c advice.statusHints=false status --column=nodense --show-stash $@ \
            | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;" \
            | sed -E -e "s/(Your stash.+has [[:digit:]]+ entr(ies|y))/${c_stash}\\1${c_reset}/;"
            ;;
        3)  echo "#"
            veval git -c advice.statusHints=false status --column=nodense --show-stash --ignored=traditional --verbose $@ \
            | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;" \
            | sed -E -e "s/(Your stash.+has [[:digit:]]+ entr(ies|y))/${c_stash}\\1${c_reset}/;"
            ;;
        *)  echo-error "git-status: unexpected level: $status_level"
            return 1
            ;;
      esac
    }
    alias gst='qeval git-status'
    alias gsta='qeval git-status 1'
    alias gstat='qeval git-status 2'
    alias gstatu='qeval git-status 3' gstatus='gstatu'

    # update local mtime based on git log
    # from: https://stackoverflow.com/a/2038768/160955
    git-touch() {
      [[ -z "$1" ]] && echo-error "usage: git-touch file [...]" && return 1
      while [[ -n "$1" ]]; do
        local f="$1"; shift
        local rev="$(git rev-list -n 1 "HEAD" "$f")"
        local commit_sec="$(git show --pretty=format:%at --abbrev-commit "$rev" | head -n 1)"
        local commit_ts="$(date -r $commit_sec '+%Y%m%d%H%M.%S')"
        qprintf 'before: ' && ls -oghF "$f"
        qeval touch -h -t "$commit_ts" "$f"
        qprintf 'after:  ' && ls -oghF "$f"
      done      
    }

    .tick-zprofile '... checking for git-flow'
    if is-defined git-flow; then
      # https://github.com/aleksandr-m/gitflow-maven-plugin

      .tick-zprofile "... checking for ~/.git-flow-completion"
      _QUIET=1 safe-source ~/.git-flow-completion
      complete -p | grep -E -q 'git-flow$' && .tick-zprofile "... loaded git-flow cli completion" || .tick-zprofile "... not using git-flow completion"

      # Usage: gf-feature-start featureName [mvn_opts] [gitflow_opts]
      gf-feature-start() {
        local gitbr="$(git branch --show-current 2> /dev/null)"
        [[ -z "$gitbr" ]] && echo-error "gf-feature-start: not in a git repository" && return 1
        local featureName="${1#*feature/}"; shift  # everything after "feature/", else entire string
        local mvn_opts="$1"; shift
        local gitflow_opts="$1"; shift
        qeval mvn --batch-mode "$mvn_opts" gitflow:feature-start -Dverbose=true -DfeatureName="$featureName" -DpushRemote=true "$gitflow_opts"
      }
    
      # Usage (from feature branch): gf-feature-finish -m [mvn_opts] -g [gitflow_opts]
      gf-feature-finish() {
        local gitbr="$(git branch --show-current 2> /dev/null)"
        [[ -z "$gitbr" ]] && echo-error "gf-feature-finish: not in a git repository" && return 1
        local featureName="${gitbr#*feature/}"
        local mvn_opts="$1"; shift
        local gitflow_opts="$1"; shift
        qeval mvn --batch-mode "$mvn_opts" gitflow:feature-finish -Dverbose=true -DkeepBranch=true -DfeatureName="$featureName" -DfeatureSquash=true -DincrementVersionAtFinish=true "$gitflow_opts"
      }
    fi
      
    .setup-git-prompt() {
      .tick-zprofile "[start] .setup-git-prompt, PS1=[$PS1]"

      # export GIT_PROMPT_ONLY_IN_REPO=
      # export GIT_PROMPT_SHOW_UPSTREAM=1
      # export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal # can be no, normal or all
      # export GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=1
      
      .tick-zprofile "[end] .setup-git-prompt, PS1=[$PS1]"
    }
    .setup-git-prompt 

    .tick-zprofile '[end] .setup-git'
  }
  ! ((_SKIP_GIT_SETUP)) && .setup-git


  #
  ### SDKMAN/JAVA
  #
  .setup-java-sdkman() {
    .tick-zprofile '[start] .setup-java-sdkman'
    if [[ ! -e "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
      .tick-zprofile "[end] .setup-java-sdkman, SDKMAN not installed"
      return 1
    fi

    export SDKMAN_DIR="$HOME/.sdkman"

    if [[ "$(type -t sdk)" == "function" ]]; then
      .tick-zprofile 'sdkman already initialized'
    else
      .tick-zprofile '... initializing sdkman'
      . "$SDKMAN_DIR/bin/sdkman-init.sh"
      path-prepend "$SDKMAN_DIR/bin"
      .tick-zprofile "... initialized sdkman"
    fi
    # .tick-zprofile -e 'echo "... using $(sdkman version)"'
    # .tick-zprofile -e 'echo "... $ which javac: $(2>&1 which javac)"'
    # .tick-zprofile -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
    
    if [[ -z "$JAVA_HOME" ]]; then
      .tick-zprofile "sdkman left a blank JAVA_HOME"
    elif [[ ! -d "$JAVA_HOME" ]]; then
      .tick-zprofile "sdkman left a non-directory JAVA_HOME: $JAVA_HOME"
    elif [[ ! -d "$JAVA_HOME/bin" ]]; then
      .tick-zprofile "sdkman non-directory JAVA_HOME/bin: $JAVA_HOME/bin"
    fi

    sdk-ls() {
      sdk ls java '$@' | head -n 5
      sdk ls java '$@' | egrep '>>>| installed | local only '
    }

    .tick-zprofile -e tilde-compress "[end] .setup-java-sdkman, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
  }
  ! ((_SKIP_SDKMAN_SETUP)) && .setup-java-sdkman


  #
  ### JENV/JAVA
  #
  .setup-java-jenv() {
    .tick-zprofile '[start] .setup-java-jenv'
    ! is-defined jenv && .tick-zprofile "[end] .setup-java-jenv, jenv not installed" && return 1

    if [[ "$(type -t jenv)" == "function" ]]; then
      .tick-zprofile 'jenv already initialized'
    else
      .tick-zprofile '... initializing jenv'
      eval "$(jenv init --no-rehash -)"
      path-prepend "$HOME/.jenv/bin"
      .tick-zprofile "... initialized jenv"
    fi
    # .tick-zprofile -e 'echo "... using $(jenv --version)"'
    # .tick-zprofile -e 'echo "... using java $(jenv version)"'
    # .tick-zprofile -e 'echo "... $ which javac: $(2>&1 which javac)"'
    # .tick-zprofile -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
    
    local javahome="$(jenv javahome)"
    if [[ -z "$javahome" ]]; then
      .tick-zprofile "jenv reports a blank JAVA_HOME"
    elif [[ ! -d "$javahome" ]]; then
      .tick-zprofile "jenv reports a non-directory JAVA_HOME: $javahome"
    elif [[ ! -d "$javahome/bin" ]]; then
      .tick-zprofile "jenv non-directory JAVA_HOME/bin: $javahome/bin"
    else
      export JAVA_HOME="$javahome"
    fi

    .tick-zprofile -e tilde-compress "[end] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
  }
  ! ((_SKIP_SETUP_JENV)) && ! is-defined sdk && .setup-java-jenv


  #
  ### POSTGRESQL
  #
  .setup-pg() {
    .tick-zprofile '[start] .setup-pg'
    export HOMEBREW_POSTGRESQL_SERVICE="$(readlink /usr/local/opt/postgresql)"
    if [[ -z "$HOMEBREW_POSTGRESQL_SERVICE" ]]; then
      .tick-zprofile '[end] .setup-pg, no /usr/local/opt/postgresql; pg not installed'
      return 1
    fi
    path-append '/usr/local/opt/postgresql/bin'
    alias pg-restart='qeval brew services restart $HOMEBREW_POSTGRESQL_SERVICE'
    alias pg-start='qeval brew services start $HOMEBREW_POSTGRESQL_SERVICE'
    alias pg-stop='qeval brew services stop $HOMEBREW_POSTGRESQL_SERVICE'
    .tick-zprofile '[end] .setup-pg, PATH=$PATH"'
  }
  ! ((_SKIP_POSTGRES_SETUP)) && .setup-pg


  #
  ### SCHEMASPY
  #
  .setup-schemaspy() {
    if [[ ! -e "$HOME/lib/schemaspy.jar" ]]; then
      .tick-zprofile "[end] .setup-schemaspy, schemaspy.jar not installed in ~/lib"
      return 1
    fi

    schemaspy() {
      local driver_path="$HOME/lib"
      local spy_output="schemaspy-out"
      while [[ "$1" =~ -[a-z] ]]; do case "$1" in
        -dp|--driver-path)    driver_path="$2"; shift 2;;
        -o|--outputDirectory) spy_output="$2"; shift 2;;
        *) break;;
      esac; done
      qeval java -jar "$HOME/lib/schemaspy.jar" \
        -cat '%' \
        -dp "$driver_path" \
        -o  "$spy_output" \
        -noviews -noimplied -nopages -maxdet 9999 \
        $@
    }
  }
  ! ((_SETUP_SCHEMASPY_DISABLED)) && .setup-schemaspy


  #
  ### VIRTUAL BOX general helpers
  #
  .setup-vbox() {
    ! is-defined VBoxManage && .tick-zprofile '[end] .setup-vbox, VirtualBox not installed' && return 1

    export VBOX_VMS_HOME="$HOME/VirtualBox VMs"
    export VBOX_VERSION="$(substring_before_last $(VBoxManage --version) '.')" # e.g., 6.1 or 7.1

    vb() { qeval VBoxManage $@; }
    #
    vb-list() {
      local _QUIET=$_QUIET _VERBOSE=$_VERBOSE _WHATIF=$_WHATIF
      local opt_hostonly opt_running
      local opts_are_general=1 general_opts
      while [[ "$1" ]]; do echo "arg: $1"; case "$1" in
        -q|--quiet)     _QUIET=1; shift 1;;
        -v|--verbose)   _VERBOSE=1; shift 1;;
        -h|--host*)     opt_hostonly=1; shift 1;;
        -r|--run*)      opt_running=1; shift 1;;

        --) opts_are_general=0; shift 1;;
        -*) if ((! opts_are_general)); then
              echo "((! opts_are_general))"
              break
            else
              general_opts="$general_opts $1"
              shift 1
              echo-var general_opts
            fi;;
        *) break;;
      esac; done
      local specific_opts="$@"
      echo-var opt_hostonly opt_running opts_are_general general_opts specific_opts
      if ((opt_hostonly)); then
        local hostonly="hostonlynets"; [[ "$VBOX_VERSION" =~ ^6 ]] && hostonly="hostonlyifs"
        qeval vb $general_opts list $specific_opts "$hostonly"
      else
        local obj="vms"; ((opt_running)) && obj="runningvms" && shift 1
        qeval vb $general_opts list --sorted $specific_opts "$obj"
      fi

    }
    alias vbls='qeval vb-list'
    #
    vb-status() {
      local USAGE="usage: vb-status [--all] [--long]"
      local all= long=
      while [[ "$1" ]]; do case "$1" in
        -a|--all)   all=1; shift 1;;
        -l|--long)  long=1; shift 1;;
        *) break;;
      esac; done

      ((all)) && printf "\nALL VMS\n" && vb-list
      
      printf "\nRUNNING VMS\n"
      vb-list --running

      if ((long)); then
        printf "\nRUNNING VMS --long\n"
        vb-list --running -- --long |\
          egrep '^(Name|Guest OS|UUID|Config file|Log folder|Memory size|State):\s{2,}'
      fi
    }
    alias vbst=vb-status

    # Lookup full vm name given a pattern; if not found, return pattern with error status.
    vb-vm-name() {
      [[ -z "$1" ]] && echo-error "usage: vb-vm-name patt" && return 1
      local patt="$1" && shift
      local save_clicolor_force=${CLICOLOR_FORCE}
      unset CLICOLOR_FORCE
      if ls -1A "$VBOX_VMS_HOME/" | egrep -i "$patt"; then
        export CLICOLOR_FORCE=$save_clicolor_force
        return 0
      else
         echo "$patt"
         export CLICOLOR_FORCE=$save_clicolor_force
         return 1
      fi
    }

    vb-start() {
      [[ -z "$1" ]] && echo-error "usage: vb-start vm_name [startvm options]" && return 1
      local vm_name="$1" && shift
      qeval VBoxManage startvm \"$vm_name\" --type headless $@
    }
    vb-controlvm() {
      [[ -z "$2" ]] && echo-error "usage: vb-controlvm vm_name_patt cmd [controlvm cmd options]" && return 1
      local vm_name_patt="$1" && shift
      local cmd="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      qeval VBoxManage controlvm \"$vm_name\" $cmd $@
    }
    vb-reboot() {
      [[ -z "$1" ]] && echo-error "usage: vb-reboot vm_name" && return 1
      local vm_name_patt="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      qeval vb-controlvm "$vm_name" reboot $@
    }
    vb-poweroff() {
      [[ -z "$1" ]] && echo-error "usage: vb-poweroff vm_name_patt [--type=gui|headless|..., other startvm options]" && return 1
      local vm_name_patt="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      gecho vm_name
      qeval vb-controlvm "$vm_name" poweroff $@
    }

    vb-less() {
      [[ -z "$1" ]] && echo-error "usage: vb-less vm_name ['less' options]" && return 1
      local vm_name_patt="$1" && shift
      local vm_name=$vm_name_patt #"$(vb-vm-name $vm_name_patt)"
      qeval less $@ \"$VBOX_VMS_HOME/$vm_name/Logs/VBox.log\"
    }
    vb-tail() {
      [[ -z "$1" ]] && echo-error "usage: vb-tail vm_name_patt [-f or other 'tail' options]" && return 1
      local vm_name_patt="$1" && shift
      qeval tail $@ \"$VBOX_VMS_HOME/$vm_name/Logs/VBox.log\"
    }
  }
  ! ((_SKIP_SETUP_VBOX)) && .setup-vbox


  #
  ### MAPR (client)
  #
  .setup-mapr() {
    .tick-zprofile '[start] .setup-mapr'
    [[ ! -e "/opt/mapr" ]] && .tick-zprofile '[end] .setup-mapr, no such directory: /opt/mapr' && return 1

    export MAPR_HOME="/opt/mapr"
    path-prepend PATH "$MAPR_HOME/bin"

    .tick-zprofile "[end] .setup-mapr, MAPR_HOME=$MAPR_HOME, PATH=$PATH"
  }
  ! ((_SKIP_SETUP_MAPR)) && .setup-mapr


  #
  ### HADOOP (client & server, not embedded in MapR)
  #
  .setup-hadoop() {
    .tick-zprofile '[start] .setup-hadoop'
    [[ ! -e "/opt/hadoop" ]] && .tick-zprofile '[end] .setup-hadoop, no such directory: /opt/mapr' && return 1

    export HADOOP_HOME="/opt/hadoop"
    path-prepend PATH "$HADOOP_HOME/sbin"
    path-prepend PATH "$HADOOP_HOME/bin"

    export HADOOP_LIBEXEC_DIR="$HADOOP_HOME/libexec"
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    export HADOOP_LOG_DIR="/var/log/hadoop"

    .tick-zprofile "[end] .setup-hadoop, HADOOP_HOME=$HADOOP_HOME, PATH=$PATH"
  }
  ! ((_SKIP_SETUP_HADOOP)) && .setup-hadoop


  #
  ### PWR-JUMPER
  #
  _QUIET=1 safe-source $HOME/.pwrfunc.sh


  #
  ### PS1 COMMAND LINE PROMPT
  #
  # - if unset, leave unset (non-interactive shell)
  # - if last command was in error, display "!" prefix before "$" and before line sep
  # - history -a explicitly flushes the session history to the history file
  # __git_ps1 shows the current git branch, if any, and is configured below
  # - \u = user, \h = hostname, \w = working dir
  #
  # .setup-ps1() {
  #   .tick-zprofile "[start] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"  #  PS1=[\h:\W \u\[\]\$\[\] ]
  #   [[ -z "$PS1" ]] && .tick-zprofile '[end] .setup-ps1: non-interactive shell' && return 0

  #   export PROMPT_COMMAND='.ps1-set-last-command-state;_prompt_command'

  #  ` # Hijack git prompt's saved status from prior command
  #   .ps1-set-last-command-state() {
  #     export GIT_PROMPT_LAST_COMMAND_STATE=$?
  #   }

  #   _prompt_command() {
  #     # .tick-zprofile "[start] _prompt_command: on entry, PROMPT_COMMAND=[$PROMPT_COMMAND], \$\?=$GIT_PROMPT_LAST_COMMAND_STATE, PS1=[$PS1]"

  #     history -a 

  #     local ps1_suffix='$'; ((GIT_PROMPT_LAST_COMMAND_STATE>0)) && ps1_suffix='!$'

  #     # if type -t kube_ps1 &>/dev/null && [[ "$KUBE_PS1_ENABLED" = on ]]; then
  #     #   _kube_ps1_update_cache
  #     #   local k_ps1_text="$(kube_ps1)"
  #     #   local len_k_ps1_text=${#k_ps1_text}
  #     #   ((len_k_ps1_text>0)) && k_ps1_text="$k_ps1_text\\n"
  #     `#   # .tick-zprofile "... k_ps1_text=[$k_ps1_text], len(k_ps1_text)=[$len_k_ps1_text]"
  #     # fi

  #     local g_ps1_text=
  #     if type -t setGitPrompt &>/dev/null; then
  #       export GIT_PROMPT_START=
  #       export GIT_PROMPT_END=
  #       export GIT_PROMPT_LEADING_SPACE=0
  #       setGitPrompt
  #       g_ps1_text="$PS1"
  #     fi
  #     g_ps1_text="$g_ps1_text\\n${LAST_COMMAND_INDICATOR}${ResetColor} $(tilde-compress \\w) $ps1_suffix "
  #     # .tick-zprofile "... g_ps1_text=[$g_ps1_text]"

  #     export PS1="$(printf '%s%s' "${k_ps1_text}" "${g_ps1_text}")"

  #     # .tick-zprofile "[end] _prompt_command: on exit, PS1=[$PS1]"
  #   }

  #   .tick-zprofile "[end] .setup-ps1, PROMPT_COMMAND=[$PROMPT_COMMAND], PS1=[$PS1]"
  # }
  # .setup-ps1

  .source-extra-start-files() {
    .tick-zprofile "[start] .source-extra-start-files ($1)"
    if glob-path-exists ~/$1.*; then
      for f in ~/$1.*; do
        .tick-zprofile "... sourcing $f"
        . $f
      done
    fi
    .tick-zprofile "[end] .source-extra-start-files ($1)"
  }
  # .source-extra-start-files

}
zprofile-wrapper

alias .reload-shell='qeval exec $SHELL -l'
alias .rs='veval .reload-shell'

alias .reload-zprofile='qeval . ~/.zprofile'
alias .rlzp='qeval .reload-zprofile'


export _DOT_ZPROFILE_MTIME="$(stat -L -f '%m' ~/.zprofile)"
.tick-zprofile "[END-FILE] (\$\$=$$), mtime=$_DOT_ZPROFILE_MTIME" #, \$PATH=[$PATH])"

# fi