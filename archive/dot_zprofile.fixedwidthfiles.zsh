#!/usr/bin/env zsh

#
### fixed-width file helpers
#
# Record lengths along with count of each length, in the same sequence as file.
record-lengths() {
  [[ -z "$1" ]] && >&2 echo "usage: record-lengths file [...]" && return 1
  local files=$@
  for f in $files; do
    printf "%s\n  %s\n" "$f" "$(awk '{print length($0)}' "$f" | sort -n | uniq -c)"
  done
}
alias recl='qeval record-lengths'
#
# View a fix-width file in a more human-readable format.
fwf-nice() {
  local USAGE="usage: fwf-nice [-d delim] file [col-expr [...]"
  local delim='|'; [[ "$1" =~ ^-d|--delim$ ]] && delim="$2" && shift 2
  local is_pipe=; [[ ! -t 0 ]] && is_pipe=1
  
  local fwf=; ! ((is_pipe)) && fwf="$1" && shift
  # [[ -z "$fwf" ]] && echo-error "$USAGE" && return 1
  ! ((is_pipe)) && [[ ! -f "$fwf" ]] && echo-error "fwf-nice: $fwf: No such file" && return 1
  local c='print ' first=1
  while true; do
    local cr=0
    [[ "$1" = "CR" ]] && cr=1 && shift 1
    [[ -z "$1" || -z "$2" ]] && break
    local pos=$1 len=$2; shift 2
    if ((first)); then
      c="print substr(\$0, $pos, $len)"
      first=0
    elif ((cr)); then
      c="$c \"\n\" substr(\$0, $pos, $len)"
    else
      c="$c \"$delim\" substr(\$0, $pos, $len)"
    fi
  done
  ((is_pipe)) && awk "{$c}" || awk "{$c}" "$fwf"
}
