#!/bin/sh
set -eu
cd "$(dirname "$0")"

for script in install.sh install-builder-config.sh builder-config/scripts/validate-olddefconfig.sh \
    resources.sh topology.sh labctl nextlevel prevlevel \
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

USER_ID=student@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT="$case_root/first" sh install.sh --dry-run >/dev/null
USER_ID=student@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT="$case_root/repeat" sh install.sh --dry-run >/dev/null
diff -r "$case_root/first/home" "$case_root/repeat/home" >/dev/null

USER_ID=other@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT="$case_root/other" sh install.sh --dry-run >/dev/null
if cmp -s "$case_root/first/home/level2/README.txt" \
    "$case_root/other/home/level2/README.txt"; then
    echo 'changed learner did not vary Level 2 instructions' >&2
    exit 1
fi

USER_ID=student@example.edu CURRENT_DATE=2026-10-12 \
    NETLAB_ROOT="$case_root/later" sh install.sh --dry-run >/dev/null
if cmp -s "$case_root/first/home/level10/README.txt" \
    "$case_root/later/home/level10/README.txt"; then
    echo 'changed date did not vary Level 10 instructions' >&2
    exit 1
fi

[ "$(wc -l < data/alma-hop-hostnames.txt)" -eq 8 ]
! grep -i 'bad[.]horse' data/alma-hop-hostnames.txt
for number in 1 2 3 4 5 6 7 8 9 10; do
    [ -s "$case_root/first/home/level$number/README.txt" ]
done

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

INSTALL_ROOT=$(pwd)
NETLAB_ROOT="$case_root/story"
export INSTALL_ROOT NETLAB_ROOT
mkdir -p "$NETLAB_ROOT/dns"
. ./topology.sh
write_story_dns
[ "$(grep -c '^host-record=' "$NETLAB_ROOT/dns/level9.conf")" -eq 9 ]
[ "$(grep -c '^host-record=polylab[.]code[.]' "$NETLAB_ROOT/dns/level9.conf")" -eq 1 ]
line=$(grep -n '^host-record=polylab[.]code[.]' "$NETLAB_ROOT/dns/level9.conf" | cut -d : -f 1)
[ "$line" -eq $((2 * INSERT_AFTER + 7)) ]
grep -q '^address=/trace[.]lab[.]test/198[.]51[.]100[.]34$' \
    "$NETLAB_ROOT/dns/level9.conf"

printf 'Networking prototype static tests passed.\n'
