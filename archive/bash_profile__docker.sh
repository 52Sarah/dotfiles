#
  ### DOCKER
  #
  .setup-docker() {
    .tick_bpu '[start ] .setup-docker'
    ! type -t docker >&/dev/null && .tick_bpu "[finish] .setup-docker: docker not installed" && return 0
    alias d='docker'
    d-lsc() { qeval docker container ls --all --format "'table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}\t{{.Networks}}\\t{{.Ports}}'" $@; }
    d-lsi() { qeval docker image ls --all --format "'table {{.ID}}\\t{{.Image}}\\t{{.CreatedAt}}\\t{{.Size}}\\t{{.Networks}}\\t{{.Ports}}'" $@; }
  }
  .setup-docker

