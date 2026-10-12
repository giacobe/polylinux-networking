#!/bin/sh
# Buildroot root login starts the exercise automatically.
[ "$(id -u)" -eq 0 ] || return 0
cd /root || exit 1
exec sh /root/install.sh
