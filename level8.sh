#!/bin/sh
set -eu

. "$INSTALL_ROOT/polylinux-common.sh"

host="$(theme_variant host 8).lab.test"
address="192.0.2.$((20 + THEME_INDEX))"
aliases="$(theme_field service) $(theme_field project)"
{
    printf '%s %s %s\n' "$address" "$host" "$aliases"
    printf '198.51.100.40 archive.lab.test archive\n'
    printf '203.0.113.55 status.lab.test status\n'
} > "$LEVEL_HOME/hosts.snapshot"
{
    echo 'Level 8: Name Resolution'
    echo
    echo 'A service was recorded in a saved hosts table. Use grep, awk, or cut'
    echo 'to find the IPv4 address associated with the themed hostname below.'
    echo
    printf 'Hostname: %s\n' "$host"
    echo 'Data file: hosts.snapshot'
    echo 'Answer format: IPv4 address'
} >> "$readMeLocation"
