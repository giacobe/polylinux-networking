#!/bin/sh
# Check the package selections against an actual Buildroot 2025.02.15 tree.
set -eu

if [ "$#" -ne 1 ] || [ ! -f "$1/Makefile" ]; then
    echo 'Usage: sh validate-olddefconfig.sh /path/to/buildroot-2025.02.15' >&2
    exit 2
fi

buildroot_src=$(CDPATH= cd -- "$1" && pwd -P)
profile_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../networking-prototype-v1" && pwd -P)
output_dir=$(mktemp -d "${TMPDIR:-/tmp}/polylinux-networking-kconfig.XXXXXX")
cleanup() {
    case "$output_dir" in
        */polylinux-networking-kconfig.*) rm -rf "$output_dir" ;;
        *) echo "Refusing unexpected cleanup path: $output_dir" >&2 ;;
    esac
}
trap cleanup EXIT HUP INT TERM

cp "$profile_dir/defconfig" "$output_dir/.config"
sed '/^BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES=/d; /^BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=/d' \
    "$profile_dir/features.fragment" >> "$output_dir/.config"
printf 'BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES="%s/busybox.fragment"\n' "$profile_dir" >> "$output_dir/.config"
printf 'BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="%s/linux.fragment"\n' "$profile_dir" >> "$output_dir/.config"
make -s -C "$buildroot_src" O="$output_dir" olddefconfig

for selection in \
    BR2_PACKAGE_BUSYBOX_HTTPD=y \
    BR2_PACKAGE_DNSMASQ=y \
    BR2_PACKAGE_DNSMASQ_DHCP=y \
    BR2_PACKAGE_TRACEROUTE=y \
    BR2_PACKAGE_LIBCURL=y \
    BR2_PACKAGE_LIBCURL_CURL=y; do
    grep -Fqx "$selection" "$output_dir/.config" || {
        echo "Buildroot dropped required selection: $selection" >&2
        exit 1
    }
done
grep -Fqx "BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES=\"$profile_dir/busybox.fragment\"" "$output_dir/.config"
grep -Fqx "BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=\"$profile_dir/linux.fragment\"" "$output_dir/.config"
printf 'Buildroot package and fragment selections survived olddefconfig.\n'
