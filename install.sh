#!/bin/sh
set -eu

INSTALL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NETLAB_INSTALL_ROOT=$INSTALL_ROOT
PATH="$INSTALL_ROOT/bin:$PATH"
NETLAB_ROOT=${NETLAB_ROOT:-/run/polylinux-networking}
USER_ID=${USER_ID:-student@example.edu}
CURRENT_DATE=${CURRENT_DATE:-$(date +%Y-%m-%d)}
SYSTEM_PASSWORD=${SYSTEM_PASSWORD:-systemPassword}
LEVEL_PASSWORD_ROOT=${LEVEL_PASSWORD_ROOT:-levelPassword}
export INSTALL_ROOT NETLAB_INSTALL_ROOT NETLAB_ROOT PATH
export USER_ID CURRENT_DATE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT

. "$INSTALL_ROOT/resources.sh"
USER_ID=$(normalize_email "$USER_ID")
export USER_ID
chmod 755 "$INSTALL_ROOT/labctl" "$INSTALL_ROOT/nextlevel" \
    "$INSTALL_ROOT/prevlevel" "$INSTALL_ROOT/bin/udhcpc" \
    "$INSTALL_ROOT/dhcp-client.sh"

mode=live
for argument in "$@"; do
    case "$argument" in
        --dry-run) mode=dry ;;
        --live|--non-interactive|--no-login) ;;
        *) die "unknown option: $argument" ;;
    esac
done

validate_email "$USER_ID" || die 'USER_ID must be a complete email address'
validate_date "$CURRENT_DATE" || die 'CURRENT_DATE must be YYYY-MM-DD'
for command in awk cat cut date grep mkdir printf sed sha256sum tr; do need "$command"; done

if [ "$mode" = live ]; then
    [ "$(id -u)" -eq 0 ] || die 'live installation requires root inside the disposable guest'
    for command in busybox curl dnsmasq ip nslookup ping ss traceroute udhcpc; do
        need "$command"
    done
    busybox --list | grep -qx httpd || die 'BusyBox httpd applet is required'
    [ -d /proc/sys/net/ipv4 ] || die 'IPv4 kernel support is required'
    case "$NETLAB_ROOT" in
        /run/polylinux-networking|/tmp/polylinux-networking-prototype) ;;
        *) die 'live NETLAB_ROOT must be a recognized disposable path' ;;
    esac
fi

mkdir -p "$NETLAB_ROOT/home"
for number in 1 2 3 4 5 6 7 8 9 10; do
    sh "$INSTALL_ROOT/level$number.sh"
done

if [ "$mode" = dry ]; then
    printf 'Generated ten deterministic level instructions in %s/home.\n' "$NETLAB_ROOT"
    exit 0
fi

. "$INSTALL_ROOT/topology.sh"
setup_topology
printf 'Networking prototype is ready. Enter Level 1 with:\n'
printf '  sh %s/labctl enter 1\n' "$INSTALL_ROOT"
