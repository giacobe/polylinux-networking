#!/bin/sh
# Root-owned sudo target; students cannot choose a DHCP hook script.
set -eu
[ "${SUDO_USER:-}" = level7 ] || exit 1
[ "$#" -eq 4 ] && [ "$1" = -i ] && [ "$3" = -n ] && [ "$4" = -q ] || exit 1
printf '%s' "$2" | grep -Eq '^lan[0-9]{2}$' || exit 1
exec busybox udhcpc -s /usr/local/libexec/polylinux-dhcp-client.sh "$@"
