#!/bin/sh
# Developer-only check of a packaged prototype rootfs on an x86 Linux host.
set -eu

if [ "$#" -ne 1 ] || [ ! -f "$1" ] || [ "$(id -u)" -ne 0 ]; then
    echo 'Usage (as root): sh smoke-packaged-rootfs.sh PACKAGE.rootfs.cpio.gz' >&2
    exit 2
fi

rootfs=$1
extract_dir=$(mktemp -d "${TMPDIR:-/tmp}/polylinux-networking-rootfs.XXXXXX")
cleanup() {
    case "$extract_dir" in
        */polylinux-networking-rootfs.*) rm -rf "$extract_dir" ;;
        *) echo "Refusing unexpected cleanup path: $extract_dir" >&2 ;;
    esac
}
trap cleanup EXIT HUP INT TERM

gzip -dc "$rootfs" | (cd "$extract_dir" && cpio -id --quiet --no-absolute-filenames)
[ -f "$extract_dir/root/install.sh" ] || {
    echo 'Packaged rootfs lacks the lab installer.' >&2
    exit 1
}
chroot "$extract_dir" /bin/busybox --list | grep -qx httpd || {
    echo 'Packaged BusyBox lacks httpd.' >&2
    exit 1
}
env USER_ID=student@example.edu CURRENT_DATE=2026-10-11 \
    NETLAB_ROOT=/tmp/polylinux-networking-prototype \
    chroot "$extract_dir" /bin/sh /root/install.sh --dry-run
printf 'Packaged BusyBox httpd and ten-level dry run passed.\n'
