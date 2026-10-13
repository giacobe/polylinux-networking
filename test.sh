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
grep -Fqx 'CONFIG_CLEAR=y' "$profile_dir/busybox.fragment"
grep -Fqx 'CONFIG_NET_SCHED=y' "$profile_dir/linux.fragment"
grep -Fqx 'CONFIG_NET_SCH_NETEM=y' "$profile_dir/linux.fragment"
grep -Fqx 'clear' "$profile_dir/required-commands.txt"
grep -Fqx 'tc' "$profile_dir/required-commands.txt"
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

story_count=0
for story_file in data/story-hop-hostnames/*.txt; do
    story_count=$((story_count + 1))
    [ "$(wc -l < "$story_file")" -eq 8 ]
    [ "$(sort -u "$story_file" | wc -l)" -eq 8 ]
    awk 'length($0) > 253 || $0 !~ /^[a-z0-9]+([.][a-z0-9]+)+$/ { exit 1 }
        { n = split($0, labels, "."); for (i = 1; i <= n; i++) if (length(labels[i]) > 63) exit 1 }' \
        "$story_file"
    ! grep -i 'bad[.]horse\|alma[.]lab[.]test' "$story_file"
done
[ "$story_count" -eq 6 ]
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
grep -Fq "* The resolver at .1 supplies each hop's full name." \
    "$case_root/first/home/level9/README.txt"
grep -Fq 'PolyLab code hop appears between the first and last lyric hops.' \
    "$case_root/first/home/level9/README.txt"

USER_ID=student@example.edu
CURRENT_DATE=2026-10-11
SYSTEM_PASSWORD=systemPassword
LEVEL_PASSWORD_ROOT=levelPassword
export USER_ID CURRENT_DATE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT
. ./resources.sh
. ./topology.sh
level_values 9
[ "$LEVEL_SEED" = 'e6c52cf528b46da253df5a3d0140e77f37962f4f544201fa9254b549de83d9d3' ]
case "$CODE" in
    ????????????) ;; *) echo 'Level 9 code length changed' >&2; exit 1 ;;
esac
printf '%s' "$CODE" | grep -Eq '^[0-9a-f]{12}$'
[ "$INSERT_AFTER" -ge 2 ] && [ "$INSERT_AFTER" -le 6 ]
first_delay=
varied=0
for link in 0 1 2 3 4 5 6 7 8; do
    delay=$(story_link_delay_ms "$link")
    [ "$delay" -ge 10 ] && [ "$delay" -le 200 ]
    [ "$(story_link_delay_ms "$link")" -eq "$delay" ]
    if [ -z "$first_delay" ]; then first_delay=$delay
    elif [ "$delay" -ne "$first_delay" ]; then varied=1; fi
done
[ "$varied" -eq 1 ]

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
write_story_dns
[ "$(grep -c '^host-record=' "$NETLAB_ROOT/dns/level9.conf")" -eq 9 ]
[ "$(grep -c '^host-record=polylab[.]code[.]' "$NETLAB_ROOT/dns/level9.conf")" -eq 1 ]
position=$(awk '/^host-record=/ { count++; if ($0 ~ /^host-record=polylab[.]code[.]/) print count }' \
    "$NETLAB_ROOT/dns/level9.conf")
[ "$position" -eq $((INSERT_AFTER + 1)) ]
grep -q '^address=/trace[.]lab[.]test/198[.]51[.]100[.]34$' \
    "$NETLAB_ROOT/dns/level9.conf"
! grep -q '^ptr-record=' "$NETLAB_ROOT/dns/level9.conf"
awk -F, '/^host-record=/ { expected = count == 0 ? 1 : 4 * count + 2; if ($2 != "198.51.100." expected) exit 1; count++ } END { if (count != 9) exit 1 }' \
    "$NETLAB_ROOT/dns/level9.conf"
selected_story="$INSTALL_ROOT/data/story-hop-hostnames/$(story_variant_filename "$story_variant")"
first_name=$(sed -n '1p' "$selected_story")
grep -Fq "host-record=$first_name,198.51.100.1" \
    "$NETLAB_ROOT/dns/level9.conf"
! grep -Fq 'alma.lab.test' "$NETLAB_ROOT/dns/level9.conf"
seen_variants=' '
for seed_number in $(seq 1 60); do
    USER_ID="student${seed_number}@example.edu"
    write_story_dns
    case "$seen_variants" in
        *" $story_variant "*) ;;
        *) seen_variants="$seen_variants$story_variant " ;;
    esac
    selected_story="$INSTALL_ROOT/data/story-hop-hostnames/$(story_variant_filename "$story_variant")"
    awk -F '[=,]' '/^host-record=/ && $2 !~ /^polylab[.]code[.]/ { print $2 }' \
        "$NETLAB_ROOT/dns/level9.conf" > "$case_root/emitted-story.txt"
    cmp -s "$selected_story" "$case_root/emitted-story.txt"
    [ "$(grep -c '^host-record=polylab[.]code[.]' "$NETLAB_ROOT/dns/level9.conf")" -eq 1 ]
    position=$(awk '/^host-record=/ { count++; if ($0 ~ /^host-record=polylab[.]code[.]/) print count }' \
        "$NETLAB_ROOT/dns/level9.conf")
    [ "$position" -eq $((INSERT_AFTER + 1)) ]
done
[ "$(printf '%s\n' "$seen_variants" | wc -w)" -eq 6 ]
USER_ID=student@example.edu
write_story_dns
grep -Fq '198.51.100.1' "$case_root/first/home/level9/README.txt"
awk '/^clear$/ { cleared=1 } /^cat README[.]txt$/ { if (!cleared) exit 1; found=1 } END { if (!found) exit 1 }' profile

# Exercise the topology builder with a logging ip stub so the first-link
# address swap and all 18 netem directions are checked without root access.
(
    ip() { printf '%s\n' "$*" >> "$case_root/story-ip.log"; }
    set_resolver() { printf '%s %s\n' "$1" "$2" >> "$case_root/story-resolver.log"; }
    start_dnsmasq() { :; }
    setup_story_level
)
grep -Fqx -- '-n pln-l9 addr add 198.51.100.2/30 dev e0a' "$case_root/story-ip.log"
grep -Fqx -- '-n pln-r9-1 addr add 198.51.100.1/30 dev e0b' "$case_root/story-ip.log"
grep -Fqx 'pln-l9 198.51.100.1' "$case_root/story-resolver.log"
[ "$(grep -Ec '^netns exec pln-.* tc qdisc add dev e[0-8][ab] root netem delay [0-9]+ms$' \
    "$case_root/story-ip.log")" -eq 18 ]
delay=$(story_link_delay_ms 0)
forward=$((delay / 2))
backward=$((delay - forward))
grep -Fqx "netns exec pln-l9 tc qdisc add dev e0a root netem delay ${forward}ms" \
    "$case_root/story-ip.log"
grep -Fqx "netns exec pln-r9-1 tc qdisc add dev e0b root netem delay ${backward}ms" \
    "$case_root/story-ip.log"
[ -f .profile ] && [ -f profile ] && [ -f polylinux-colors.sh ]
grep -q 'exec sh /root/install.sh' .profile
grep -q 'su - "level$number"' labctl
grep -q '^BR2_PACKAGE_SUDO=y$' builder-config/networking-prototype-v1/features.fragment

for file in LICENSE .profile profile polylinux-colors.sh install.sh resources.sh \
    topology.sh labctl nextlevel prevlevel network-ip.sh network-udhcpc.sh \
    dhcp-client.sh level1.sh level2.sh level3.sh level4.sh level5.sh \
    level6.sh level7.sh level8.sh level9.sh level10.sh bin/ip bin/udhcpc \
    data/story-hop-hostnames/alma-opening.txt \
    data/story-hop-hostnames/alma-middle.txt \
    data/story-hop-hostnames/nittany-opening.txt \
    data/story-hop-hostnames/nittany-chorus.txt \
    data/story-hop-hostnames/fight-on-state.txt \
    data/story-hop-hostnames/victory-refrain.txt; do
    cmp -s "$file" "payload/$file" || {
        echo "runtime payload is stale: $file" >&2
        exit 1
    }
done
[ ! -e payload/verify.sh ] && [ ! -e payload/test.sh ] &&
    [ ! -e payload/builder-config ]

printf 'Networking prototype static tests passed.\n'
