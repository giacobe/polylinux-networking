#!/bin/sh
# Developer-only live validation. Run after install.sh --live in a Linux guest.
set -eu
cd "$(dirname "$0")"
INSTALL_ROOT=$(pwd)
NETLAB_ROOT=${NETLAB_ROOT:-/run/polylinux-networking}
USER_ID=${USER_ID:-student@example.edu}
CURRENT_DATE=${CURRENT_DATE:-$(date +%Y-%m-%d)}
SYSTEM_PASSWORD=${SYSTEM_PASSWORD:-systemPassword}
LEVEL_PASSWORD_ROOT=${LEVEL_PASSWORD_ROOT:-levelPassword}
export INSTALL_ROOT NETLAB_ROOT USER_ID CURRENT_DATE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT
. ./resources.sh

[ "$(id -u)" -eq 0 ] || die 'live-test.sh requires root'
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
printf 'Nine-hop named and numeric traces passed.\n'
