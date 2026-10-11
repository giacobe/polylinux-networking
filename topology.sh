#!/bin/sh
# Live, isolated Linux networking fixtures. Source after resources.sh.

all_namespace_names() {
    for number in 1 2 3 4 5 6 7 8 9 10; do
        learner_ns "$number"
        [ "$number" -eq 9 ] || peer_ns "$number"
    done
    for number in 1 2 3 4 5 6 7 8; do router_ns "$number"; done
    printf 'pln-d9\n'
}

teardown_topology() {
    current=$(ip netns identify "$$" 2>/dev/null || true)
    case "$current" in pln-*) die 'leave the lab namespace before resetting it' ;; esac
    for ns in $(all_namespace_names); do
        if ip netns list | grep -q "^$ns\([[:space:]]\|$\)"; then
            for pid in $(ip netns pids "$ns"); do kill "$pid" 2>/dev/null || true; done
            ip netns del "$ns" || die "could not remove lab namespace $ns"
        fi
        if [ -f "/etc/netns/$ns/resolv.conf" ]; then
            rm -f "/etc/netns/$ns/resolv.conf"
            rmdir "/etc/netns/$ns" 2>/dev/null || true
        fi
    done
}

set_resolver() {
    ns=$1
    server=$2
    mkdir -p "/etc/netns/$ns"
    printf 'nameserver %s\n' "$server" > "/etc/netns/$ns/resolv.conf"
}

start_dnsmasq() {
    ns=$1
    config=$2
    ip netns exec "$ns" dnsmasq --conf-file="$config" ||
        die "dnsmasq failed in $ns"
}

start_httpd() {
    ns=$1
    bind=$2
    port=$3
    webroot=$4
    log=$5
    ip netns exec "$ns" busybox httpd -f -p "$bind:$port" -h "$webroot" > "$log" 2>&1 &
    http_pid=$!
    sleep 1
    kill -0 "$http_pid" 2>/dev/null || die "HTTP server failed in $ns; see $log"
}

setup_basic_level() {
    number=$1
    level_values "$number"
    learner=$(learner_ns "$number")
    peer=$(peer_ns "$number")
    gateway="192.0.2.$GATEWAY_OCTET"

    ip netns add "$learner"
    ip netns add "$peer"
    ip link add "$IFACE" type veth peer name peer0
    ip link set "$IFACE" netns "$learner"
    ip link set peer0 netns "$peer"
    ip -n "$learner" link set lo up
    ip -n "$peer" link set lo up
    case "$number" in
        3) ip -n "$peer" addr add "198.51.100.2/$L3_PREFIX" dev peer0 ;;
        4) ip -n "$peer" addr add "$L4_BASE.194/27" dev peer0 ;;
        *) ip -n "$peer" addr add "$gateway/24" dev peer0 ;;
    esac
    ip -n "$peer" link set peer0 up

    if [ "$number" -eq 7 ]; then
        ip -n "$learner" link set dev "$IFACE" address "$CLIENT_MAC"
    fi
    if [ "$number" -ne 1 ]; then ip -n "$learner" link set "$IFACE" up; fi
    case "$number" in
        5|6|8|10)
            ip -n "$learner" addr add "192.0.2.$HOST_OCTET/24" dev "$IFACE"
            ;;
    esac

    case "$number" in
        6)
            set_resolver "$learner" 192.0.2.254
            cat > "$NETLAB_ROOT/dns/level6.conf" <<EOF
no-resolv
no-hosts
bind-interfaces
interface=peer0
host-record=$DNS_NAME,198.51.100.$SERVICE_OCTET
pid-file=$NETLAB_ROOT/pids/dns6.pid
EOF
            start_dnsmasq "$peer" "$NETLAB_ROOT/dns/level6.conf"
            ;;
        7)
            set_resolver "$learner" 192.0.2.254
            cat > "$NETLAB_ROOT/dns/level7.conf" <<EOF
port=0
no-resolv
no-hosts
bind-interfaces
interface=peer0
dhcp-authoritative
dhcp-range=192.0.2.20,192.0.2.220,255.255.255.0,12h
dhcp-host=$CLIENT_MAC,192.0.2.$LEASE_OCTET
dhcp-option=option:router,$gateway
dhcp-option=option:dns-server,$gateway
dhcp-leasefile=$NETLAB_ROOT/dns/level7.leases
pid-file=$NETLAB_ROOT/pids/dns7.pid
EOF
            start_dnsmasq "$peer" "$NETLAB_ROOT/dns/level7.conf"
            ;;
        8)
            mkdir -p "$NETLAB_ROOT/web/level8"
            printf 'PolyLinux local service\n' > "$NETLAB_ROOT/web/level8/index.html"
            start_httpd "$learner" 127.0.0.1 "$PORT" \
                "$NETLAB_ROOT/web/level8" "$NETLAB_ROOT/logs/http8.log"
            ;;
        10)
            set_resolver "$learner" "$gateway"
            ip -n "$learner" route add default via "$gateway" dev "$IFACE"
            cat > "$NETLAB_ROOT/dns/level10.conf" <<EOF
no-resolv
no-hosts
bind-interfaces
interface=peer0
host-record=$DNS_NAME,$gateway
pid-file=$NETLAB_ROOT/pids/dns10.pid
EOF
            start_dnsmasq "$peer" "$NETLAB_ROOT/dns/level10.conf"
            mkdir -p "$NETLAB_ROOT/web/level10"
            printf '%s\n' "$CODE" > "$NETLAB_ROOT/web/level10/code.txt"
            start_httpd "$peer" "$gateway" "$PORT" \
                "$NETLAB_ROOT/web/level10" "$NETLAB_ROOT/logs/http10.log"
            ;;
    esac
}

story_dns_record() {
    story_name=$1
    story_hop=$2
    ingress=$((4 * (story_hop - 1) + 2))
    printf 'host-record=%s,198.51.100.%s\n' "$story_name" "$ingress" >> "$story_config"
    if [ "$story_hop" -lt 9 ]; then
        outgoing=$((4 * story_hop + 1))
        printf 'ptr-record=%s.100.51.198.in-addr.arpa,%s\n' \
            "$outgoing" "$story_name" >> "$story_config"
    fi
}

write_story_dns() {
    level_values 9
    story_config="$NETLAB_ROOT/dns/level9.conf"
    cat > "$story_config" <<EOF
no-resolv
no-hosts
bind-interfaces
interface=e0b
address=/trace.lab.test/198.51.100.34
pid-file=$NETLAB_ROOT/pids/dns9.pid
EOF
    lyric_number=0
    hop=0
    while IFS= read -r lyric_name; do
        lyric_number=$((lyric_number + 1))
        hop=$((hop + 1))
        story_dns_record "$lyric_name" "$hop"
        if [ "$lyric_number" -eq "$INSERT_AFTER" ]; then
            hop=$((hop + 1))
            story_dns_record "polylab.code.$CODE.alma.lab.test" "$hop"
        fi
    done < "$INSTALL_ROOT/data/alma-hop-hostnames.txt"
    [ "$lyric_number" -eq 8 ] && [ "$hop" -eq 9 ] || die 'story requires eight lyric hops and one code hop'
}

setup_story_level() {
    learner=$(learner_ns 9)
    ip netns add "$learner"
    for number in 1 2 3 4 5 6 7 8; do ip netns add "$(router_ns "$number")"; done
    ip netns add pln-d9
    for number in 0 1 2 3 4 5 6 7 8; do
        if [ "$number" -eq 0 ]; then left_ns=$learner
        else left_ns=$(router_ns "$number"); fi
        if [ "$number" -eq 8 ]; then right_ns=pln-d9
        else right_ns=$(router_ns "$((number + 1))"); fi
        left_if="e${number}a"
        right_if="e${number}b"
        first=$((4 * number + 1))
        second=$((first + 1))
        ip link add "$left_if" type veth peer name "$right_if"
        ip link set "$left_if" netns "$left_ns"
        ip link set "$right_if" netns "$right_ns"
        ip -n "$left_ns" addr add "198.51.100.$first/30" dev "$left_if"
        ip -n "$right_ns" addr add "198.51.100.$second/30" dev "$right_if"
        ip -n "$left_ns" link set "$left_if" up
        ip -n "$right_ns" link set "$right_if" up
    done
    for ns in $(all_namespace_names); do
        case "$ns" in pln-l9|pln-r9-*|pln-d9) ip -n "$ns" link set lo up ;; esac
    done
    for number in 1 2 3 4 5 6 7 8; do
        ns=$(router_ns "$number")
        next=$((4 * number + 2))
        ip -n "$ns" route add default via "198.51.100.$next" dev "e${number}a"
        if [ "$number" -gt 1 ]; then
            previous=$((4 * (number - 1) + 1))
            ip -n "$ns" route add 198.51.100.0/30 via \
                "198.51.100.$previous" dev "e$((number - 1))b"
        fi
        ip netns exec "$ns" sh -c 'printf 1 > /proc/sys/net/ipv4/ip_forward'
    done
    ip -n pln-d9 route add default via 198.51.100.33 dev e8b
    set_resolver "$learner" 198.51.100.2
    write_story_dns
    start_dnsmasq "$(router_ns 1)" "$NETLAB_ROOT/dns/level9.conf"
}

setup_topology() {
    mkdir -p "$NETLAB_ROOT/dns" "$NETLAB_ROOT/pids" \
        "$NETLAB_ROOT/logs" "$NETLAB_ROOT/web"
    teardown_topology
    for number in 1 2 3 4 5 6 7 8 10; do setup_basic_level "$number"; done
    setup_story_level
}
