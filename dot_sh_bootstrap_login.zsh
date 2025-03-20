#!/usr/bin/env zsh

# Shell-agnostic bootstrap functions and aliases for login shells.

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

[[ -e ~/.sh_bootstrap-0 ]] && source ~/.sh_bootstrap-0

# Do not execute this script if it has already been run this session and is not modified since.
if [[ "$(sh-ok-to-skip ~/.sh_bootstrap_login)" != 'true' ]]; then

  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  is-defined .tick || safe-source ~/.tick.sh
  .tick-login() { .tick -s ".sh_bootstrap_login" $@; }
  .tick-login "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' $HOME/.sh_bootstrap_login)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

  bootstrap-login-wrapper() {
    .tick-login "[START-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH], \$PS1=[$PS1])"

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

    export EDITOR=vi


    # CLICOLOR_FORCE has an adverse interaction with a few tools.
    export CLICOLOR=1 CLICOLOR_FORCE=1

    #
    ### 'ack' helpers
    #
    if is-defined ack; then
      alias ack-help-types='eval-quiet ack --help-types'
      alias ack-java='eval-quiet ack --type=java'; alias ackj='ack-java'
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
      eval-quiet cd "$link"
      if [[ -d "$target" ]]; then
          eval-quiet cd "$target"
      else
          eval-quiet cd "$(dirname "$target")"
      fi
    }

    #
    ### 'chmod' helpers
    #
    # Make specified, or all in PWD, shell scripts executable.
    chx() {
      local files=($@)
      [[ -z "$1" ]] && files=(*.sh) && _VERBOSE=1
      eval-quiet chmod ${_VERBOSE:+-vv} +x "${files[@]}"
    }

    #
    ### 'less' helpers:
    # 
    alias l='less'
    #
    # Lines will NOT wrap, but CTRL-C, arrow keys can scroll left and right. Press 'F' to resume "tailing".
    alias less-trunc='eval-quiet less --chop-long-lines +F'

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
    alias ls1='ls -1 -F'
    alias lsa='ls -A -F'
    #
    alias ll='ls -og -hF'
    alias llt='ls -og -hF -t'
    alias lltr='ls -og -hF -tr'
    alias lls='ls -og -hF -S'
    alias llsr='ls -og -hF -Sr'
    #
    alias lA='ls -al -hF'
    alias la='ls -Al -hF'
    alias lat='ls -Al -hF -t'
    alias latr='ls -Al -hF -tr'
    alias las='ls -Al -hF -S'
    alias lasr='ls -Al -hF -Sr'
    #
    # Display permissions in octal, from: http://askubuntu.com/a/152005
    # I've tried to figure out how this works but have no clue.
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
      
      eval-verbose nc -z $host $port $@
      
      local ret=$?
      if ! _quiet; then
        ((!ret)) && echo "Active" || echo "Inactive"
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
      eval-quiet "$ps_cmd"
    }
    ps-java() {
      eval-verbose "ps-grep -l java | sed -E -n '/^USER/p; /^[[:alnum:]]+ +([[:digit:]]+ +){2}/ s/^([[:alnum:]]+ +([[:digit:]]+ +){2}([^[:space:]]+ +){4}([^[:space:]]+) +).*( ([a-z]+\.)+[A-Z][^.]+.*)$/\1 - \5/p;'" \
        | sed -E 's:\/Library\/Java\/JavaVirtualMachines\/::'
      # eval-quiet "ps-grep -l java | sed -E -n '/^USER/p; /^[[:alnum:]]+ +([[:digit:]]+ +){2}/ s/^([[:alnum:]]+ +(?:[[:digit:]]+ +){2} +(?:[^[:space:]]+ +){4} +([^[:space:]]+) +).+$/\1/; p;'" # + \d+ +\d+/p;' #' +\w+ +\w+ +\w+ +'
      # eval-quiet "ps-grep -l java | sed -E -n 's/^(USER.+)|([[:alnum:]]+ +([[:digit:]]+ +){2} +([[:digit:]]+ +){5} +.+)$/\2/; p;'" # + \d+ +\d+/p;' #' +\w+ +\w+ +\w+ +'
    }
    ps-java-pid-class() {
      [[ -z "$1" ]] && echo-error "Usage: ps-java-pid-class PID" && return 1
       eval-quiet "ps -p $1 | sed -E -n -e 's/.+ ([a-z]+\.)+([A-Z][A-Za-z]+).*/\2/p'"
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
      eval-quiet lsof -b +c 16 -i TCP -n -P -w $@
    }
    ps-ports-2() {
      ps-ports-1 $@ | egrep --color=never '^COMMAND [A-Z /]+$|(java|idea|pycharm|datagrip) .+ \((LISTEN|ESTABLISHED)\)$'
    }
    ps-ports-3() {
      ps-ports-2 $@ | awk '{printf("%-16s %5s  %s\n", $1, $2, $9);}'
      # | awk '{split($9,hostport,":"); printf("%s %s\n", $2, hostport[2]);}'
    }
    ps-ports() {
      ps-ports-3 $@ | sort -k2 -k3
    }
    ps-ports-java-class() {
      printf "%-16s  %5d  %s\n" "COMMAND" "PID" "PORTS"
      ps-ports $@ \
      | while read cmd pid ports; do
        class="$(ps-java-pid-class $pid)"
        printf "%-16s %5d %-16s %s\n" "$cmd" "$pid" "$class" "$ports"
      done
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
    alias term-wrap='eval-quiet tput smam'
    alias term-trunc='eval-quiet tput rmam'
    #
    # colored text, from https://www.shellhacks.com/bash-colors/
    echo-color() {
      local USAGE="Usage: echo-color [-n] black|red|green|brown|blue|purple|cyan|light-gray TEXT [...]"
      local opt_no_crlf=; [[ "$1" == "-n" ]] && opt_no_crlf='-n' && shift 1
      [[ -z "$2" ]] && echo-error "$USAGE" && return 1

      local color="$(lower $1)"; shift 1
      case "$color" in
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
          [[ ! -d "$dir" ]] && echo-verbose "touchd: $dir_tilde: not a directory" && continue

          local newest="$(ls -A1t "$dir/" | head -n 1)"
          [[ -z "$newest" ]] && echo-verbose "touchd: empty directory: $dir_tilde" && continue

          local dir_time="$(stat -f %Sm "$dir")"; [[ -z "$dir_time" ]] && return 1
          local newest_time="$(stat -f %Sm "$dir/$newest")"; [[ -z "$newest_time" ]] && return 1
          [[ "$dir_time" == "$newest_time" ]] && echo-verbose "touchd: $dir_tilde: mtime already matches $newest: $newest_time" && continue
          echo "touchd: updating mtime of '$dir_tilde' ($dir_time) to match '$newest': $newest_time"

          # touch -h will update link's target instead of link
          eval-quiet touch -r "$dir/$newest" "$dir"
          [[ -L "$dir" ]] && eval-quiet touch -h -r "$dir/$newest" "$dir"
          
          ((count++))
      done
      ((!count)) && return 1
      echo-verbose "touchd: updated $count directories"
    }
    #
    touchd-R() {
      local dirs=$@
      [[ -z "$dirs" ]] && dirs="$PWD"
      for dir in $dirs; do
          find "$dir" -depth ! -type f -print |\
          while read -r subdir; do
              eval-quiet touchd "$subdir"
          done
          eval-quiet touchd "$dir"
      done
    }


    #
    ### symlink/ln helpers
    #
    ln-valid() {
      local files="${@:-*}"
      local ret=0
      for link in ${~files}; do
        local target=
        local ln_status="OK"
        if [[ ! -L "$link" ]]; then
          ! _verbose && continue
          ln_status="NON-LINK"
        else
          target="$(readlink "$link")"
          [[ ! -e "$target" ]] && ln_status="INVALID"
        fi
        local line="$(printf '%-9s %s -> %s\n' $ln_status $link $target)"
        if [[ "$ln_status" == "OK" ]]; then
          echo-quiet "$line"
        elif [[ "$ln_status" == "NON-LINK" ]]; then
          echo-color blue "$line"
        else
          ret=1
          echo-color red "$line"
        fi
      done
      return $ret
    }

    #
    ###  HOMEBREW
    #
    .setup-homebrew() {
      .tick-login '[start] .setup-homebrew'

      local brew_bin="$(glob-path-first /usr/local/bin/brew /opt/homebrew/bin/brew)"
      if [[ -n "$brew_bin" ]]; then
        .tick-login "... using homebrew binary: $brew_bin"
      else
        .tick-login "... homebrew not installed"
        .tick-login "... execute: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        .tick-login "[end] .setup-homebrew"
        return 1
      fi

      eval "$($brew_bin shellenv $SHELL 2>/dev/null)"
      if [[ -d "$HOMEBREW_PREFIX" ]]; then
        .tick-login "... homebrew shellenv set \$HOMEBREW_PREFIX=$HOMEBREW_PREFIX"
      else
        .tick-login "... homebrew shellenv did not properly set \$HOMEBREW_PREFIX"
        .tick-login "[end] .setup-homebrew"
        return 1
      fi

      path-prepend PATH "$(substring_before_last $brew_bin '/')"

      local gnu_getopt_home="$HOMEBREW_PREFIX/opt/gnu-getopt"
      if [[ -e "$gnu_getopt_home" ]]; then
        path-prepend PATH "$gnu_getopt_home/bin"
        .tick-login "... prepended $gnu_getopt_home/bin to PATH"
      else
        .tick-login "... gnu-getopt not installed via brew"
      fi

      local openssl_home="$HOMEBREW_PREFIX/opt/openssl@3"
      if [[ -e "$openssl_home" ]]; then
        path-prepend PATH "$openssl_home/bin"
        .tick-login "... prepended $openssl_home/bin to PATH"
      else
        .tick-login '... openssl@3 not installed via brew'
      fi

      .tick-login "[end] .setup-homebrew"
    }
    ! ((_SKIP_HOMEBREW_SETUP)) && .setup-homebrew


    #
    ###  ITERM
    #
    .setup-iterm() {
      .tick-login '[start] .setup-iterm'
      [[ "$TERM_PROGRAM" != "iTerm.app" ]] && .tick-login "... iTerm2 not active" && return 1

      if [[ -e "$HOME/.iterm2_shell_integration.bash" ]]; then
        .tick-login '... loading iTerm2 bash shell integration'
        source "$HOME/.iterm2_shell_integration.bash"
        export ITERM_BADGE="$ITERM_PROFILE"
        iterm2_print_user_vars() {
          iterm2_set_user_var badge "$ITERM_BADGE"
        }
      else
        .tick-login '... iTerm bash shell integration not installed'
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

      .tick-login "[end] .setup-iterm, ITERM_PROFILE=$ITERM_PROFILE"
    }
    ! ((_SKIP_ITERM_SETUP)) && .setup-iterm


    #
    ###  GIT
    #
    .setup-git() {
      .tick-login '[start] .setup-git'
      if ! is-defined git; then
        .tick-login "[end] .setup-git: git not installed"
        return 0
      fi

      .tick-login "... using $(git --version)"

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
          0)  eval-verbose git branch --list --ignore-case --sort='-committerdate' \
                --format="\"$f_sha $f_date_relative $f_branch $f_track_short\"" \
                $@ | less
              ;;
          1)  eval-verbose git branch --list --ignore-case --sort='-committerdate' --column=never \
                --format="\"$f_sha  $f_date_short  $f_authorname_20 $f_branch_and_track_short $f_upstream $f_comment\"" $@ \
                | awk -v MAXW=$((COLUMNS-8)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | less
              ;;
          2)  eval-verbose git branch --list --ignore-case --sort='-committerdate' --column=never \
                --format="\"$f_sha  $f_date  $f_authorname_20 $f_branch_and_track_short $f_upstream $f_comment $f_track \"" $@ \
                | awk -v MAXW=$((COLUMNS-8)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | less
              ;;
          *)  echo-error "git-branch: unexpected level: $branch_level"
              return 1
              ;;
        esac
      }
      alias gbr='eval-verbose "git-branch | egrep -v \"[A-Z]+\.(feature|hotfix)|(feature|hotfix)\.[A-Z]+\""'
      alias gbra='eval-verbose git-branch 1'
      alias gbran='eval-verbose git-branch 2' gbranc='gbran' gbranch='gbran'
      #
      alias gbr-rm='eval-quiet git brrm'
      alias gbr-mv='eval-quiet git brmv'
      alias gbr-cp='eval-quiet git brcp'
      #
      git-branch-bak() {
        [[ -z "$GIT_BRANCH" ]] && echo-error "No current branch" && return 1
        [[ -n "$1" ]] && mmdd="$1" || mmdd="$(date +'%m%d')"
        eval-quiet git brcp \"$GIT_BRANCH\" \"XXX.${GIT_BRANCH}.$mmdd\"
      }
      alias gbr-bak='eval-quiet git-branch-bak'
      #
      git-branch-set-upstream() {
        eval-quiet git branch --set-upstream-to "origin/$GIT_BRANCH" $@
      }
      git-branch-set-upstream-to() {
        eval-quiet git branch --set-upstream-to "${@:-origin/$GIT_BRANCH}"
      }
      git-branch-unset-upstream() {
        eval-quiet git branch --unset-upstream "${@:-origin/$GIT_BRANCH}"
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
        eval-verbose git -P log --all -n 10 --date="iso-strict" --format=\"'%h %cd %cN'\" --color=never $log_opts -- $file_glob \
          | while read commit_sha commit_dt committer; do
              echo-verbose "$commit_sha | $commit_dt | $committer"
              eval-verbose git -P branch --all --list --contains=$commit_sha --format="\"%(committerdate:format:%F %H:%M) | %(refname:short)\""
            done \
          | sort -r -s \
          | uniq
      }
      alias gbw='eval-quiet git-branches-with'
      #
      alias gco='eval-quiet git checkout'
      alias gcod='eval-quiet git checkout develop'
      alias gcom='eval-quiet git checkout master'
      #
      git-checkout-remote-branch() {
        [[ -z "$1" ]] && echo-error "usage: git-checkout-remote-branch remote/branch_name" && return 1
        [[ ! "$1" =~ .+/.+ ]] && echo-error "usage: git-checkout-remote-branch remote/branch_name" && return 1
        local remote_branch="$1" && shift
        local remote_name="$(substring_before_first $remote_branch '/')"
        local branch_name="$(substring_after_first $remote_branch '/')"
        echo-verbose "$(echo-glob remote_branch remote_name branch_name)"
        eval-quiet git checkout -b $branch_name $remote_name/$branch_name || return 1
        eval-quiet git branch --set-upstream-to $remote_name/$branch_name
      }
      #
      git-commit-message() {
        local opts=
        while [[ "$1" =~ ^--?[a-z] ]]; do
          opts="$opts $1"
          shift
        done
        [[ -z "$1" ]] && echo-error "usage: git-commit-message 'message'" && return 1
        eval-quiet git commit --message \"$@\" || return 1
        eval-quiet git diff --stat=$COLUMNS HEAD^ | grep -E -v '[0-9]+ (files? changed|insertions?|deletions?)'
      }
      alias gcm='eval-quiet git-commit-message'
      #
      alias gds='eval-quiet git ds'
      alias gdss='eval-quiet git dss'
      alias gdds='eval-quiet git dds'

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
              eval-verbose git log -20 --abbrev=$hash_len --decorate=short --date='format:%D' \
                --format="\"$f_hash  $f_author_name_mailmap $f_commit_date_short $f_tags_short $f_subject_line$c_reset\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E \
                  -e 's/origin/$O/g' \
                  -e 's/tag: ?/$T:/g' \
                  -e 's/ -> /->/g' \
                | less
                  # -e "s/$(git config --get user.name)/\$ME/g" \
                ;;
          1)  eval-verbose git log -20 --abbrev=$hash_len --date=human --use-mailmap \
                --format="\"$f_hash  $f_author_name_mailmap_long $f_commit_date_rel $f_tags $f_subject_line$c_reset\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E \
                  -e 's/origin/$O/g' \
                  -e 's/tag: ?/$T:/g' \
                  -e 's/ -> /->/g' \
                | less
                ;;
          2) eval-verbose git log -20 --abbrev=$hash_len --date=human --use-mailmap \
                --format="\"$f_hash  $f_author_name_mailmap_long  $f_commit_date_short $f_commit_date_rel $f_tags%n  $f_subject_line$c_reset\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E \
                  -e 's/origin/$O/g' \
                  -e 's/tag: ?/$T:/g' \
                  -e 's/ -> /->/g' \
                | less
              ;;
          3) eval-verbose git log -20 --abbrev=$hash_len --date=human --no-use-mailmap --stat \
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
      alias glo='eval-quiet git-log'
      alias glog='eval-quiet git-log 1'
      alias glogg='eval-quiet git-log 2'
      alias gloggg='eval-quiet git-log 3'

      git-log-me() {
        git-log $@ -999 | grep "'$(git config --get user.name)'"
      }
      alias glme='eval-quiet git-log-me'
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
          eval-quiet git pull --ff-only
          cd ..
        done
      }
      #
      alias gpff='eval-quiet git pff'
      #
      alias gr-dev='eval-quiet git rebase develop'
      alias gr-mas='eval-quiet git rebase master'
      alias gr-ab='eval-quiet git rebase --abort'
      #
      alias gs='git stash'
      alias gsh='eval-quiet git stash -h'
      alias gsl='eval-quiet git stash list' 
      alias gsld='eval-quiet git stash list --date=short' 
      alias gsa='eval-quiet git stash apply' 
      alias gss='eval-quiet git stash show'
      #
      git-stash-diff() {
        local index=0; [[ -n "$1" ]] && index=$1 && shift
        local index2=; [[ "$1" =~ ^[[:digit:]]+$ ]] && index2=$1 && shift
        local rev="stash@{$index}"
        local rev2=; [[ -n "$index2" ]] && rev2="stash@{$index2}"
        eval-quiet git diff $rev $rev2 $@
      }
      git-stash-diff-stat() {
        local index=0; [[ -n "$1" ]] && index=$1 && shift
        local index2=; [[ "$1" =~ ^[[:digit:]]+$ ]] && index2=$1 && shift
        local rev="stash@{$index}"
        local rev2=; [[ -n "$index2" ]] && rev2="stash@{$index2}"
        eval-quiet git diff --stat $rev $rev2 $@
      }
      alias gsd=git-stash-diff
      alias gsds=git-stash-diff-stat
      #
      git-status() {
        local status_level=1; [[ "$1" =~ ^[0123]$ ]] && local status_level=$1 && shift 1

        git branch --show-current 1>/dev/null || return 1

        c_remote_branch="$(git config --get-color color.status.remotebranch)"
        c_stash="$(git config --get-color color.decorate.stash)"
        c_reset="$(git config --get-color '' reset)"
        
        case "$status_level" in

          0)  eval-verbose git -c advice.statusHints=false status --short $@ ;;
          1)  eval-verbose git -c advice.statusHints=false status --column=dense --no-show-stash $@ \
              | grep -E -v '^\#?\s*$' \
              | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;"
              ;;
          2)  echo "#"
              eval-verbose git -c advice.statusHints=false status --column=nodense --show-stash $@ \
              | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;" \
              | sed -E -e "s/(Your stash.+has [[:digit:]]+ entr(ies|y))/${c_stash}\\1${c_reset}/;"
              ;;
          3)  echo "#"
              eval-verbose git -c advice.statusHints=false status --column=nodense --show-stash --ignored=traditional --verbose $@ \
              | sed -E -e "s/'(.+)'/'${c_remote_branch}\\1${c_reset}'/;" \
              | sed -E -e "s/(Your stash.+has [[:digit:]]+ entr(ies|y))/${c_stash}\\1${c_reset}/;"
              ;;
        esac
      }
      alias gst='eval-quiet git-status 0'
      alias gsta='eval-quiet git-status 1'
      alias gstat='eval-quiet git-status 2'
      alias gstatu='eval-quiet git-status 3' gstatus='gstatu'

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
          eval-quiet touch -h -t "$commit_ts" "$f"
          qprintf 'after:  ' && ls -oghF "$f"
        done      
      }

      if is-defined git-flow; then
        .tick-login '... git-flow is installed'
        # https://github.com/aleksandr-m/gitflow-maven-plugin

        .tick-login "... checking for ~/.git-flow-completion"
        _QUIET=1 safe-source ~/.git-flow-completion
        complete -p | grep -E -q 'git-flow$' && .tick-login "... loaded git-flow cli completion" || .tick-login "... not using git-flow completion"

        # Usage: gf-feature-start featureName [mvn_opts] [gitflow_opts]
        gf-feature-start() {
          local gitbr="$(git branch --show-current 2> /dev/null)"
          [[ -z "$gitbr" ]] && echo-error "gf-feature-start: not in a git repository" && return 1
          local featureName="${1#*feature/}"; shift  # everything after "feature/", else entire string
          local mvn_opts="$1"; shift
          local gitflow_opts="$1"; shift
          eval-quiet mvn --batch-mode "$mvn_opts" gitflow:feature-start -Dverbose=true -DfeatureName="$featureName" -DpushRemote=true "$gitflow_opts"
        }
      
        # Usage (from feature branch): gf-feature-finish -m [mvn_opts] -g [gitflow_opts]
        gf-feature-finish() {
          local gitbr="$(git branch --show-current 2> /dev/null)"
          [[ -z "$gitbr" ]] && echo-error "gf-feature-finish: not in a git repository" && return 1
          local featureName="${gitbr#*feature/}"
          local mvn_opts="$1"; shift
          local gitflow_opts="$1"; shift
          eval-quiet mvn --batch-mode "$mvn_opts" gitflow:feature-finish -Dverbose=true -DkeepBranch=true -DfeatureName="$featureName" -DfeatureSquash=true -DincrementVersionAtFinish=true "$gitflow_opts"
        }
      fi
        
      .tick-login '[end] .setup-git'
    }
    ! ((_SKIP_GIT_SETUP)) && .setup-git


    #
    ### SDKMAN/JAVA
    #
    .setup-java-sdkman() {
      .tick-login '[start] .setup-java-sdkman'
      if [[ ! -e "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        .tick-login "[end] .setup-java-sdkman, SDKMAN not installed"
        return 1
      fi

      export SDKMAN_DIR="$HOME/.sdkman"

      if [[ "$(type -t sdk)" == "function" ]]; then
        .tick-login 'sdkman already initialized'
      else
        .tick-login '... initializing sdkman'
        . "$SDKMAN_DIR/bin/sdkman-init.sh"
        path-prepend "$SDKMAN_DIR/bin"
        .tick-login "... initialized sdkman"
      fi
      # .tick-login -e 'echo "... using $(sdkman version)"'
      # .tick-login -e 'echo "... $ which javac: $(2>&1 which javac)"'
      # .tick-login -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
      
      if [[ -z "$JAVA_HOME" ]]; then
        .tick-login "sdkman left a blank JAVA_HOME"
      elif [[ ! -d "$JAVA_HOME" ]]; then
        .tick-login "sdkman left a non-directory JAVA_HOME: $JAVA_HOME"
      elif [[ ! -d "$JAVA_HOME/bin" ]]; then
        .tick-login "sdkman non-directory JAVA_HOME/bin: $JAVA_HOME/bin"
      fi

      sdk-ls() {
        sdk ls java '$@' | head -n 5
        sdk ls java '$@' | egrep '>>>| installed | local only '
      }

      .tick-login -e tilde-compress "[end] .setup-java-sdkman, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
    }
    ! ((_SKIP_SDKMAN_SETUP)) && .setup-java-sdkman


    #
    ### JENV/JAVA
    #
    .setup-java-jenv() {
      .tick-login '[start] .setup-java-jenv'
      ! is-defined jenv && .tick-login "[end] .setup-java-jenv, jenv not installed" && return 1

      if [[ "$(type -t jenv)" == "function" ]]; then
        .tick-login 'jenv already initialized'
      else
        .tick-login '... initializing jenv'
        eval "$(jenv init --no-rehash -)"
        path-prepend "$HOME/.jenv/bin"
        .tick-login "... initialized jenv"
      fi
      # .tick-login -e 'echo "... using $(jenv --version)"'
      # .tick-login -e 'echo "... using java $(jenv version)"'
      # .tick-login -e 'echo "... $ which javac: $(2>&1 which javac)"'
      # .tick-login -e 'echo "... $ javac -version: $(2>&1 javac -version)"'
      
      local javahome="$(jenv javahome)"
      if [[ -z "$javahome" ]]; then
        .tick-login "jenv reports a blank JAVA_HOME"
      elif [[ ! -d "$javahome" ]]; then
        .tick-login "jenv reports a non-directory JAVA_HOME: $javahome"
      elif [[ ! -d "$javahome/bin" ]]; then
        .tick-login "jenv non-directory JAVA_HOME/bin: $javahome/bin"
      else
        export JAVA_HOME="$javahome"
      fi

      .tick-login -e tilde-compress "[end] .setup-java-jenv, JAVA_HOME=[$JAVA_HOME], PATH=$PATH"
    }
    ! ((_SKIP_SETUP_JENV)) && ! is-defined sdk && .setup-java-jenv


    #
    ### POSTGRESQL
    #
    .setup-pg() {
      .tick-login '[start] .setup-pg'
      export HOMEBREW_POSTGRESQL_SERVICE='postgresql@14'
      if [[ -e "$HOMEBREW_PREFIX/Cellar/$HOMEBREW_POSTGRESQL_SERVICE" ]]; then
        .tick-login "... found HOMEBREW_POSTGRESQL_SERVICE=$HOMEBREW_POSTGRESQL_SERVICE"
      else
        .tick-login "[end] .setup-pg, invalid HOMEBREW_POSTGRESQL_SERVICE=$HOMEBREW_POSTGRESQL_SERVICE"
        return 1
      fi
      # path-append '/usr/local/opt/postgresql/bin'
      alias pg-restart='eval-quiet brew services restart $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-start='eval-quiet brew services start $HOMEBREW_POSTGRESQL_SERVICE'
      alias pg-stop='eval-quiet brew services stop $HOMEBREW_POSTGRESQL_SERVICE'
      .tick-login '[end] .setup-pg'
    }
    ! ((_SKIP_POSTGRES_SETUP)) && .setup-pg


    #
    ### SCHEMASPY
    #
    .setup-schemaspy() {
      if [[ -e "$HOME/lib/schemaspy.jar" ]]; then
        .tick-login '... defining schemaspy function'
        schemaspy() {
          local driver_path="$HOME/lib"
          local spy_output="schemaspy-out"
          while [[ "$1" =~ -[a-z] ]]; do case "$1" in
            -dp|--driver-path)    driver_path="$2"; shift 2;;
            -o|--outputDirectory) spy_output="$2"; shift 2;;
            *) break;;
          esac; done
          eval-quiet java -jar "$HOME/lib/schemaspy.jar" \
            -cat '%' \
            -dp "$driver_path" \
            -o  "$spy_output" \
            -noviews -noimplied -nopages -maxdet 9999 \
            $@
        }
      fi
    }
    ! ((_SETUP_SCHEMASPY_DISABLED)) && .setup-schemaspy


    .tick-login "[END-WRAPPER] (\$\$=$$)" #, \$PATH=[$PATH])"
  }
  bootstrap-login-wrapper

  .reload-bootstrap-login() {
    unset "_DOT_SH_MTIMES[sh_bootstrap_login]"
    eval-quiet source ~/.sh_bootstrap_login
  }

  sh-store-mtime ~/.sh_bootstrap_login
  .tick-login "[END-FILE] (\$\$=$$), mtime=$_DOT_SH_MTIMES[sh_bootstrap_login]" #, \$PATH=[$PATH])"
fi
