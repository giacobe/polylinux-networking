#!/bin/sh
# Install the portable profile into a Linux checkout of buildroot-builder2.
set -eu

if [ "$#" -ne 1 ]; then
    echo 'Usage: sh install-builder-config.sh /path/to/buildroot-builder2' >&2
    exit 2
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")/builder-config/networking-prototype-v1" && pwd -P)
builder_dir=$(CDPATH= cd -- "$1" && pwd -P)
[ -f "$builder_dir/scripts/02-build-baseline.sh" ] || {
    echo 'Not a compatible PolyLinux Buildroot builder checkout.' >&2
    exit 1
}
[ -d "$builder_dir/config-sets" ] || {
    echo 'Builder config-sets directory is missing.' >&2
    exit 1
}

profile_dir="$builder_dir/config-sets/networking-prototype-v1"
[ ! -e "$profile_dir" ] || {
    echo "Profile already exists: $profile_dir" >&2
    exit 1
}
case "$profile_dir" in
    *'"'*|*'\'*|*' '*|*'\t'*)
        echo 'Builder path must not contain spaces, quotes, or backslashes.' >&2
        exit 1 ;;
esac

mkdir "$profile_dir"
cp "$source_dir/defconfig" "$source_dir/features.fragment" \
   "$source_dir/busybox.fragment" "$source_dir/linux.fragment" \
   "$source_dir/required-commands.txt" "$source_dir/README.md" "$profile_dir/"
printf 'BR2_PACKAGE_BUSYBOX_CONFIG_FRAGMENT_FILES="%s/busybox.fragment"\n' "$profile_dir" >> "$profile_dir/features.fragment"
printf 'BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="%s/linux.fragment"\n' "$profile_dir" >> "$profile_dir/features.fragment"
printf 'Installed %s\n' "$profile_dir"
