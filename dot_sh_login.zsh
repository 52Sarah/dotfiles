#!/usr/bin/env zsh

# Shell-agnostic bootstrap functions and aliases for login shells.

# At startup, Zsh reads, in order, from:
#   1. ~/.zshenv
#   2. ~/.zprofile for login shells
#   3. ~/.zshrc for interactive shells
#   4. ~/.zlogin for login shells
# See: https://zsh.sourceforge.io/Doc/Release/Files.html

source ~/.sh_bootstrap

sh-login-wrapper() {
  local dot_fname='.sh_login'

  # Do not execute scripts if they have already been run this session and are not modified since.
  dot-ok-to-skip ~/$dot_fname && return 

  .reload-login() {
    unset "_DOT_MTIMES[.sh_login]"
    eval-quiet source ~/.sh_login
  }

  export _TICK_INDENT=
  is-command .tick || safe-source ~/.tick.sh
  .tick-login() { .tick -s ".sh_login" $@; }
  .tick-login "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' ~/.sh_login)" #, \$PATH=[$PATH], \$PS1=[$PS1])"


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
      if is-command ack; then
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
      #    4/2025: For some reason, IntelliJ doesn't like substring_before_last as used in .setup-homebrew.
      #
      .setup-homebrew() {
        .tick-login '[start] .setup-homebrew'
        .tick-login "... \$INTELLIJ_ENVIRONMENT_READER=$INTELLIJ_ENVIRONMENT_READER"
        .tick-login "... \$SHELL=$SHELL"

        local brew_binary="$(glob-path-first /usr/local/bin/brew /opt/homebrew/bin/brew)"
        if [[ -n "$brew_binary" ]]; then
          .tick-login "... using homebrew binary: $brew_binary"
        else
          .tick-login "... homebrew not installed"
          .tick-login "... execute: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          .tick-login "[end] .setup-homebrew"
          return 1
        fi

        eval "$($brew_binary shellenv $SHELL 2>/dev/null)"
        if [[ -d "$HOMEBREW_PREFIX" ]]; then
          .tick-login "... homebrew shellenv set \$HOMEBREW_PREFIX=$HOMEBREW_PREFIX"
        else
          .tick-login "... homebrew shellenv did not properly set \$HOMEBREW_PREFIX"
          .tick-login "[end] .setup-homebrew"
          return 1
        fi

        .tick-login "... computing brew_bin from \$brew_binary=$brew_binary"
        local brew_bin="$(substring-before-last $brew_binary '/')"
        path-prepend "$brew_bin"
        .tick-login "... prepended $brew_bin to PATH"

        local gnu_getopt_home="$HOMEBREW_PREFIX/opt/gnu-getopt"
        .tick-login "... checking gnu_getopt_home=$gnu_getopt_home"
        if [[ -e "$gnu_getopt_home" ]]; then
          path-prepend "$gnu_getopt_home/bin"
          .tick-login "... prepended $gnu_getopt_home/bin to PATH"
        else
          .tick-login "... gnu-getopt not installed via brew"
        fi

        local openssl_home="$HOMEBREW_PREFIX/opt/openssl@3"
        if [[ -e "$openssl_home" ]]; then
          path-prepend "$openssl_home/bin"
          .tick-login "... prepended $openssl_home/bin to PATH"
        else
          .tick-login '... openssl@3 not installed via brew'
        fi

        .tick-login "[end] .setup-homebrew"
      }
      ! ((_SKIP_HOMEBREW_SETUP)) && .setup-homebrew
      # ! ((_SKIP_HOMEBREW_SETUP)) && [[ -z "$INTELLIJ_ENVIRONMENT_READER" ]] && .setup-homebrew


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
      ### SDKMAN/JAVA
      #
      .setup-java-sdkman() {
        .tick-login '[start] .setup-java-sdkman'
        if [[ ! -e "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
          .tick-login "[end] .setup-java-sdkman, SDKMAN not installed"
          return 1
        fi

        export SDKMAN_DIR="$HOME/.sdkman"

        if [[ "$(whence -w sdk)" == "sdk: function" ]]; then
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
        ! is-command jenv && .tick-login "[end] .setup-java-jenv, jenv not installed" && return 1

        if [[ "$(whence -w jenv)" == "jenv: function" ]]; then
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
      ! ((_SKIP_JENV_SETUP)) && ! is-command sdk && .setup-java-jenv


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
      ! ((_SKIP_SCHEMASPY_SETUP)) && .setup-schemaspy


  source-extra-dot-files $dot_fname
  dot-store-mtime ~/$dot_fname

  .tick-login "[END-FILE] (\$\$=$$), mtime=$_DOT_MTIMES[$dot_fname]" #, \$PATH=[$PATH])"
}
sh-login-wrapper $@
unset -f sh-login-wrapper .tick-login
