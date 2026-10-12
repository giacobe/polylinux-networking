#!/bin/sh
# Deterministic values shared by the prototype generators and live topology.

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command missing: $1"; }

validate_date() {
    case "$1" in ????-??-??) ;; *) return 1 ;; esac
    printf '%s' "$1" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
}

validate_email() {
    case "$1" in *@*.*) return 0 ;; *) return 1 ;; esac
}

normalize_email() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
        tr '[:upper:]' '[:lower:]'
}

prefix_for_hosts() {
    required=$1
    block=4
    prefix=30
    while [ $((block - 2)) -lt "$required" ]; do
        block=$((block * 2))
        prefix=$((prefix - 1))
    done
    printf '%s\n' "$prefix"
}

# The level seed hashes the exact concatenation, with no separators or newline.
seed_for_level() {
    LEVEL=$1
    LEVEL_SEED=$(
        printf '%s%s%s%s' "$USER_ID" "$CURRENT_DATE" \
            "$SYSTEM_PASSWORD" "${LEVEL_PASSWORD_ROOT}${LEVEL}" |
            sha256sum | cut -d ' ' -f 1
    )
    export LEVEL LEVEL_SEED
}

derive_hex() {
    printf '%s:%s' "$LEVEL_SEED" "$1" | sha256sum | cut -d ' ' -f 1
}

derive_byte() {
    byte=$(derive_hex "$1" | cut -c 1-2)
    printf '%s\n' "$((0x$byte))"
}

level_values() {
    seed_for_level "$1"
    IFACE="lan$((10 + $(derive_byte interface) % 80))"
    HOST_OCTET=$((30 + $(derive_byte host) % 170))
    GATEWAY_OCTET=$((1 + $(derive_byte gateway) % 10))
    SERVICE_OCTET=$((40 + $(derive_byte service) % 160))
    LEASE_OCTET=$((30 + $(derive_byte lease) % 170))
    PORT=$((8080 + $(derive_byte port) % 800))
    CODE=$(derive_hex code | cut -c 1-12)
    INSERT_AFTER=$((2 + $(derive_byte story-position) % 5))
    DNS_NAME="service-$(derive_hex dns-name | cut -c 1-6).lab.test"
    CLIENT_MAC="02:50:4c:$(derive_hex mac | cut -c 1-2):$(derive_hex mac | cut -c 3-4):$(derive_hex mac | cut -c 5-6)"
    L3_HOSTS=$((12 + $(derive_byte hosts) % 100))
    L3_PREFIX=$(prefix_for_hosts "$L3_HOSTS")
    if [ $(( $(derive_byte vlsm-parent) % 2 )) -eq 0 ]; then
        L4_BASE=203.0.113
    else
        L4_BASE=198.51.100
    fi
    export IFACE HOST_OCTET GATEWAY_OCTET SERVICE_OCTET LEASE_OCTET
    export PORT CODE INSERT_AFTER DNS_NAME CLIENT_MAC L3_HOSTS L3_PREFIX L4_BASE
}

learner_ns() { printf 'pln-l%s\n' "$1"; }
peer_ns() { printf 'pln-p%s\n' "$1"; }
router_ns() { printf 'pln-r9-%s\n' "$1"; }

level_home() { printf '%s/level%s\n' "$HOME_ROOT" "$1"; }

write_level_readme() {
    level_values "$1"
    home=${LEVEL_HOME:-$(level_home "$LEVEL")}
    mkdir -p "$home"
    {
        printf 'Level: level%s\n' "$LEVEL"
        printf 'PolyLinux: Networking from the Command Line\n'
        printf 'Participant: %s\n' "$USER_ID"
        printf 'Exercise code: %s\n\n' "$(printf '%s' "$CURRENT_DATE" | tr -d '-')"
        case "$LEVEL" in
            1)
                cat <<EOF
Interface state

The lab interface is down. Inspect links, bring the lab interface up, and
confirm that it reports UP. Submit its exact interface name.

Commands: ip -br link; ip link set dev INTERFACE up
Answer format: interface name, lowercase, no spaces.
EOF
                ;;
            2)
                cat <<EOF
Manual IPv4 assignment

Configure $IFACE with host number $HOST_OCTET on 192.0.2.0/24. Inspect
the result with ip -4 addr show dev $IFACE.

Answer format: IPv4/prefix, for example 192.0.2.42/24.
EOF
                ;;
            3)
                cat <<EOF
Subnet mask selection

An isolated site receives 198.51.100.0/24 and needs at least $L3_HOSTS usable
host addresses in one subnet. Choose the smallest suitable subnet, then
configure its first usable address on $IFACE. Inspect your address and mask.

Answer format: network/prefix, for example 198.51.100.0/26.
EOF
                ;;
            4)
                cat <<EOF
VLSM allocation

Allocate $L4_BASE.0/24 from the lowest addresses upward. Allocate the
largest requirement first; use the smallest suitable subnet for each.

  Research: 90 usable hosts
  Library: 50 usable hosts
  Sensors: 20 usable hosts

Configure the first usable Sensors address on $IFACE.
Answer format: Sensors network/prefix, for example $L4_BASE.192/27.
EOF
                ;;
            5)
                cat <<EOF
Default gateway

$IFACE already has a local address. The router is 192.0.2.$GATEWAY_OCTET.
Add a default route through it. Confirm the gateway with ip route and
confirm the egress path with ip route get 198.51.100.20.

Answer format: gateway IPv4 address only.
EOF
                ;;
            6)
                cat <<EOF
DNS resolver configuration

The resolver setting in this level is incorrect. Set its nameserver to
192.0.2.$GATEWAY_OCTET. Then use nslookup to resolve $DNS_NAME.

Use /etc/resolv.conf inside this level's shell; the file is isolated from
other levels. Answer format: resolved IPv4 address only.
EOF
                ;;
            7)
                cat <<EOF
DHCP versus a manual address

$IFACE starts without an address. The router offers DHCP on this link.
Run udhcpc on $IFACE, then inspect the resulting IPv4 address, default
route, and resolver. Compare them with the manual settings in Level 2.

Answer format: leased-IPv4|gateway-IPv4|DNS-IPv4, with literal pipes.
EOF
                ;;
            8)
                cat <<EOF
Local reachability and a listening service

First ping the gateway 192.0.2.$GATEWAY_OCTET. Then inspect TCP listeners
with ss -ltn. A small web service listens only on 127.0.0.1. Identify
its port, and use curl to confirm the local response.

Answer format: decimal TCP port only.
EOF
                ;;
            9)
                cat <<EOF
Traceroute and reverse DNS

The local interface e0a has 198.51.100.1/30. The next-hop router is
198.51.100.2 (not your own .1 address). Add a default route through .2,
then ping .2 and compare:

  traceroute -n trace.lab.test
  traceroute trace.lab.test

The resolver at .2 supplies full names ending in .alma.lab.test. A short
fragment such as for.the.glory is not a complete DNS name. Use nslookup
on a hop IP address to inspect its reverse DNS name if needed.

The named hops follow eight lines of Penn State's alma mater. One extra
PolyLab code line appears between the first and last lyric lines. Submit
only its code: exactly 12 lowercase hexadecimal characters.
EOF
                ;;
            10)
                cat <<EOF
Resolve and connect to an internal service

Resolve $DNS_NAME with nslookup, then request its /code.txt path on port
$PORT with curl. This service runs on the virtual peer in this VM.

Answer format: resolved-IPv4|HTTP-status|12-character-code.
EOF
                ;;
        esac
        printf '\nSubmit the level answer through the external exercise grading form.\n'
    } > "$home/README.txt"
}

# Called by each independent level script in a private staging directory.
generate_level() {
    number=$1
    if [ "${INSTALL_MODE:-dry}" = live ]; then
        . "$INSTALL_ROOT/topology.sh"
        case "$number" in
            9) setup_story_level ;;
            *) setup_basic_level "$number" ;;
        esac
    fi
    write_level_readme "$number"
}
