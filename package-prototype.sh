#!/bin/sh
# Package only runtime lab files into an already validated Buildroot baseline.
set -eu

if [ "$#" -ne 3 ]; then
    echo 'Usage: sh package-prototype.sh BUILDER_DIR BASELINE_DIR OUTPUT_DIR' >&2
    exit 2
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
builder_dir=$(CDPATH= cd -- "$1" && pwd -P)
baseline_dir=$(CDPATH= cd -- "$2" && pwd -P)
output_parent=$(CDPATH= cd -- "$(dirname -- "$3")" && pwd -P)
output_dir="$output_parent/$(basename -- "$3")"

[ -f "$builder_dir/scripts/package_rootfs_payload.py" ] || {
    echo 'Builder payload packager is missing.' >&2
    exit 1
}
[ -f "$baseline_dir/images/bzImage" ] &&
    [ -f "$baseline_dir/images/rootfs.cpio.gz" ] || {
    echo 'Baseline image pair is missing.' >&2
    exit 1
}
[ ! -e "$output_dir" ] || {
    echo "Output already exists: $output_dir" >&2
    exit 1
}

stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/polylinux-networking-payload.XXXXXX")
cleanup() {
    case "$stage_dir" in
        */polylinux-networking-payload.*) rm -rf "$stage_dir" ;;
        *) echo "Refusing unexpected cleanup path: $stage_dir" >&2 ;;
    esac
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$stage_dir/bin" "$stage_dir/data/story-hop-hostnames"
for file in LICENSE .profile profile polylinux-colors.sh install.sh \
    resources.sh topology.sh labctl nextlevel prevlevel network-ip.sh \
    network-udhcpc.sh dhcp-client.sh level1.sh level2.sh level3.sh level4.sh level5.sh \
    level6.sh level7.sh level8.sh level9.sh level10.sh; do
    cp "$source_dir/$file" "$stage_dir/$file"
done
cp "$source_dir/bin/udhcpc" "$stage_dir/bin/udhcpc"
cp "$source_dir/bin/ip" "$stage_dir/bin/ip"
cp "$source_dir"/data/story-hop-hostnames/*.txt "$stage_dir/data/story-hop-hostnames/"

python3 "$builder_dir/scripts/package_rootfs_payload.py" \
    --bzimage "$baseline_dir/images/bzImage" \
    --rootfs "$baseline_dir/images/rootfs.cpio.gz" \
    --payload-dir "$stage_dir" \
    --output-dir "$output_dir" \
    --output-bzimage-name polylinux-networking.bzImage \
    --output-rootfs-name polylinux-networking.rootfs.cpio.gz
printf 'Packaged runtime-only prototype at %s\n' "$output_dir"
