#!/bin/sh
# Root-owned sudo target. Only lab-local changes in the caller's namespace.
set -eu
real_ip=/usr/local/libexec/polylinux-real-ip
deny() { echo 'This level permits only its assigned network changes.' >&2; exit 1; }
valid_iface() {
    case "$SUDO_USER:$1" in
        level9:e0a) return 0 ;;
        level[1-5]:lan[0-9]*) printf '%s' "$1" | grep -Eq '^lan[0-9]{2}$' ;;
        *) return 1 ;;
    esac
}
case "${SUDO_USER:-}" in level1|level2|level3|level4|level5|level9) ;; *) deny ;; esac
[ "$#" -ge 2 ] || deny
case "$1:$2" in
    link:set)
        [ "$SUDO_USER" = level1 ] && [ "$#" -eq 5 ] &&
            [ "$3" = dev ] && valid_iface "$4" &&
            { [ "$5" = up ] || [ "$5" = down ]; } || deny
        ;;
    addr:add|addr:replace)
        case "$SUDO_USER" in level2|level3|level4) ;; *) deny ;; esac
        [ "$#" -eq 5 ] && [ "$4" = dev ] && valid_iface "$5" || deny
        case "$3" in *.*.*.*/*) ;; *) deny ;; esac
        ;;
    addr:flush)
        case "$SUDO_USER" in level2|level3|level4) ;; *) deny ;; esac
        [ "$#" -eq 4 ] && [ "$3" = dev ] && valid_iface "$4" || deny
        ;;
    route:add|route:replace)
        case "$SUDO_USER" in level5|level9) ;; *) deny ;; esac
        [ "$#" -eq 7 ] && [ "$3" = default ] && [ "$4" = via ] &&
            [ "$6" = dev ] && valid_iface "$7" || deny
        case "$5" in *.*.*.*) ;; *) deny ;; esac
        ;;
    route:del)
        case "$SUDO_USER" in level5|level9) ;; *) deny ;; esac
        [ "$#" -eq 3 ] && [ "$3" = default ] || deny
        ;;
    *) deny ;;
esac
exec "$real_ip" "$@"
