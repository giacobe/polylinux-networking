#!/bin/sh
# Applied by BusyBox udhcpc after a real lease from the local dnsmasq server.
set -eu
: "${interface:?missing DHCP interface}"
case "${1:-}" in
    deconfig)
        /usr/local/libexec/polylinux-real-ip -4 addr flush dev "$interface"
        /usr/local/libexec/polylinux-real-ip route del default 2>/dev/null || true
        ;;
    bound|renew)
        : "${ip:?missing leased address}"
        [ "${subnet:-}" = 255.255.255.0 ] || exit 1
        /usr/local/libexec/polylinux-real-ip -4 addr flush dev "$interface"
        /usr/local/libexec/polylinux-real-ip addr add "$ip/24" dev "$interface"
        first_router=${router%% *}
        first_dns=${dns%% *}
        [ -n "$first_router" ] && [ -n "$first_dns" ] || exit 1
        /usr/local/libexec/polylinux-real-ip route replace default via "$first_router" dev "$interface"
        printf 'nameserver %s\n' "$first_dns" > /etc/resolv.conf
        ;;
esac
