#!/bin/sh
# Developer-only live validation. Run after install.sh --live in a Linux guest.
set -eu
cd "$(dirname "$0")"
INSTALL_ROOT=$(pwd)
NETLAB_ROOT=${NETLAB_ROOT:-/run/polylinux-networking}
HOME_ROOT=${HOME_ROOT:-/home}
export HOME_ROOT
USER_ID=${USER_ID:-student@example.edu}
CURRENT_DATE=${CURRENT_DATE:-$(date +%Y-%m-%d)}
SYSTEM_PASSWORD=${SYSTEM_PASSWORD:-systemPassword}
LEVEL_PASSWORD_ROOT=${LEVEL_PASSWORD_ROOT:-levelPassword}
export INSTALL_ROOT NETLAB_ROOT USER_ID CURRENT_DATE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT
. ./resources.sh

[ "$(id -u)" -eq 0 ] || die 'live-test.sh requires root'
for number in 1 2 3 4 5 6 7 8 9 10; do
    id "level$number" >/dev/null 2>&1 || die "missing level$number account"
done
for number in 1 2 3 4 5 6 7 8 9 10; do
    login_output=$(ip netns exec "pln-l$number" su - "level$number" -c \
        'ip netns identify' 2>&1) ||
        die "level$number login failed: $login_output"
    login_ns=$(printf '%s\n' "$login_output" | tail -n 1)
    [ "$login_ns" = "pln-l$number" ] ||
        die "level$number login reached the wrong namespace: $login_ns"
done
printf 'Ten account login and namespace checks passed.\n'
level_values 1
ip netns exec pln-l1 su -c "PATH=/usr/local/bin:\$PATH ip link set dev $IFACE up" level1 >/dev/null ||
    die 'Level 1 account cannot bring its interface up'
level_values 2
ip netns exec pln-l2 su -c "PATH=/usr/local/bin:\$PATH ip address add 192.0.2.$HOST_OCTET/24 dev $IFACE" level2 >/dev/null ||
    die 'Level 2 account cannot assign an address with ip address add'
level_values 3
ip netns exec pln-l3 su -c "PATH=/usr/local/bin:\$PATH ip address add 198.51.100.1/$L3_PREFIX dev $IFACE" level3 >/dev/null ||
    die 'Level 3 account cannot assign its subnet address'
level_values 4
ip netns exec pln-l4 su -c "PATH=/usr/local/bin:\$PATH ip address add $L4_BASE.193/27 dev $IFACE" level4 >/dev/null ||
    die 'Level 4 account cannot assign its VLSM address'
level_values 5
ip netns exec pln-l5 su -c "PATH=/usr/local/bin:\$PATH ip route add default via 192.0.2.$GATEWAY_OCTET dev $IFACE" level5 >/dev/null ||
    die 'Level 5 account cannot add its default route'
level_values 7
ip netns exec pln-l7 su -c "PATH=/usr/local/bin:\$PATH udhcpc -i $IFACE -n -q" level7 >/dev/null ||
    die 'Level 7 account cannot request a DHCP lease'
ip netns exec pln-l9 su -c 'PATH=/usr/local/bin:$PATH ip route replace default via 198.51.100.2 dev e0a' level9 >/dev/null ||
    die 'Level 9 account cannot configure its route through the network helper'
printf 'Learner account network-change commands passed.\n'
for number in 1 2 3 4 5 6 7 8 9 10; do
    level_values "$number"
    case "$number" in
        1) expected=$IFACE ;;
        2) expected="192.0.2.$HOST_OCTET/24" ;;
        3) expected="198.51.100.0/$L3_PREFIX" ;;
        4) expected="$L4_BASE.192/27" ;;
        5) expected="192.0.2.$GATEWAY_OCTET" ;;
        6) expected="198.51.100.$SERVICE_OCTET" ;;
        7) expected="192.0.2.$LEASE_OCTET|192.0.2.$GATEWAY_OCTET|192.0.2.$GATEWAY_OCTET" ;;
        8) expected=$PORT ;;
        9) expected=$CODE ;;
        10) expected="192.0.2.$GATEWAY_OCTET|200|$CODE" ;;
    esac
    actual=$(sh "$INSTALL_ROOT/verify.sh" "$number" | tail -n 1)
    [ "$actual" = "$expected" ] ||
        die "Level $number: expected $expected, recovered $actual"
    printf 'Level %s live path passed.\n' "$number"
done

named=$(ip netns exec pln-l9 traceroute -m 12 -q 1 trace.lab.test)
numeric=$(ip netns exec pln-l9 traceroute -n -m 12 -q 1 trace.lab.test)
[ "$(printf '%s\n' "$named" | grep -Ec '^ [1-9]  ')" -eq 9 ] ||
    die 'Level 9 named trace did not display nine hops'
[ "$(printf '%s\n' "$numeric" | grep -Ec '^ [1-9]  ')" -eq 9 ] ||
    die 'Level 9 numeric trace did not display nine hops'
[ "$(printf '%s\n' "$named" | grep -c 'polylab[.]code[.]')" -eq 1 ] ||
    die 'Level 9 code hop is missing or repeated'
if printf '%s\n' "$named" | grep -qi 'bad[.]horse'; then
    die 'unrelated traceroute wording leaked into Level 9'
fi
ip netns exec pln-l9 nslookup 198.51.100.2 |
    grep -q 'for.the.glory.of.old.state.alma.lab.test' ||
    die 'Level 9 first-hop reverse DNS is missing'
printf 'Nine-hop named and numeric traces passed.\n'
