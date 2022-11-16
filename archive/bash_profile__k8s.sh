  #
  ### KUBECTL
  #
  .setup-kubectl() {
    .tick_bp '[start ] .setup-kubectl'
    ! type -t kubectl &>/dev/null && .tick_bp '[finish] .setup-kubectl: k8s/kubectl not installed' && return 0

    .tick_bp '... loading kubectl bash completion'
    if ! eval "$(kubectl completion bash)"; then
      .tick_bp '!!! failed to load kubectl completion'
    elif complete -p | grep -E -q 'kubectl$'; then
      .tick_bp "... loaded kubectl bash completion"
    else
      .tick_bp "... not using kubectl completion"
    fi

    # list all kubectl aliases and functions
    k?() {
      alias \
        | grep -E "^alias k.*='k" \
        | sed -E "s/^alias //; s/='/=/; s/'$//" \
        | awk -F= '{printf("%-6s \t%s\n", $1, $2);}'
      declare -F \
        | sed -E 's/^declare -f //;' \
        | grep -E '^k-'
      declare -F \
        | egrep '^k\-'
    }
    
    k-less()      { qeval kubectl -n "$(kubens --current)" "$@" | less; }
    
    k-help()      { k-less "$@" --help; }
    k-config()    { k-less config "$@"; }
    k-get()       { k-less get "$@"; }
    k-describe()  { k-less describe "$@"; }
    k-explain()   { k-less explain "$@"; }
    k-logs()      { k-less logs "$@"; }
    alias k='k-less' kh='k-help' kc='k-config' kg='k-get' kd='k-describe' ke='k-explain' kl='k-logs'
    
    # get $1 resources (pods/deployments/etc.) for $2 app
    k-get-resource-for-app() {
      local res= app=
      while [[ -n "$1" ]]; do
        [[ "$1" = "-r" ]] && res="$2" && shift 2
        [[ "$1" = "-a" ]] && app="$2" && shift 2
      done
      [[ -z "$res" && -z "$app" ]] && eecho 'usage: k-get-resource-for-app -r res -a app [kubectl_opts ...]' && return 1
      eeval k-get $res -l "app=$app" -L 'alt-name,app,version' "$@"
    }
    alias kg-res-app='k-get-resource-for-app'

    kg-ns() { qeval k-get namespaces "$@"; }

    kg-pods() { qeval k-get pods -L alt-name,app,version "$@"; }
    alias kgp='kg-pods'

    # get pods for app $1      
    kg-pods-app() {
      [[ -z "$1" ]] && eecho 'usage: kg-pods-app app [kubectl_opts ...]' && return 1
      qeval k-getres--app -r pods -a "$1"
    }
    kgp-app() { k-getpods--app "$@"; }
    
    kg-pods-grep() {
      [[ -z "$1" ]] && echo-stderr 'usage: kg-pods-grep pattern [...]' && return 1
      local patterns=
      while [[ -n "$1" ]]; do patterns="$patterns|$1"; shift; done
      qeval "kg-pods | egrep '^NAME $patterns' | egrep -v 'Completed'"
    }
    alias kgp-grep='kg-pods-grep'

    
    # delete all pods for app $1      
    k-deletepods--app() {
      [[ -z "$1" ]] && eecho 'usage: k-deletepods--app app [kubectl_opts ...]' && return 1
      local app="$1" && shift
      eeval kubectl delete pods -l "app=$app" "$@"
    }
    
    k-logs--app() {
      [[ -z "$1" ]] && eecho "usage: k-logs--app app [kubectl_opts ...]" && return 1
      local app="$1" && shift
      local now="$(date +'%Y%m%d_%H%M%S')"
      local ns="$(kubens --current)"
      eeval "kubectl logs -l app=$app --tail -1 $@" \
        "| grep -E '^\{'" \
        "| tee $ns-$app.$now.FULL.log.json" \
        "| jq '{timestamp, logger, thread, level, message}'" \
        " > $ns-$app.$now.log.json"
      ls -pghF "$ns-$app.${now:0:8}_"*
    }

    .setup-kube-prompt() {
      .tick_bp "[start ] .setup-kube-prompt"
      if [[ ! -e "${kube_ps1_sh:=/usr/local/opt/kube-ps1/share/kube-ps1.sh}" ]]; then
        .tick_bp "[finish] .setup-kube-prompt: $kube_ps1_sh: File not found" && return 0
      else
        . "$kube_ps1_sh" || .tick_bp "!!! failed to source $kube_ps1_sh"
      fi
      .tick_bp "[finish] .setup-kube-prompt"
    }
    .setup-kube-prompt

    .tick_bp '[finish] .setup-kubectl'
  }
  .setup-kubectl


