#!/bin/sh
set -eu

cd "$(dirname "$0")"
INSTALL_ROOT=$(pwd)
NETLAB_INSTALL_ROOT=$INSTALL_ROOT
NETLAB_ROOT=${NETLAB_ROOT:-/run/polylinux-networking}
CURRENT_DATE=${CURRENT_DATE:-$(date +%Y-%m-%d)}
SYSTEM_PASSWORD=${SYSTEM_PASSWORD:-systemPassword}
LEVEL_PASSWORD_ROOT=${LEVEL_PASSWORD_ROOT:-levelPassword}
INSTALL_MODE=live
NON_INTERACTIVE=0
NO_LOGIN=0
for argument in "$@"; do
    case "$argument" in
        --dry-run) INSTALL_MODE=dry; NO_LOGIN=1 ;;
        --live) INSTALL_MODE=live ;;
        --non-interactive) NON_INTERACTIVE=1 ;;
        --no-login) NO_LOGIN=1 ;;
        *) echo "ERROR: unknown option: $argument" >&2; exit 2 ;;
    esac
done
if [ "$INSTALL_MODE" = dry ]; then
    HOME_ROOT=${HOME_ROOT:-$NETLAB_ROOT/home}
else
    HOME_ROOT=${HOME_ROOT:-/home}
fi
export INSTALL_ROOT NETLAB_INSTALL_ROOT NETLAB_ROOT HOME_ROOT
export CURRENT_DATE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT INSTALL_MODE
. "$INSTALL_ROOT/resources.sh"

if [ "$NON_INTERACTIVE" -eq 1 ]; then
    raw_user=${USER_ID:-student@example.edu}
else
    while :; do
        printf 'Enter your email address: '
        IFS= read -r raw_user || die 'email input ended'
        normalized=$(normalize_email "$raw_user")
        if ! validate_email "$normalized"; then
            echo 'Enter a complete email address.' >&2
            continue
        fi
        printf 'Use %s for this exercise? (y/n) ' "$normalized"
        IFS= read -r confirmation || die 'email confirmation ended'
        case "$confirmation" in y|Y|yes|YES) break ;; esac
    done
fi
USER_ID=$(normalize_email "$raw_user")
validate_email "$USER_ID" || die 'USER_ID must be a complete email address'
validate_date "$CURRENT_DATE" || die 'CURRENT_DATE must be YYYY-MM-DD'
EXERCISE_CODE=$(exercise_code_from_date "$CURRENT_DATE")
export USER_ID EXERCISE_CODE
printf 'Exercise code: %s\n' "$EXERCISE_CODE"

for command in awk cat chmod chown cp cut date grep id ln mkdir mv printf \
    rm sed sha256sum sleep tr; do need "$command"; done
if [ "$INSTALL_MODE" = live ]; then
    [ "$(id -u)" -eq 0 ] || die 'live installation requires root'
    [ "$HOME_ROOT" = /home ] || die 'live HOME_ROOT must be /home'
    case "$NETLAB_ROOT" in
        /run/polylinux-networking|/tmp/polylinux-networking-prototype) ;;
        *) die 'live NETLAB_ROOT must be a recognized disposable path' ;;
    esac
    for command in adduser busybox curl dnsmasq ip nslookup passwd ping \
        ss su sudo traceroute udhcpc; do need "$command"; done
    busybox --list | grep -qx httpd || die 'BusyBox httpd applet is required'
    [ -d /proc/sys/net/ipv4 ] || die 'IPv4 kernel support is required'
fi

install_runtime() {
    [ "$INSTALL_ROOT" != /root ] || chmod 700 /root
    mkdir -p /usr/local/bin /usr/local/sbin /usr/local/libexec \
        /etc/profile.d /etc/sudoers.d
    real_ip=
    for candidate in /usr/sbin/ip /sbin/ip /usr/bin/ip /bin/ip; do
        if [ -x "$candidate" ]; then real_ip=$candidate; break; fi
    done
    [ -n "$real_ip" ] || die 'iproute2 ip binary not found outside /usr/local/bin'
    ln -sf "$real_ip" /usr/local/libexec/polylinux-real-ip
    cp "$INSTALL_ROOT/bin/ip" /usr/local/bin/ip
    cp "$INSTALL_ROOT/bin/udhcpc" /usr/local/bin/udhcpc
    cp "$INSTALL_ROOT/network-ip.sh" /usr/local/sbin/polylinux-network-ip
    cp "$INSTALL_ROOT/network-udhcpc.sh" /usr/local/sbin/polylinux-network-udhcpc
    cp "$INSTALL_ROOT/dhcp-client.sh" /usr/local/libexec/polylinux-dhcp-client.sh
    chmod 755 /usr/local/bin/ip /usr/local/bin/udhcpc \
        /usr/local/sbin/polylinux-network-ip \
        /usr/local/sbin/polylinux-network-udhcpc \
        /usr/local/libexec/polylinux-dhcp-client.sh
    cp "$INSTALL_ROOT/polylinux-colors.sh" /etc/profile.d/polylinux-colors.sh
    chmod 644 /etc/profile.d/polylinux-colors.sh
    cp "$INSTALL_ROOT/profile" /etc/profile
    chmod 644 /etc/profile
    cp "$INSTALL_ROOT/nextlevel" /usr/bin/nextlevel
    cp "$INSTALL_ROOT/prevlevel" /usr/bin/prevlevel
    chmod 755 /usr/bin/nextlevel /usr/bin/prevlevel
    {
        for number in 1 2 3 4 5 9; do
            printf 'level%s ALL=(root) NOPASSWD: /usr/local/sbin/polylinux-network-ip\n' "$number"
        done
        echo 'level7 ALL=(root) NOPASSWD: /usr/local/sbin/polylinux-network-udhcpc'
    } > /etc/sudoers.d/polylinux-networking
    chmod 440 /etc/sudoers.d/polylinux-networking
    if ! grep -Eq '^[#@]includedir[[:space:]]+/etc/sudoers.d' /etc/sudoers; then
        printf '\n@includedir /etc/sudoers.d\n' >> /etc/sudoers
    fi
    if command -v visudo >/dev/null 2>&1; then
        visudo -cf /etc/sudoers >/dev/null || die 'sudoers syntax check failed'
    fi
}

prepare_accounts() {
    mkdir -p "$HOME_ROOT" "$NETLAB_ROOT/ready" "$NETLAB_ROOT/failed" \
        "$NETLAB_ROOT/logs"
    for number in 1 2 3 4 5 6 7 8 9 10; do
        account=level$number
        home=$(level_home "$number")
        if [ "$INSTALL_MODE" = live ]; then
            if ! id "$account" >/dev/null 2>&1; then
                adduser -D -g 'PolyLinux Networking learner' "$account"
            fi
            passwd -d "$account" >/dev/null 2>&1 || die "could not unlock $account"
        fi
        case "$home" in
            "$HOME_ROOT"/level[1-9]|"$HOME_ROOT"/level10) rm -rf "$home" ;;
            *) die "refusing unexpected level home: $home" ;;
        esac
        mkdir -p "$home"
        cat > "$home/.README.pending.$$" <<EOF
Level $number is still preparing.

You may use nextlevel or prevlevel and return shortly.
EOF
        render_box_file "$home/.README.pending.$$" "$home/README.txt"
        rm -f "$home/.README.pending.$$"
        if [ "$INSTALL_MODE" = live ]; then
            chown -R "$account:$account" "$home"
            chmod 700 "$home"
        fi
        rm -f "$NETLAB_ROOT/ready/$account" "$NETLAB_ROOT/failed/$account"
    done
}

build_one() (
    number=$1
    account=level$number
    final_home=$(level_home "$number")
    LEVEL_HOME="$HOME_ROOT/.polylinux-networking-$account-$$"
    export LEVEL_HOME
    case "$LEVEL_HOME" in
        "$HOME_ROOT"/.polylinux-networking-level[1-9]-*|\
        "$HOME_ROOT"/.polylinux-networking-level10-*) ;;
        *) die "refusing unexpected staging path: $LEVEL_HOME" ;;
    esac
    mkdir -p "$LEVEL_HOME"
    if sh "$INSTALL_ROOT/level$number.sh" > "$NETLAB_ROOT/logs/$account.log" 2>&1 &&
        [ -s "$LEVEL_HOME/README.txt" ]; then
        cp "$LEVEL_HOME/README.txt" "$final_home/.README.ready.$$"
        if [ "$INSTALL_MODE" = live ]; then
            chown "$account:$account" "$final_home/.README.ready.$$"
        fi
        mv "$final_home/.README.ready.$$" "$final_home/README.txt"
        : > "$NETLAB_ROOT/ready/$account"
        rm -rf "$LEVEL_HOME"
        exit 0
    fi
    {
        echo "Level $number could not be prepared."
        printf 'Report this level and the build log: %s\n' "$NETLAB_ROOT/logs/$account.log"
    } > "$final_home/.README.failed.$$"
    render_box_file "$final_home/.README.failed.$$" "$final_home/README.txt"
    rm -f "$final_home/.README.failed.$$"
    if [ "$INSTALL_MODE" = live ]; then
        chown "$account:$account" "$final_home/README.txt"
    fi
    : > "$NETLAB_ROOT/failed/$account"
    rm -rf "$LEVEL_HOME"
    exit 1
)

if [ "$INSTALL_MODE" = live ]; then
    install_runtime
    . "$INSTALL_ROOT/topology.sh"
    prepare_topology
fi
prepare_accounts

pids=
for number in 1 2 3 4 5 6 7 8 9 10; do
    build_one "$number" &
    pids="$pids $!"
done
if [ "$NO_LOGIN" -eq 1 ]; then
    failures=0
    for pid in $pids; do wait "$pid" || failures=$((failures + 1)); done
    [ "$failures" -eq 0 ] || die "$failures level(s) failed; inspect $NETLAB_ROOT/logs"
    printf 'Ten levels are ready for %s.\n' "$USER_ID"
    exit 0
fi
while [ ! -f "$NETLAB_ROOT/ready/level1" ]; do
    [ ! -f "$NETLAB_ROOT/failed/level1" ] ||
        die "Level 1 failed; inspect $NETLAB_ROOT/logs/level1.log"
    sleep 1
done
printf 'Level 1 is ready for %s. Later levels may still be preparing.\n' "$USER_ID"
exec sh "$INSTALL_ROOT/labctl" enter 1
