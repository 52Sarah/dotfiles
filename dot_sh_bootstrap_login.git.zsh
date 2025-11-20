#!/usr/bin/env zsh

# Shell-agnostic git-related functions and aliases for login shells.

# Do not execute this script if it has already been run this session and is not modified since.
if [[ "$(sh-ok-to-skip ~/.sh_bootstrap_login.git)" != 'true' ]]; then

  # Simple login file debugging to ~/.tick.log and/or stdout/stderr.
  is-defined .tick || safe-source ~/.tick.sh
  .tick-login-git() { .tick -s ".sh_bootstrap_login" $@; }
  .tick-login-git "[START-FILE] (\$\$=$$), mtime=$(stat -L -f '%m' $HOME/.sh_bootstrap_login.git)"

  bootstrap-login-git-wrapper() {
    .tick-login-git "[START-WRAPPER] (\$\$=$$)"

    .setup-git() {
      .tick-login '[start] .setup-git'
      if ! is-defined git; then
        .tick-login "[end] .setup-git: git not installed"
        return 0
      fi

      # usage: git-alias [--max-count n] [patt]
      git-alias() {
        local USAGE="usage: git-alias [[--max-count] n] [patt]"
        local opt_patt='.+' opt_maxcount=999
        while [[ -n "$1" ]]; do case "$1" in
          -n | --max-count) shift 1; 
                            if [[ -n "$1" ]]; then
                              opt_maxcount=$1
                              shift
                            else
                              echo-error "usage: $USAGE"
                              return 1
                            fi;;
          *) break;;
        esac; done
        [[ "$1" =~ ^[0-9]+$ ]] && opt_maxcount=$1 && shift
        opt_patt="$@"

        git config --get-regexp "^alias\.${opt_patt}" \
          | head -n $opt_maxcount \
          | sed -E 's/^alias\.([^ ]+) +(.*)/\1\t\2/;'
      }
    
      # usage: git-branch [detail_level:0]
      # detail_level:
      #   0 - local branches, brief
      #   1 - 
      git-branch() {
        local branch_level=1; while [[ "$1" =~ [012] ]]; do branch_level="$1" && shift 1; done
        git branch --show-current 1>/dev/null || return 1

        c_br_remote="$(git config --get-color color.branch.remote)"
        c_br_current="$(git config --get-color color.branch.current)"
        c_commit="$(git config --get-color color.diff.commit)"

        c_br_upstream="$(git config --get-color color.branch.upstream)"
        c_stash="$(git config --get-color color.decorate.stash)"
        c_untracked="$(git config --get-color color.status.untracked)"
        c_reset="%(color:reset)"

        f_sha="%(if)%(HEAD)%(then)$c_br_current*%(else)$c_commit %(end)%(objectname:short)$c_reset"
        f_track="$c_untracked%(if)%(upstream)%(then)%(upstream:track)%(end)$c_reset"
        f_track_short="$c_untracked%(if)%(upstream)%(then)[%(upstream:trackshort)]%(end)$c_reset"
        f_date="$c_stash%(align:14,left)%(committerdate:format:%F %T)%(end)$c_reset"
        f_date_relative="$c_stash%(align:20,left)%(committerdate:relative)%(end)$c_reset"
        f_date_short="$c_stash%(align:14,left)%(committerdate:format:%D %H:%M)%(end)$c_reset"
        f_authorname="%(align:20,left)%(authorname)%(end)"
        f_branch="%(if)%(HEAD)%(then)$c_br_current%(refname:short)%(else)%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)$c_br_remote%(else)$c_stash%(end)%(refname:short)%(end)$c_reset"
        f_upstream="%(if)%(upstream)%(then)$c_br_upstream(%(upstream:short)$c_reset) %(end)"
        f_comment="%(contents:subject)"
        f_branch_and_track_short="%(align:60,left)$f_branch $f_track_short%(end)%(if)%(HEAD)%(then)  %(end)"
        f_upstream_and_comment="$f_upstream$f_comment"

        case "$branch_level" in
          0)  eval-verbose git branch --list --ignore-case --sort='-committerdate' \
                --format="\"$f_sha  $f_date_relative $f_branch $f_track_short\"" \
                $@ | less
              ;;
          1)  eval-verbose git branch --list --ignore-case --sort='-committerdate' --column=never \
                --format="\"$f_sha  %(align:left,80)$f_date_short  $f_authorname $f_branch_and_track_short%(end) $f_upstream_and_comment\"" $@ \
                | awk -v MAXW=$((COLUMNS-8)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | less
              ;;
          2)  eval-verbose git branch --list --ignore-case --sort='-committerdate' --column=never \
                --format="\"$f_sha  %(align:left,90)$f_date  $f_authorname $f_branch_and_track_short%(end) $f_upstream_and_comment $f_track \"" $@ \
                | awk -v MAXW=$((COLUMNS-8)) '{ if (MAXW<=0 || length()<=MAXW) {print $0} else {printf("%-" MAXW "." MAXW "s...\n"), $0} }' \
                | less
              ;;
          *)  echo-error "git-branch: unexpected level: $branch_level"
              return 1
              ;;
        esac
      }
      alias gbr='eval-verbose git-branch 0'
      alias gbra='eval-verbose git-branch 1'
      alias gbran='eval-verbose git-branch 2' gbranc='gbran' gbranch='gbran'
      
      alias gbr-rm='eval-quiet git brrm'
      alias gbr-mv='eval-quiet git brmv'
      alias gbr-cp='eval-quiet git brcp'
      
      # make a backup copy of current branch using timestamp 'mmdd' as default suffix
      git-branch-bak() {
        [[ -z "$GIT_BRANCH" ]] && echo-error "No current branch" && return 1
        [[ -n "$1" ]] && mmdd="$1" || mmdd="$(date +'%m%d')"
        eval-quiet git brcp \"$GIT_BRANCH\" \"XXX.${GIT_BRANCH}.$mmdd\"
      }
      alias gbr-bak='eval-quiet git-branch-bak'
      
      git-branch-set-upstream()     { eval-quiet git branch --set-upstream-to "origin/$GIT_BRANCH" $@; }
      git-branch-set-upstream-to()  { eval-quiet git branch --set-upstream-to "${@:-origin/$GIT_BRANCH}"; }
      git-branch-unset-upstream()   { eval-quiet git branch --unset-upstream; }
      
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
      
      alias gco='eval-quiet git checkout'
      alias gcod='eval-quiet git checkout develop'
      alias gcom='eval-quiet git checkout master'
    
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
      
      alias gpff='eval-quiet git pff'
      
      alias gr-dev='eval-quiet git rebase develop'
      alias gr-mas='eval-quiet git rebase master'
      alias gr-ab='eval-quiet git rebase --abort'
      
      alias gs='eval-quiet git stash'
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


    .tick-login-git "[END-WRAPPER] (\$\$=$$)"
  }
  bootstrap-login-git-wrapper

  .reload-bootstrap-login-git() {
    unset "_DOT_SH_MTIMES[~/.sh_bootstrap_login.git]"
    eval-quiet source ~/.sh_bootstrap_login.git
  }

  sh-store-mtime ~/.sh_bootstrap_login.git
  .tick-login-git "[END-FILE] (\$\$=$$), mtime=$_DOT_SH_MTIMES[sh_bootstrap_login.git]"
fi
