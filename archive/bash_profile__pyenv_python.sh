  #
  ### PYENV
  #
  .setup-pyenv() {
    .tick_bp '[start ] .setup-pyenv'
    ! type -t pyenv &>/dev/null && .tick_bp "[finish] .setup-pyenv: pyenv not installed" && return 0
    [[ -n "$PYENV_ROOT" && "$(type -t pyenv &>/dev/null)" == "function" ]] && .tick_bp "[finish] .setup-pyenv: pyenv already initialized" && return 0

    export PYENV_ROOT="$HOME/.pyenv"
    path-prepend "$PYENV_ROOT/bin"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    # .tick_bp -e 'echo "... using $(2>&1 pyenv -v)"'
    # .tick_bp -e 'echo "... using python version $(2>&1 pyenv version)"'
    # .tick_bp -e 'echo "... $ which python: $(2>&1 which python)"'
    # .tick_bp -e 'echo "... $ python -V: $(2>&1 python -V)"'

    # manually rehash from install location; -v for extra output
    pyenv-rehash-ln() {
      local opt_verbose=; [[ "$1" =~ -v ]] && opt_verbose='v' && shift
      ((_ECHO_V)) && opt_verbose='v'

      local py_bin="$(brew --prefix)/Cellar/python@3.9/$(pyenv version-name)/bin"
      local py_shims="$PYENV_ROOT/shims"
      local dot_py_shims="$HOME/dotfiles/pyenv_shims"
      mkdir -p$opt_verbose "$py_shims"
      for f in "$py_bin"/*; do veval ln -sf$opt_verbose "$f" "$py_shims"; done
      for f in "$dot_py_shims"/*; do
        local shim="$(sed -E 's/^pyenv_|_[^_]+_shiv\.sh$//g' <<< "$(basename $f)")"
        cp -p$opt_verbose "$f" "$py_shims/$shim"
      done
      if [[ -n "$opt_verbose" ]]; then
        eeval ll $py_shims/
        echo 'python3 ...'; which python3; python3 -V
        echo 'python ...'; which python; python -V
        echo 'pip ...'; which pip; pip -V
      fi
    }
    ((SH_LOGIN_PYENV_REASH)) && .tick_bp '... calling pyenv-rehash-ln'
    pyenv-rehash-ln
    # .tick_bp -e 'echo "... $ which python: $(2>&1 which python)"'
    # .tick_bp -e 'echo "... $ python -V: $(2>&1 python -V)"'

    .tick_bp '[finish] .setup-pyenv'
  }
  .setup-pyenv

  #
  ### PYTHON
  #
  .setup-python-pip() {
    .tick_bp '[start ] .setup-python-pip'
    ! type -t python &>/dev/null && .tick_bp '[finish] .setup-python-pip: python not installed' && return 0

    # .tick_bp -e 'echo "... using pip version $(2>&1 pip --version)"'

    export VIRTUALENVWRAPPER_PYTHON="$(which python)"
    export VIRTUALENVWRAPPER_HOOK_DIR="$HOME/.virtualenvs"

    # ! eval "$(python -m pip completion --bash)" && .tick_bp '[finish] !!! .setup-python-pip: failed to load pip completion' && return 1
    # complete -p | grep -E -q 'pip$' && .tick_bp "... loaded pip cli completion" || .tick_bp "!!! pip cli completion not loaded"

    .tick_bp '[finish] .setup-python-pip'
  }
  .setup-python-pip
