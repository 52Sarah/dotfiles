#!/usr/bin/env zsh

# Shell-agnostic git-related functions and aliases for login shells.

# Do not execute this script if it has already been run this session and is not modified since.
if [[ "$(.dot-ok-to-skip ~/.sh_login.git)" != 'true' ]]; then

  sh-login-git-wrapper() {
    local dot_fname='.sh_login.git'

    # Do not execute scripts if they have already been run this session and are not modified since.
    .dot-ok-to-skip ~/$dot_fname && return 

    .reload-sh-login-git() {
      .dot-reset-mtimes
      eval-quiet source ~/.sh_login.git
    }

    .tick-login-git() { .tick -s ".sh_login.git" "$SHELL \$\$=$$ $@"; }
    .tick-start-line .tick-login-git $dot_fname

    .setup-git() {
      if ! is-command git; then
        .tick-login "[skip] .setup-git: git not installed"
        return 0
      fi
      .tick-login '[start] .setup-git'

      # Many of these items are better implemented by git-extras. so are disabled.

      # UGH - Friday afternoon boondoggle, 3/6/26. Maybe salvage some of this.
      # # Builds atop git-extras' `git brv` command, which lists fields in this order:
      # #   - committerdate (%F, or yyyy-mm-dd)
      # #   - refname:short (branch name)
      # #   - upstream:short (remote)
      # #   - objectname:short (sha)
      # #   - contents:subject (comment)
      # # usage: git-branch [detail_level:0]
      # # detail_level:
      # #   0 - local branches, brief
      # #   1 - 
      # git-branch() {
      #   local branch_level=1; [[ "$1" =~ '^[0-9]$' ]] && branch_level="$1" && shift 1
      #   git branch --show-current 1>/dev/null || return 1

      #   c_normal="$(git config get --type=color --default=normal '')"
      #   c_br_remote="$(git config get --type=color color.branch.remote)"
      #   c_br_current="$(git config get --type=color color.branch.current)"
      #   c_commit="$(git config get --type=color color.diff.commit)"

      #   c_br_upstream="$(git config get --type=color color.branch.upstream)"
      #   c_stash="$(git config get --type=color color.decorate.stash)"
      #   c_untracked="$(git config get --type=color color.status.untracked)"
      #   c_reset="$(git config get --type=color --default=reset '')"

      #   # f_sha="%(if)%(HEAD)%(then)$c_br_current*%(else)$c_commit %(end)%(objectname:short)$c_reset"
      #   # f_track="$c_untracked%(align:6,left)%(if)%(upstream)%(then)%(upstream:track)%(end)%(end)$c_reset"              # [gone], [=] (6)
      #   # f_track_short="$c_untracked%(align:5,left)%(if)%(upstream)%(then)[%(upstream:trackshort)]%(end)%(end)$c_reset" # [], [=], [<nn] (5)
      #   # f_date="$c_stash%(align:10,left)%(committerdate:format:%F)%(end)$c_reset"                 # yyyy-mm-dd (10)
      #   # f_date_short="$c_stash%(align:8,left)%(committerdate:format:%D)%(end)$c_reset"            # mm/dd/yy (8)
      #   # f_datetime="$c_stash%(align:20,left)%(committerdate:format:%F %T)%(end)$c_reset"          # yyyy-mm-dd hh:mm:ss(19)
      #   # f_datetime_relative="$c_stash%(align:20,left)%(committerdate:relative)%(end)$c_reset"
      #   # f_datetime_short="$c_stash%(align:14,left)%(committerdate:format:%D %H:%M)%(end)$c_reset" # mm/dd/yy hh:mm (14)
      #   # f_authorname="%(align:20,left)%(authorname)%(end)"
      #   # f_branch="%(if)%(HEAD)%(then)$c_br_current%(refname:short)%(else)%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)$c_br_remote%(else)$c_stash%(end)%(refname:short)%(end)$c_reset"
      #   # f_upstream="%(if)%(upstream)%(then)$c_br_upstream(%(upstream:short)$c_reset) %(end)"
      #   # f_comment="%(contents:subject)"
      #   # f_branch_and_track="%(align:60,left)$f_branch $f_track%(end)"
      #   # f_branch_and_track_short="%(align:60,left)$f_branch $f_track_short%(end)"
      #   # f_upstream_and_comment="$f_upstream$f_comment"
      #   f_head="%(if)%(HEAD)%(then)*%(else) %(end)"
      #   f_date="%(committerdate:format:%F)"                 # yyyy-mm-dd (10)
      #   f_date_short="%(committerdate:format:%D)"            # mm/dd/yy (8)
      #   f_datetime="%(committerdate:format:%F %T)"          # yyyy-mm-dd hh:mm:ss(19)
      #   f_datetime_relative="%(committerdate:relative)"
      #   f_datetime_short="%(committerdate:format:%D %H:%M)" # mm/dd/yy hh:mm (14)
      #   f_authorname="%(authorname)"
      #   f_branch="%(if)%(HEAD)%(then)%(refname:short)%(else)%(refname:short)%(end)"
      #   f_track="%(if)%(upstream)%(then)%(upstream:track)%(end)"              # [gone], [=] (6)
      #   f_track_short="%(if)%(upstream)%(then)[%(upstream:trackshort)]%(end)" # [], [=], [<nn] (5)
      #   f_upstream="%(if)%(upstream)%(then)%(upstream:short)%(else) %(end)" 
      #   f_sha="%(objectname:short)"
      #   f_comment="%(contents:subject)"
      #   f_branch_and_track="$f_branch $f_track"
      #   f_branch_and_track_short="$f_branch $f_track_short"
      #   f_upstream_and_comment="$f_upstream $f_comment"

      #   .git-branch-println() {
      #     local head="$1" date="$2" branch="$3" upstream="$4" sha="$5" comment="$6"
      #     local branch_len=50 upstream_len=50
      #     if matches "$branch" '.+\[.*\]$'; then
      #       (( branch_len += $(string-length "${c_untracked}${c_reset}") ))
      #       branch="$(substring-before-last "$branch" '[')${c_untracked}[$(substring-after-last "${branch}" '[')${c_reset}"
      #     fi
      #     if [[ "$head" = "*" ]]; then
      #       (( branch_len += $(string-length "${c_br_current}${c_reset}") ))
      #       branch="${c_br_current}${branch}${c_reset}"
      #     fi
      #     if [[ "$upstream" != " " ]]; then
      #       (( upstream_len += $(string-length "${c_br_upstream}${c_reset}") ))
      #       upstream="${c_br_upstream}${upstream}${c_reset}"
      #     fi
      #     sha="${c_commit}${sha}${c_reset}"
      #     printf "%-s %-s %-${branch_len}.${branch_len}s %-${upstream_len}.${upstream_len}s %-s %-s\n" \
      #         "$head" "$date" "$branch" "$upstream" "$sha" "$comment"
      #   }

      #   local format
      #   case "$branch_level" in
      #     0)  format="$f_head%09$f_date_short%09$f_branch_and_track_short%09$f_upstream%09$f_sha%09$f_comment";;
      #     1)  format="$f_head%09$f_datetime_short%09$f_branch_and_track_short%09$f_upstream%09$f_sha%09$f_comment";;
      #     2)  format="$f_head%09$f_datetime%09$f_branch_and_track%09$f_upstream%09$f_sha%09$f_comment";;
      #     *)  echo-error "git-branch: unexpected level: $branch_level"; return 1;;
      #   esac

      #   git for-each-ref --sort='-*committerdate' --format="$format" $@ 'refs/heads' | \
      #   while IFS=$'\t' read head date branch upstream sha comment; do
      #     .git-branch-println "$head" "$date" "$branch" "$upstream" "$sha" "$comment"
      #   done \
      #   | less
      # }
      # alias gbr='eval-verbose git-branch 0'
      # alias gbra='eval-verbose git-branch 1'
      # alias gbran='eval-verbose git-branch 2' gbranc='gbran' gbranch='gbran'
      
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
      # See: https://git-scm.com/docs/git-log
      git-log() {
        local log_level=1; [[ "$1" =~ ^[0123]$ ]] && log_level="$1" && shift 1
        git branch --show-current 1>/dev/null || return 1

        local hash_len=7

        c_reset='%C(reset)'
        c_commit="%C(yellow)"
        c_tag="%C(bold cyan)"
        c_stash="%C(white)"

        f_hash="%<($hash_len)${c_commit}%h"
        f_author_name_mailmap="${c_reset}%<(20)%aN"
        f_author_name="${c_reset}%<(20)%an"
        f_commit_date="%cd"
        f_commit_date_rel="%<(14)%cr"
        f_tags="${c_tag}%d"
        f_subject_line="${c_reset}%s"
        f_subject_line_white="${c_stash}%s"
        f_body="${c_reset}%b"

        case "$log_level" in
          0) eval-verbose git log -20 --abbrev=$hash_len --date=\'format:%D\' --decorate=short \
                --format="\"$f_hash $f_author_name_mailmap $f_commit_date $f_tags $f_subject_line$c_reset\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E -e 's/origin/@O/g; s/tag: ?/@T:/g; s/ -> /->/g;' \
                | less
                ;;
          1) eval-verbose git log -20 --abbrev=$hash_len --date=\'format:%a %D %H:%M\' \
                --format="\"$f_hash $f_author_name_mailmap $f_commit_date $f_tags $f_subject_line$c_reset\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E -e 's/origin/@O/g; s/tag: ?/@T:/g; s/ -> /->/g' \
                | less
              ;;
          2) eval-verbose git log -20 --abbrev=$hash_len --date=\'format:%a %D %T\' \
                --format="\"$f_hash $f_author_name_mailmap $f_commit_date, $f_commit_date_rel $f_tags $f_subject_line$c_reset\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E -e 's/origin/@O/g; s/tag: ?/@T:/g; s/ -> /->/g' \
                | less
              ;;
          3) eval-verbose git log -20 --abbrev=$hash_len --date=human --no-use-mailmap --stat \
                --format="\"$f_hash $f_author_name $f_commit_date, $f_commit_date_rel $f_tags%n  $f_subject_line_white$c_reset%n  $f_body\"" $@ \
                | awk -v MAXW=$((COLUMNS+12)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | sed -E -e 's/origin/@O/g; s/tag: ?/@T:/g; s/ -> /->/g' \
                | less
              ;;
          *)  echo-error "git-log: unexpected level: $log_level"
              return 1
              ;;
        esac
      }
      alias glo='eval-quiet git-log 0' glog='eval-quiet git-log 1' glogg='eval-quiet git-log 2' gloggg='eval-quiet git-log 3'
      git-log-me() { git-log $@ -999 | grep "$(git config --get user.name)"; }
      alias glme='eval-quiet git-log-me'
      
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

      if is-command git-flow; then
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
    .setup-git

  }
  sh-login-git-wrapper; unset -f sh-login-git-wrapper

  .dot-store-mtime ~/.sh_login.git
  .tick-login-git "[END-FILE] mtime=$(file-mtime ~/$dot_fname)"
fi
