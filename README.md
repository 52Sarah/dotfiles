# dotfiles README

At startup, standard Zsh reads in order from:
  1. ~/.zshenv
  2. ~/.zprofile for login shells
  3. ~/.zshrc for interactive shells
  4. ~/.zlogin for login shells
See: https://zsh.sourceforge.io/Doc/Release/Files.html

## overview

These startup files are intended to support Zsh or Bash, and to provide for easily enabling
only certain functionality depending on the tools installed/configured. They also provide for
configurable logging at login, as well as quiet/verbose/debugging output.

It is expected that symlinks in $HOME will link to these dotfiles. Only files needed for the
current setup should be symlinked. Files follow this convention:
  * `.sh_bootstrap*` are shell-agnostic and are read at the top of the corresponding `.z*` file
  * `.tick*` are files controlling startup file tracing and logging
  * `.z*` files will be symlinked to the proper dotfile in this repo


## environment variables and files

The dotfile scripts can be controlled without modifying the files themselves for most common
use cases. Generally this is done by setting environment files and creating indicator files i ~.

### environment variables

Checked in ~/.sh_bootstrap:
  - `_DOT_MTIMES_IGNORE`: if 1 then `dot-ok-to-skip` will always return false
  - `_DEBUG`, `_VERBOSE`, `_QUIET`: used to control echo/printf/eval helpers, set to 1 if enabled

Checked in ~/.sh_bootstrap_login:
  - `_DOT_SKIP_HOMEBREW_SETUP`
  - `_DOT_SKIP_ITERM_SETUP`
  - `_DOT_SKIP_JENV_SETUP`
  - `_DOT_SKIP_PIPENV_SETUP`
  - `_DOT_SKIP_POSTGRES_SETUP`
  - `_DOT_SKIP_RANCHER_DESKTOP_SETUP`
  - `_DOT_SKIP_SCHEMASPY_SETUP`
  - `_DOT_SKIP_SDKMAN_SETUP`

Used in multiple files:
  - `_DOT_MTIMES` is the associative array used to hold mtimes

Used internally in .tick.sh:
  - `_TICK_LAST_MS` - used to determine gap between calls to .tick
  - `_TICK_INDENT` - indents at [start] lines, outdents at [end]/[finish] lines


### indicator files


## startup file loading

The startup dotfiles are executed in this fashion, building on the standard startup files:
  
### ~/.zshenv
  - can set any of the environment variables used in other start scripts (e.g., TICK_STDERR)
  
### ~/.zprofile for login shells
  - checks mtime staleness
  - reads ~/.sh_rcprofile
      - reads ~/.sh_rcrc
          - reads ~/.sh_bootstrap
  - lazily loads tick 
  - reads ~/.zshrc
  - [other loading, setup and initialization as needed]
  - at end: loads any ~/.zprofile.* files, saves mtime
  
### ~/.zshrc for interactive shells
  - reads ~/.sh_rcrc
      - reads ~/.sh_bootstrap
  - checks mtime staleness
  - lazily loads tick
  - reads ~/.secrets, if it exists
  - [other loading, setup and initialization as needed]
  - at end: loads any ~/.zshrc.* files, saves mtime
  
### ~/.zlogin for login shells
  - reads ~/.sh_bootstrap_login
      - reads ~/.sh_bootstrap
  - checks mtime staleness
  - lazily loads tick
  - initializes oh-my-sh if desired
  - [other login setup]
  - at end: loads any ~/.zlogin.* files, saves mtime

## bootstrap files

The main dotfiles make use of several "bootstrap" files, as noted above.

### ~/.sh_bootstrap

Shell-agnostic pre-bootstrap functions for all login shells. 
Functions defined here should not depend on any other startup files.
No references to tick logging in this file.

  - initializes mtime staleness map and related functions: `dot-ok-to-skip` and `dot-store-mtime`
  - checks its own mtime staleness
  - defines following shell functions:
      - is-zsh
      - is-macos, is-cygwin, is-ubuntu, is-centos, is-amazon
      - commands to check "echo log level": `_debug`, `_verbose`, `_quiet`
      - echo-stderr, printf-stderr
      - "echo if" commands: echo-debug, echo-verbose, echo-quiet
      - "printf if" commands: printf-debug, printf-verbose, printf-quiet
      - shell agnostic regex match: matches
      - "echo and evaluate" commands: eval-echo, eval-debug, eval-verbose, eval-quiet
      - string helpers: substring, substring-before-first, etc.
      - is-command
      - safe-source
      - path-append, path-prepend
      - glob-path-count, glob-path-exists, glob-path-first
      - .reload-shell (first clears mtimes)
      - source-extra-dot-files (sources any files with given prefix)
  - at end: loads any ~/.sh_bootstrap.* files, saves mtime

### ~/.sh_rcprofile

Shell-agnostic bootstrap functions for all login shells.

  - checks mtime staleness
  - reads ~/.sh_rcrc
  - lazily loads tick
  - [other login bootstrap setup]

### ~/.sh_rcrc

Shell-agnostic bootstrap functions for interactive shells.
Functions defined here should not depend on only ~/.sh_bootstrap.
No references to tick logging in this file.

  - reads ~/.sh_bootstrap
  - checks mtime staleness
  - defines following shell functions:
      - echo-status, echo-unescape, echo-variables, echo-glob
      - du-dir (uses `find` to better control `du`)
      - array/lines functions: join-array, uniq-array, join-lines, splt-lines
      - path-list
      - string helpers: ends-with, starts-with, trim, rtrim, ltrim, upper, lower
      - path helpers: tilde-compress, tilde-expand, home-compress, home-expand
  - at end: loads any ~/.sh_rcrc.* files, saves mtime

### ~/.sh_bootstrap_login

Shell-agnostic bootstrap functions and aliases for login shells.

  - reads ~/.sh_bootstrap
  - checks mtime staleness
  - lazily loads tick
  - defines:
      - LESS, LESSEDIT; l, less-trunc
      - HISTCONTROL, HISTSIZE, HISTFILESIZE
      - EDITOR
      - CLICOLOR, CLICOLOR_FORCE
      - ack helpers: ack-help-types, ack-java
      - cd helper: cd-ln
      - chmod helper: chx
      - ls helpers
      - nc helper: ncz
      - ps helpers: ps-grep, ps-java, ps-java-pid-class, ps-ports*
      - tail helpers: t, tf
      - term-wrap, term-trunc, echo-color
      - touch helpers: touchd, touchd-R
      - ln-valid
  - initializes tools:
      - .setup-homebrew
      - .setup-iterm
      - .setup-java-sdkman
      - .setup-java-jenv
      - .setup-pg
      - .setup-schemaspy
  - at end: loads any ~/.sh_bootstrap_login_.* files, saves mtime

### lazy reading

Each file is intended to have as few dependencies on the others as possible. This allows
for simpler setups to possible omit certain files from startup.

Care is taken to avoid extraneous executions, by checking the file's mtime against the 
mtime of the file when last read. This allows, for example. .zprofile to read
.zshrc without worrying about triggering a recursion or needless re-loading. The `_DOT_MTIMES`
associative array stores the mtimes.

The .reload-* functions will always force a reload by removing the mtime for the specified file.

### "tick" logging

To facilitate tracing and troubleshooting login without cluttering the console, the .tick subsystem provides configurable logging.

It can be controlled with the following variables and/or marker files.
As soon as the first match is found, .tick will stop looking.
  - ~/.tick.disabled - globally disable
  - ~/.tick.enabled - globally enable
  - ~/.tick.stdout - globally enable and echo all lines to stdout
  - ~/.tick.stderr - globally enable and echo all lines to stderr
