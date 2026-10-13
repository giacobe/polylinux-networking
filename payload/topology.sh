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

    ip netns add "$peer"
    left_temp="plna$number"
    right_temp="plnb$number"
    ip link add "$left_temp" type veth peer name "$right_temp"
    ip link set "$left_temp" netns "$learner"
    ip link set "$right_temp" netns "$peer"
    ip -n "$learner" link set "$left_temp" name "$IFACE"
    ip -n "$peer" link set "$right_temp" name peer0
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
            chown level6:level6 "/etc/netns/$learner/resolv.conf"
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
    if [ "$story_hop" -eq 1 ]; then
        ingress=1
    else
        ingress=$((4 * (story_hop - 1) + 2))
    fi
    printf 'host-record=%s,198.51.100.%s\n' "$story_name" "$ingress" >> "$story_config"
}

story_link_delay_ms() {
    link=$1
    value=$(derive_byte "story-link-delay-$link")
    printf '%s\n' "$((10 + value % 191))"
}

story_variant_filename() {
    case "$1" in
        0) printf 'alma-opening.txt\n' ;;
        1) printf 'alma-middle.txt\n' ;;
        2) printf 'nittany-opening.txt\n' ;;
        3) printf 'nittany-chorus.txt\n' ;;
        4) printf 'fight-on-state.txt\n' ;;
        5) printf 'victory-refrain.txt\n' ;;
        *) die "unknown story variant: $1" ;;
    esac
}

write_story_dns() {
    level_values 9
    story_variant=$(( $(derive_byte story-variant) % 6 ))
    story_file="$INSTALL_ROOT/data/story-hop-hostnames/$(story_variant_filename "$story_variant")"
    [ -f "$story_file" ] || die "missing story variant: $story_file"
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
            story_dns_record "polylab.code.$CODE" "$hop"
        fi
    done < "$story_file"
    [ "$lyric_number" -eq 8 ] && [ "$hop" -eq 9 ] || die 'story requires eight lyric hops and one code hop'
}

setup_story_level() {
    level_values 9
    learner=$(learner_ns 9)
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
        if [ "$number" -eq 0 ]; then
            left_address=$second
            right_address=$first
        else
            left_address=$first
            right_address=$second
        fi
        ip link add "$left_if" type veth peer name "$right_if"
        ip link set "$left_if" netns "$left_ns"
        ip link set "$right_if" netns "$right_ns"
        ip -n "$left_ns" addr add "198.51.100.$left_address/30" dev "$left_if"
        ip -n "$right_ns" addr add "198.51.100.$right_address/30" dev "$right_if"
        ip -n "$left_ns" link set "$left_if" up
        ip -n "$right_ns" link set "$right_if" up
        delay=$(story_link_delay_ms "$number")
        forward_delay=$((delay / 2))
        return_delay=$((delay - forward_delay))
        ip netns exec "$left_ns" tc qdisc add dev "$left_if" root netem delay "${forward_delay}ms"
        ip netns exec "$right_ns" tc qdisc add dev "$right_if" root netem delay "${return_delay}ms"
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
    set_resolver "$learner" 198.51.100.1
    write_story_dns
    start_dnsmasq "$(router_ns 1)" "$NETLAB_ROOT/dns/level9.conf"
}

prepare_topology() {
    teardown_topology
    mkdir -p "$NETLAB_ROOT/dns" "$NETLAB_ROOT/pids" \
        "$NETLAB_ROOT/logs" "$NETLAB_ROOT/web"
    for number in 1 2 3 4 5 6 7 8 9 10; do
        ns=$(learner_ns "$number")
        ip netns add "$ns"
        ip -n "$ns" link set lo up
    done
}
