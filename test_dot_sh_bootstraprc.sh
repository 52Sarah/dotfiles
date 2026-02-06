#!/usr/bin/env zsh

test-debug-verbose-quiet() {

  _DEBUG= _VERBOSE= _QUIET=
  echo "_DEBUG=$_DEBUG _VERBOSE=$_VERBOSE _QUIET=$_QUIET"
  _debug || echo "PASS: ! _debug"
  _verbose || echo "PASS: ! _verbose"
  _quiet || echo "PASS: ! quiet"

  _DEBUG=1 _VERBOSE= _QUIET=
  echo "_DEBUG=$_DEBUG _VERBOSE=$_VERBOSE _QUIET=$_QUIET"
  _debug && echo "PASS: _debug"
  _verbose && echo "PASS: _verbose"
  _quiet || echo "PASS: ! quiet"

  _DEBUG= _VERBOSE=1 _QUIET=
  echo "_DEBUG=$_DEBUG _VERBOSE=$_VERBOSE _QUIET=$_QUIET"
  _debug || echo "PASS: ! _debug"
  _verbose && echo "PASS: _verbose"
  _quiet || echo "PASS: ! quiet"

  _DEBUG= _VERBOSE= _QUIET=1
  echo "_DEBUG=$_DEBUG _VERBOSE=$_VERBOSE _QUIET=$_QUIET"
  _debug || echo "PASS: ! _debug"
  _verbose || echo "PASS: ! _verbose"
  _quiet && echo "PASS: quiet"
}
test-debug-verbose-quiet
