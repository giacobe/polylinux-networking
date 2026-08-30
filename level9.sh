#!/bin/sh
set -eu

. "$INSTALL_ROOT/polylinux-common.sh"

target="203.0.113.$((40 + THEME_INDEX))"
gateway="192.0.2.$((1 + THEME_INDEX))"
metric=$((100 + THEME_INDEX))
{
    echo 'default via 192.0.2.1 dev eth0 metric 100'
    printf '%s/32 via %s dev eth1 metric %s\n' "$target" "$gateway" "$metric"
    echo '198.51.100.0/24 via 192.0.2.5 dev eth0 metric 200'
    echo '192.0.2.0/24 dev eth0 scope link'
} > "$LEVEL_HOME/routes.snapshot"
{
    echo 'Level 9: Routes and Service Paths'
    echo
    echo 'Inspect the saved routing table and identify the gateway used for the'
    echo 'themed destination. The longest matching route is the correct route.'
    echo
    printf 'Destination: %s\n' "$target"
    echo 'Data file: routes.snapshot'
    echo 'Answer format: IPv4 address'
} >> "$readMeLocation"
