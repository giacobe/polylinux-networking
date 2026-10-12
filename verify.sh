#!/bin/sh
# Developer-only live reference path. Exclude this file from VM payloads.
set -eu
cd "$(dirname "$0")"
ROOT=$(pwd)
NETLAB_INSTALL_ROOT=$ROOT
PATH="$ROOT/bin:$PATH"
export NETLAB_INSTALL_ROOT PATH
NETLAB_ROOT=${NETLAB_ROOT:-/run/polylinux-networking}
HOME_ROOT=${HOME_ROOT:-/home}
export HOME_ROOT
. "$ROOT/resources.sh"

[ "$(id -u)" -eq 0 ] || die 'live reference solver requires root'
number=${1:-}
case "$number" in 1|2|3|4|5|6|7|8|9|10) ;; *) die 'usage: sh verify.sh LEVEL' ;; esac
ns=$(learner_ns "$number")
readme=$(level_home "$number")/README.txt
[ -f "$readme" ] || die "missing $readme"

interface() {
    ip -n "$ns" -o link show | sed -n 's/^[0-9][0-9]*: \(lan[0-9][0-9]*\)@.*/\1/p' | head -n 1
}

lookup_ipv4() {
    ip netns exec "$ns" nslookup "$1" |
        awk '/Address/ { for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) result=$i } END { print result }'
}

case "$number" in
    1)
        iface=$(interface)
        [ -n "$iface" ] || die 'lab interface missing'
        ip -n "$ns" link set dev "$iface" up
        ip -n "$ns" -br link show dev "$iface"
        printf '%s\n' "$iface"
        ;;
    2)
        iface=$(interface)
        octet=$(sed -n 's/.*host number \([0-9][0-9]*\) on.*/\1/p' "$readme")
        [ -n "$octet" ] || die 'Level 2 host clue missing'
        ip -n "$ns" addr replace "192.0.2.$octet/24" dev "$iface"
        ip -n "$ns" -4 -o addr show dev "$iface" | awk '$3=="inet" {print $4}'
        ;;
    3)
        iface=$(interface)
        hosts=$(sed -n 's/.*needs at least \([0-9][0-9]*\) usable.*/\1/p' "$readme")
        [ -n "$hosts" ] || die 'Level 3 host clue missing'
        block=4; prefix=30
        while [ $((block - 2)) -lt "$hosts" ]; do
            block=$((block * 2)); prefix=$((prefix - 1))
        done
        ip -n "$ns" addr replace "198.51.100.1/$prefix" dev "$iface"
        printf '198.51.100.0/%s\n' "$prefix"
        ;;
    4)
        iface=$(interface)
        base=$(sed -n 's/^Allocate \([0-9.]*\)[.]0\/24.*/\1/p' "$readme")
        [ -n "$base" ] || die 'Level 4 parent clue missing'
        ip -n "$ns" addr replace "$base.193/27" dev "$iface"
        printf '%s.192/27\n' "$base"
        ;;
    5)
        iface=$(interface)
        gateway=$(sed -n 's/.*router is \([0-9.]*\)[.]/\1/p' "$readme" | head -n 1)
        [ -n "$gateway" ] || die 'Level 5 gateway clue missing'
        ip -n "$ns" route replace default via "$gateway" dev "$iface"
        ip -n "$ns" route show default | awk '{print $3}'
        ;;
    6)
        server=$(sed -n 's/^192[.]0[.]2[.]\([0-9][0-9]*\)[.] Then.*/192.0.2.\1/p' "$readme")
        name=$(sed -n 's/.*resolve \([^[:space:]]*\)[.]/\1/p' "$readme" | head -n 1)
        [ -n "$server" ] && [ -n "$name" ] || die 'Level 6 clues missing'
        printf 'nameserver %s\n' "$server" > "/etc/netns/$ns/resolv.conf"
        lookup_ipv4 "$name"
        ;;
    7)
        iface=$(interface)
        ip netns exec "$ns" busybox udhcpc -s "$ROOT/dhcp-client.sh" -i "$iface" -n -q >/dev/null
        address=$(ip -n "$ns" -4 -o addr show dev "$iface" | awk '$3=="inet" {split($4,a,"/"); print a[1]}')
        gateway=$(ip -n "$ns" route show default | awk '{print $3}')
        server=$(awk '$1=="nameserver" {print $2; exit}' "/etc/netns/$ns/resolv.conf")
        printf '%s|%s|%s\n' "$address" "$gateway" "$server"
        ;;
    8)
        gateway=$(sed -n 's/.*gateway \([0-9][0-9.]*\)[.] Then.*/\1/p' "$readme" | head -n 1)
        ip netns exec "$ns" ping -c 1 -W 2 "$gateway" >/dev/null
        port=$(ip netns exec "$ns" ss -ltn |
            awk '$4 ~ /^127[.]0[.]0[.]1:/ {split($4,a,":"); print a[length(a)]; exit}')
        [ -n "$port" ] || die 'Level 8 listener missing'
        ip netns exec "$ns" curl -fsS "http://127.0.0.1:$port/" >/dev/null
        printf '%s\n' "$port"
        ;;
    9)
        ip -n "$ns" route replace default via 198.51.100.2 dev e0a
        ip netns exec "$ns" traceroute -m 12 -q 1 trace.lab.test |
            sed -n 's/.*polylab[.]code[.]\([0-9a-f]\{12\}\)[.]alma[.]lab[.]test.*/\1/p'
        ;;
    10)
        name=$(sed -n 's/^Resolve \([^[:space:]]*\) with.*/\1/p' "$readme")
        port=$(sed -n 's/^\([0-9][0-9]*\) with curl.*/\1/p' "$readme")
        [ -n "$name" ] && [ -n "$port" ] || die 'Level 10 clues missing'
        address=$(lookup_ipv4 "$name")
        response=$(ip netns exec "$ns" curl -sS -w '\n%{http_code}\n' \
            "http://$name:$port/code.txt")
        code=$(printf '%s\n' "$response" | head -n 1)
        status=$(printf '%s\n' "$response" | tail -n 1)
        printf '%s|%s|%s\n' "$address" "$status" "$code"
        ;;
esac
