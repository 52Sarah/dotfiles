is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_cygwin() { [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" =~ ^cygwin.* ]]; }
is_ubuntu() { grep -s "ID=.?ubuntu.?" /etc/os-release >& /dev/null; }
is_centos() { grep -E -s "ID=.?centos.?" /etc/os-release >& /dev/null; }
is_amazon() { grep -E -s "ID=.?amzn.?" /etc/os-release >& /dev/null; }
