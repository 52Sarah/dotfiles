#!/usr/bin/env bash

. "$HOME/.__login.debug" ".bashrc__cat" || __echo() { :; }
__echo "[.bashrc__cat] starting; pid: $$, PS1='$PS1'"


# cat blocks iCloud
unset ICLOUD


# Set artifactory credentials using API key
export JFROG_USER="pierzt"
export JFROG_PASS="AKCp8hyineL9ZM3D5v1ZAfiiyfz6sU3REY5HtPpuZMbH2A7aY6iq6YPvyQQU2bAq4oJModRk3"


# Default Spring profile
export spring_profiles_active=local,localer


__echo "[.bashrc__cat] finished"
