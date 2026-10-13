#!/bin/sh
set -eu
cd "$(dirname "$0")"

for script in install.sh install-builder-config.sh package-prototype.sh \
    builder-config/scripts/validate-olddefconfig.sh \
    builder-config/scripts/smoke-packaged-rootfs.sh \
    resources.sh topology.sh labctl .profile profile nextlevel prevlevel \
    network-ip.sh network-udhcpc.sh bin/ip polylinux-colors.sh \
    live-test.sh verify.sh \
    bin/udhcpc dhcp-client.sh \
    level1.sh level2.sh level3.sh level4.sh level5.sh level6.sh level7.sh \
    level8.sh level9.sh level10.sh; do
    sh -n "$script"
done

case_root=$(mktemp -d "${TMPDIR:-/tmp}/polylinux-networking-test.XXXXXX")
cleanup() {
    case "$case_root" in
        */polylinux-networking-test.*) rm -rf "$case_root" ;;
        *) printf 'refusing unexpected test cleanup path: %s\n' "$case_root" >&2 ;;
    esac
}
trap cleanup EXIT HUP INT TERM

# Run the learner-facing wrapper as a simulated unprivileged account. The
# standard long spelling must reach the root-owned helper, not raw iproute2.
mkdir -p "$case_root/mock-bin"
cat > "$case_root/mock-bin/id" <<'EOF'
#!/bin/sh
[ "$1" = -u ] || exit 1
printf '1000\n'
EOF
cat > "$case_root/mock-bin/sudo" <<'EOF'
#!/bin/sh
printf 'sudo'
printf ' %s' "$@"
printf '\n'
EOF
chmod 755 "$case_root/mock-bin/id" "$case_root/mock-bin/sudo"
dispatch=$(PATH="$case_root/mock-bin:$PATH" sh bin/ip address add \
    192.0.2.106/24 dev lan72)
[ "$dispatch" = 'sudo -n /usr/local/sbin/polylinux-network-ip address add 192.0.2.106/24 dev lan72' ] || {
    printf 'ip address add bypassed the network helper: %s\n' "$dispatch" >&2
    exit 1
}

mkdir -p "$case_root/builder/scripts" "$case_root/builder/config-sets"
: > "$case_root/builder/scripts/02-build-baseline.sh"
sh install-builder-config.sh "$case_root/builder" >/dev/null
sh install-builder-config.sh --refresh "$case_root/builder" >/dev/null
profile_dir="$case_root/builder/config-sets/networking-prototype-v1"
grep -Fqx 'BR2_PACKAGE_BUSYBOX_HTTPD=y' "$profile_dir/features.fragment"
[ "$(grep -Fc 'BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES=' "$profile_dir/features.fragment")" -eq 1 ]
grep -Fqx 'BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES="../../../config-sets/networking-prototype-v1/busybox.fragment"' \
    builder-config/networking-prototype-v1/features.fragment
grep -Fqx 'BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="../../../config-sets/networking-prototype-v1/linux.fragment"' \
    builder-config/networking-prototype-v1/features.fragment
grep -Fqx "BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES=\"$profile_dir/busybox.fragment\"" \
    "$profile_dir/features.fragment"
grep -Fqx "BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=\"$profile_dir/linux.fragment\"" \
    "$profile_dir/features.fragment"

install_output=$(USER_ID=student@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT="$case_root/first" sh install.sh --dry-run --non-interactive)
printf '%s\n' "$install_output" | grep -Fqx 'Exercise code: 1352893'
USER_ID=student@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT="$case_root/repeat" sh install.sh --dry-run --non-interactive >/dev/null
diff -r "$case_root/first/home" "$case_root/repeat/home" >/dev/null
printf 'invalid\n Student@Example.edu \ny\n' | \
    CURRENT_DATE=2026-10-11 NETLAB_ROOT="$case_root/interactive" \
    sh install.sh --dry-run >/dev/null
grep -Fq '* Participant: student@example.edu' \
    "$case_root/interactive/home/level1/README.txt"

USER_ID=other@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT="$case_root/other" sh install.sh --dry-run --non-interactive >/dev/null
if cmp -s "$case_root/first/home/level2/README.txt" \
    "$case_root/other/home/level2/README.txt"; then
    echo 'changed learner did not vary Level 2 instructions' >&2
    exit 1
fi

USER_ID=student@example.edu CURRENT_DATE=2026-10-12 \
    NETLAB_ROOT="$case_root/later" sh install.sh --dry-run --non-interactive >/dev/null
if cmp -s "$case_root/first/home/level10/README.txt" \
    "$case_root/later/home/level10/README.txt"; then
    echo 'changed date did not vary Level 10 instructions' >&2
    exit 1
fi

[ "$(wc -l < data/alma-hop-hostnames.txt)" -eq 8 ]
! grep -i 'bad[.]horse' data/alma-hop-hostnames.txt
for number in 1 2 3 4 5 6 7 8 9 10; do
    readme="$case_root/first/home/level$number/README.txt"
    [ -s "$readme" ]
    awk 'length($0) != 80 || $0 !~ /^\*/ || $0 !~ /\*$/ { exit 1 }' "$readme"
    grep -Fq "* Level: level$number" "$readme"
    grep -Fq '* Exercise code: 1352893' "$readme"
    grep -Fq '* Instructions for this level' "$readme"
    awk '/Answer format:/ && $0 !~ /^\* Answer format:/ { exit 1 }' "$readme"
done
grep -Fq '* Exercise code: 1352894' "$case_root/later/home/level1/README.txt"
grep -Fq '* The resolver at .2 supplies full names ending in .alma.lab.test.' \
    "$case_root/first/home/level9/README.txt"
grep -Fq '* One PolyLab code line appears between the first and last lyric lines.' \
    "$case_root/first/home/level9/README.txt"

USER_ID=student@example.edu
CURRENT_DATE=2026-10-11
SYSTEM_PASSWORD=systemPassword
LEVEL_PASSWORD_ROOT=levelPassword
export USER_ID CURRENT_DATE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT
. ./resources.sh
level_values 9
[ "$LEVEL_SEED" = 'e6c52cf528b46da253df5a3d0140e77f37962f4f544201fa9254b549de83d9d3' ]
case "$CODE" in
    ????????????) ;; *) echo 'Level 9 code length changed' >&2; exit 1 ;;
esac
printf '%s' "$CODE" | grep -Eq '^[0-9a-f]{12}$'
[ "$INSERT_AFTER" -ge 2 ] && [ "$INSERT_AFTER" -le 6 ]

# The live topology uses `number` while creating routers. It must not change
# which level's README is generated after topology setup returns.
mkdir -p "$case_root/mock-topology" "$case_root/mock-level9"
printf 'setup_story_level() { number=8; }\n' > "$case_root/mock-topology/topology.sh"
(
    INSTALL_MODE=live
    INSTALL_ROOT="$case_root/mock-topology"
    LEVEL_HOME="$case_root/mock-level9"
    export INSTALL_MODE INSTALL_ROOT LEVEL_HOME
    generate_level 9
)
grep -Fq '* Level: level9' "$case_root/mock-level9/README.txt"
grep -Fq 'Traceroute and reverse DNS' "$case_root/mock-level9/README.txt"

INSTALL_ROOT=$(pwd)
NETLAB_ROOT="$case_root/story"
export INSTALL_ROOT NETLAB_ROOT
mkdir -p "$NETLAB_ROOT/dns"
. ./topology.sh
write_story_dns
[ "$(grep -c '^host-record=' "$NETLAB_ROOT/dns/level9.conf")" -eq 9 ]
[ "$(grep -c '^host-record=polylab[.]code[.]' "$NETLAB_ROOT/dns/level9.conf")" -eq 1 ]
line=$(grep -n '^host-record=polylab[.]code[.]' "$NETLAB_ROOT/dns/level9.conf" | cut -d : -f 1)
[ "$line" -eq $((INSERT_AFTER + 8)) ]
grep -q '^address=/trace[.]lab[.]test/198[.]51[.]100[.]34$' \
    "$NETLAB_ROOT/dns/level9.conf"
! grep -q '^ptr-record=' "$NETLAB_ROOT/dns/level9.conf"
awk -F, '/^host-record=/ { expected = 4 * count + 2; if ($2 != "198.51.100." expected) exit 1; count++ } END { if (count != 9) exit 1 }' \
    "$NETLAB_ROOT/dns/level9.conf"
grep -Fq '198.51.100.2' "$case_root/first/home/level9/README.txt"
[ -f .profile ] && [ -f profile ] && [ -f polylinux-colors.sh ]
grep -q 'exec sh /root/install.sh' .profile
grep -q 'su - "level$number"' labctl
grep -q '^BR2_PACKAGE_SUDO=y$' builder-config/networking-prototype-v1/features.fragment

for file in LICENSE .profile profile polylinux-colors.sh install.sh resources.sh \
    topology.sh labctl nextlevel prevlevel network-ip.sh network-udhcpc.sh \
    dhcp-client.sh level1.sh level2.sh level3.sh level4.sh level5.sh \
    level6.sh level7.sh level8.sh level9.sh level10.sh bin/ip bin/udhcpc \
    data/alma-hop-hostnames.txt; do
    cmp -s "$file" "payload/$file" || {
        echo "runtime payload is stale: $file" >&2
        exit 1
    }
done
[ ! -e payload/verify.sh ] && [ ! -e payload/test.sh ] &&
    [ ! -e payload/builder-config ]

printf 'Networking prototype static tests passed.\n'
