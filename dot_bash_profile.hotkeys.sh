#!/usr/bin/env bash

# @  =  ⌘ command
# ~  =  ⌥ option
# ^  =  ⌃ control
# $  =  shift
#
# \\U21a9  =  ↩︎  return
#
# \\U2191  =  ▲  up arrow 
# \\U2193  =  ▼  down arrow 
#
# \\Uf70a  =  F7

# Create a shell script with commands needed to re-create all current hotkeys
# defined in the Keyboard prefs pane, App Shortcuts.
hotkeys-export() {

  print-usage() {
    [[ "$1" ]] && eecho "$*"
    eecho 'usage: hotkeys-export [-v|-q] [--raw] [out_file]'
    eecho '       Default out_file is hotkeys-YYYYMMDD.sh'
    return 1
  }
  local _QUIET=$! _quiet_on _VERBOSE=$((_VERBOSE))
  while [[ "$1" ]]; do case "$1" in
    --quiet|-q)   _QUIET=$1; shift;;
    --verbose|-v) _VERBOSE=$1; shift;;
    -*) print-usage "invalid option: $1";;
    *) break;;
  esac; done

  local out_file="$1"; [[ -z "$out_file" ]] && out_file="mac-hotkeys-$(date +'%F').sh"

  echo '#!/usr/bin/env bash' > "$out_file"
  echo_unquiet "$EVAL_ECHO_PREFIX defaults find NSUserKeyEquivalents"
  defaults find NSUserKeyEquivalents | \
  sed \
  -e "s/Found [0-9]* keys in domain '\\([^']*\\)':/defaults write \\1 NSUserKeyEquivalents '/" \
  -e "s/    NSUserKeyEquivalents =     {//" \
  -e "s/};//" -e "s/}/}'/" >> "$out_file"
  echo "killall cfprefsd" >> "$out_file"

  # Skip if out_file is /dev/stdout or a pipe.
  if [[ -f "$out_file" ]]; then
    eval-quiet chmod +x "$out_file"
    echo_unquiet "Wrote $(egrep -E -c '=.+;$' "$out_file") key mappings to $out_file"
  fi
}

# Print human-friendly list of Mac App Shortcuts.
hotkeys-list() {

  print-usage() {
    [[ "$1" ]] && eecho "$*"
    eecho 'usage: hotkeys-export [-v|-q|-r]'
    return 1
  }
  local _QUIET=$! _quiet_on _VERBOSE=$((_VERBOSE)) opt_raw=
  while [[ "$1" ]]; do case "$1" in
    --quiet|-q)   _QUIET=$1; shift;;
    --verbose|-v) _VERBOSE=$1; shift;;
    --raw|-r)     opt_raw=1; shift;;
    -*) print-usage "invalid option: $1";;
    *) break;;
  esac; done

  if ((opt_raw)); then
    defaults find NSUserKeyEquivalents
  else
    defaults find NSUserKeyEquivalents | sed -E \
      -e '/^Found|[^}];$/! d' \
      -e 's/"\\033/"/' \
      -e 's/\\033/ -> /g' \
      -e 's/[";]//g' \
      -e "s/Found 1 keys in domain \'(.+)\': \{/\\1/" \
      -e 's/@/[⌘]+/' \
      -e 's/~/[⌥]+/' \
      -e 's/\^/[^]+/' \
      -e 's/\$/[Shift]+/' \
      -e 's/\\\\U2026/.../' \
      -e 's/\\\\U21a9/\[Return]/' \
      -e 's/\\\\Uf70a/[F7]/' \
    |\
    awk -F '=' '{ printf "%-60s %s\n", $1, substr($2,1,length($2)-1) toupper(substr($2,length($2))); }'
  fi
}

# _hotkeys_domains="global beyondcompare calendar contacts dupin excel finder iterm2 keyboardmaestro music preview"

# # usage: hotkeys-define [-v|-q] [domain...]
# hotkeys-define() {
#   vprintf 'hotkeys-define: start: "%s"\n' "$*"
#   parse-verbose-quiet $@ || shift $?

#   local target_domains="${@:-$_hotkeys_domains}"

#   local d full_domain d_total=0 d_count=0
#   for d in $target_domains; do
#     ((d_total++))
#     full_domain="$(hotkeys-domain "$d")"
#     if _write_one_domain "$full_domain"; then
#       ((d_count++))
#       ((!_QUIET)) && hotkeys-list "$full_domain"
#     fi
#   done

#   ! ((d_count)) && eecho "hotkeys-define: error: all $d_total_domains hotkey domains failed" && return 1
#   local sw_verbose= && ((_VERBOSE)) && sw_verbose='-v'
#   killall $sw_verbose cfprefsd

#   ((d_count < d_total)) && eecho "hotkeys-define: error: only defined hotkeys for $d_count/$d_total domains" && return 1
#   return 0
# }

# Given $1...
# - abbreviation for app's domain, return full NSUserKeyEquivalents domain string
# - unrecognized abbreviation, $1 as-is
hotkeys-domain() {
  [[ -z "$1" ]] && return 1

  local domain=
  local abbr="$(lower $1)" && shift
  case "$abbr" in
    *globaldomain)        domain='NSGlobalDomain' ;;
    *beyondcompare|bc)    domain='com.ScooterSoftware.BeyondCompare' ;;
    *calendar|ical)       domain='com.apple.iCal' ;;
    *contacts|addresses)  domain='com.apple.contacts' ;;
    *dupin)               domain='com.dougscripts.Dupin' ;;
    *excel)               domain='com.microsoft.Excel' ;;
    *finder)              domain='com.apple.finder' ;;
    *iterm*)              domain='com.googlecode.iterm2' ;;
    *keyboardmaestro|km)  domain='com.stairways.keyboardmaestro.editor' ;;
    *music|itunes)        domain='com.apple.Music' ;;
    *preview)             domain='com.apple.Preview' ;;
    *outlook)             domain='com.microsoft.Outlook' ;;
    *)
      vecho "hotkeys-domain: info: unrecognized domain abbreviation: $abbr; passing thru"
      domain="$abb"
      return 1;;
  esac
  
  echo "$domain"
  return 0
}

# # Given $1 is a valid defaults domain, define its hotkeys and return 0; else return 1.
# # For the rare domains with spaces in their names, replace underscores with spaces.
# _write_one_domain() {
#   vprintf '_write_one_domain: start: "%s"\n' "$*"
#   local domain="${1//_/ }" && shift
#   [[ -z "$domain" ]] && eecho "usage: _write_one_domain domain" && return 1

#   case "$domain" in

#     # APPLE GLOBAL DOMAIN
#     #
#     # [⌥]+[^]+1   Window > Move to VX228
#     # [⌥]+[^]+2   Window > Move to Thunderbolt Display
#     # [⌥]+[^]+3   Window > Move to Built-in Retina Display
#     # [⌥]+[^]+[   Window > Tile Window to Left of Screen
#     # [⌥]+[^]+]   Window > Tile Window to Right of Screen
#     #
#     NSGlobalDomain)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033Window\033Move to VX228" = "~^1";
#         "\033Window\033Move to Thunderbolt Display" = "~^2";
#         "\033Window\033Move to Built-in Retina Display" = "~^3";
#         "\033Window\033Move Window to Left Side of Screen" = "~^[";
#         "\033Window\033Move Window to Right Side of Screen" = "~^]";
#         "\033Window\033Tile Window to Left of Screen" = "~^$[";
#         "\033Window\033Tile Window to Right of Screen" = "~^$]";
#       }'
#       return 0;;

#     # BEYOND COMPARE
#     #
#     # [⌘]+[Shift]+O   Actions > Open
#     # [⌘]+O           A       > Open With > Associated Application
#     # [⌘]+B           A       > Set as Base Folder
#     # [⌘]+[Shift]+B   A       > Set as Base Folders
#     # [⌘]+[^]+C       A       > Compare Contents
#     # [^]+L           A       > Copy to Left
#     # [^]+R           A       > Copy to Right
#     # [⌘]+[⌥]+T       A       > Touch...
#     # [⌘]+[⌥]+X       A       > Exclude
#     # [⌘]+[Shift]+=   Edit > Expand All
#     # [⌘]+[Shift]+-   E    > Collapse All
#     # F7              Search > Next Difference
#     # [Shift]+F7      S      > Previous Difference
#     #
#     com.ScooterSoftware.BeyondCompare)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033Session\033Session Settings..." = "@~,";

#         "\033Actions\033Open" = "@$o";
#         "\033Actions\033Open With\033Associated Application" = "@o";
#         "\033Actions\033Set as Base Folder" = "@b";
#         "\033Actions\033Set as Base Folders" = "@$b";
#         "\033Actions\033Compare Contents" = "@^c";
#         "\033Actions\033Copy to Left" = "^l";
#         "\033Actions\033Copy to Right" = "^r";
#         "\033Actions\033Touch..." = "@~t";
#         "\033Actions\033Exclude" = "@~x";

#         "\033Edit\033Expand All" = "@$=";
#         "\033Edit\033Collapse All" = "@$-";
#       }'
#       return 0;;

#         # 5/5 these were interpreted as the actual keystroke "U".
#         # "\033Search\033Next Difference" = "\\Uf70a";
#         # "\033Search\033Previous Difference" = "$\\Uf70a";

#     # CONTACTS
#     #
#     # [⌘]+[⌥]+S   View > Show|Hide Groups
#     #
#     com.apple.contacts)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033View\033Show Groups" = "@~s";
#         "\033View\033Hide Groups" = "@~s";
#       }'
#       return 0;;
  
#     # CALENDAR
#     #
#     # [⌘]+[⌥]+S   View > Show|Hide Calendar List
#     #
#     com.apple.iCal)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033View\033Show Calendar List" = "@~s";
#         "\033View\033Hide Calendar List" = "@~s";
#       }'
#       return 0;;
  
#     # DUPIN
#     #
#     com.dougscripts.Dupin)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033Tools\033Purge..." = "@~$p";
#         "\033Tools\033Re-Playlist..." = "@$p";
#         "\033Tools\033Remove Duplicate Entries From Playlists..." = "@$d";
#       }'
#       return 0;;
  
#     # EXCEL
#     #
#     # [⌘]+[^]+A   Format > Column -> AutoFit Selection
#     #
#     com.microsoft.Excel)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033Format\033Column\033AutoFit Selection" = "@^a";
#       }'
#       return 0;;

#     # FINDER
#     #
#     # [^]+R       File > Rename|Rename n Items...
#     #
#     com.apple.finder)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033File\033Rename Item" = "^r";
#         "\033File\033Rename 2 Items..." = "^r";
#         "\033File\033Rename 3 Items..." = "^r";
#         "\033File\033Rename 4 Items..." = "^r";
#         "\033File\033Rename 5 Items..." = "^r";
#         "\033File\033Rename 6 Items..." = "^r";
#       }'
#       return 0;;

#     # ITERM2
#     #
#     # [^]+SPACE   Session > Open Autocomplete...
#     # [⌥]+/       Session > Open Autocomplete...
#     #
#     com.googlecode.iterm2)
#       defaults write "$domain" NSUserKeyEquivalents '{
#       }'
#       return 0;;
  
#     # KEYBOARD MAESTRO
#     #
#     # [⌘]+[⌥]+X   File > Export Macros...
#     # [⌘]+[⌥]+E   View > Enable|Disable Macro|Group|Action
#     # [⌘]+[⌥]+K   Actions > Try Action
#     # [⌘]+[⌥]+H   A       > Help
#     #
#     #   [^]+R       View|Actions / Rename...
#     #   "\033View\033Rename..." = "^r";
#     #   "\033Actions\033Rename..." = "^r";
#     #
#     com.stairways.keyboardmaestro.editor)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033File\033Export Macros..." = "@~x";

#         "\033View\033Enable Action" = "@~e";
#         "\033View\033Disable Action" = "@~e";

#         "\033Actions\033Try Action" = "@~k";
#         "\033Actions\033Enable Action" = "@~e";
#         "\033Actions\033Disable Action" = "@~e";
#         "\033Actions\033Help" = "@~h";
#       }'
#       return 0;;
  
#     # MUSIC.APP
#     #
#     # [⌘]+[Shift]+N   File > New > Playlist Folder
#     # [^]+N                > N   > Playlist from Selection
#     # [^]+L           Song > Love
#     # [^]+D                > Dislike
#     # [⌘]+[Shift]+L        > Show Album in Library
#     # [⌘]+[Shift]+R   View > as Artists
#     # [⌘]+[Shift]+B        > as Albums
#     # [⌘]+[Shift]+S        > as Songs
#     # [^]+[Shift]+P   Scrpt> Append to Selected Tag
#     # [^]+[Shift]+H        > Search-Replace Tag Text
#     # [^]+[Shift]+M        > Song Title to Movement
#     # [^]+[Shift]+W        > Song Title to Work
#     #
#     com.apple.Music)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033File\033New\033Playlist Folder" = "@$n";
#         "\033File\033New\033Playlist from Selection" = "^n";
#         "\033Song\033Love" = "^l";
#         "\033Song\033Dislike" = "^d";
#         "\033Song\033Show Album in Library" = "@$l";
#         "\033View\033as Artists" = "@$r";
#         "\033View\033as Albums" = "@$b";
#         "\033View\033as Songs" = "@$s";
#         "\033Scripts\033Append to Selected Tag" = "^$p";
#         "\033Scripts\033Search-Replace Tag Text" = "^$h";
#         "\033Scripts\033Song Title to Movement" = "^$m";
#         "\033Scripts\033Song Title to Work" = "^$w";
#     }'
#     ## removed, implemented in KM:
#     ## # [⌘]+[⌥]+D            > Library > Show Duplicate|All Items
#     ## "\033File\033Library\033Show Duplicate Items" = "@~d";
#     ## "\033File\033Library\033Show All Items" = "@~d";

#     return 0;;

#     # PREVIEW
#     #
#     com.apple.Preview)
#       defaults write "$domain" NSUserKeyEquivalents '{
#         "\033File\033Move To..." = "@~s";
#         "\033File\033Rename..." = "@~s";
#       }'
#       return 0;;
  
#   # # OUTLOOK
#   # com.microsoft.Outlook)
#   #   defaults write "$domain" NSUserKeyEquivalents '{
#   #     "\033Message\033Archive" = "@$e";
#   #     "\033Tools\033Rules..." = "@$u";
#   #   }'
#   #   return 0;;

#   # # PATINA
#   # com.atek.Patina)
#   #   defaults write "$domain" NSUserKeyEquivalents '{
#   #     "\033Image\033Adjust Selection Size..." = "@~s";
#   #   }'
#   #   return 0;;

#   # # TYPORA
#   # abnerworks.Typora)
#   #   defaults write "$domain" NSUserKeyEquivalents '{
#   #   "\033Paragraph\033Ordered List" = "@$7";
#   #   "\033Paragraph\033Unordered List" = "@$8";
#   # }'
#   #   return 0;;
#   esac

#   eecho "_write_one_domain: error: unrecognized domain: $domain"
#   return 1
# }
