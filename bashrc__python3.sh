### PYTHON/PYENV
#
# Set up Python aliases if installed.
if ! type -t python &>/dev/null; then
  __echo "[.bashrc] python not installed"
else
  # Avoid pip/python version mismatch message.
  alias python='python3'
  alias pip='pip3'
  alias venv='python3 -m venv'
fi
