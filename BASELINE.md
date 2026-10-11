# Buildroot baseline: networking-prototype-v1

The existing `basic-compression-networking` artifact is the closest starting
point. Its final Buildroot config has `iproute2` and `iputils`, but not
`dnsmasq`, `traceroute`, or `libcurl`'s `curl` binary. Its Buildroot 2025.02.15
qemu x86 kernel source config does not request `CONFIG_NET_NS` or
`CONFIG_VETH`. The separate `processes-v1` built image has `CONFIG_NET_NS=y`
but `CONFIG_VETH` unset and lacks the needed networking packages. None is a
verified image for the ten levels, so build a new baseline.

## Builder inputs

- Builder: [`giacobe/buildroot-builder2`](https://github.com/giacobe/buildroot-builder2),
  whose `scripts/02-build-baseline.sh` accepts the config-set layout below.
- Buildroot: **2025.02.15**, the release used by the starting config and
  checked against the saved local source tree.
- Starting profile: `basic-compression-networking` (`defconfig` copied into
  `builder-config/networking-prototype-v1/defconfig`).
- Kernel: the same qemu x86 custom version **6.12.27** and base config, plus
  `linux.fragment` for namespaces and veth.
- Output name: `networking-prototype-v1`.
- Host: an Ubuntu/Debian Linux VM with sufficient CPU, RAM, and disk for the
  existing builder workflow. Record its distribution, version, resources, and
  toolchain in the build manifest.

The portable files are in
[`builder-config/networking-prototype-v1`](builder-config/networking-prototype-v1).
The profile installer copies them into a Linux builder checkout and appends
absolute paths for the BusyBox and Linux fragments. This is necessary because
the builder copies `defconfig` into a separate output directory before running
`make olddefconfig`.

## Build on the Linux builder host

```sh
git clone https://github.com/giacobe/buildroot-builder2.git
git clone https://github.com/giacobe/polylinux-networking.git
sh polylinux-networking/install-builder-config.sh "$PWD/buildroot-builder2"
cd buildroot-builder2
BUILDROOT_VERSION=2025.02.15 scripts/01-setup-buildroot.sh
scripts/02-build-baseline.sh --config networking-prototype-v1
```

If dependencies are already installed, `scripts/01-setup-buildroot.sh
--skip-deps` uses the same source setup without running `apt-get`. Do not
substitute the builder's newer default Buildroot release without first
revalidating the symbols and fragment behavior.

The profile requests `iproute2` (`ip`, `ss`), `iputils` (`ping`), traceroute,
dnsmasq with DHCP, and curl without a TLS backend because lab traffic stays
inside the VM over HTTP. BusyBox supplies `httpd`, `nslookup`, and `udhcpc`.
The kernel fragment requests `CONFIG_NAMESPACES`, `CONFIG_NET_NS`, and
`CONFIG_VETH` plus their networking, proc, and sysctl prerequisites.

## Inspect and preserve the result

The builder writes `artifacts/networking-prototype-v1-<timestamp>/` with a
version-named `bzImage` and `rootfs.cpio.gz`, the input defconfig, final
Buildroot config, build log, hashes, and required-command manifest. Before
using it, inspect the final Buildroot `.config` for all requested package and
fragment-path symbols. Locate the generated `build/linux-*/.config` and
`build/busybox-*/.config` in the builder's output directory and preserve both
as `configs/final-linux.config` and `configs/final-busybox.config`; verify the
requested options survived `olddefconfig` and fragment merging. Also preserve
the final Buildroot defconfig (`make -C "$BUILDROOT_SRC" O="$BUILD_DIR/networking-prototype-v1" savedefconfig` after sourcing `.polylinux-builder.env`), full build log,
host/toolchain details, and SHA-256 hashes in the versioned artifact package.

Run a command-presence check against the built archive (from the sibling
`polylinux-networking` checkout):

```sh
python3 ../polylinux-networking/builder-config/scripts/check-rootfs-commands.py \
  artifacts/networking-prototype-v1-<timestamp>/images/rootfs.cpio.gz \
  --commands $(cat config-sets/networking-prototype-v1/required-commands.txt)
```

This checks names only. Boot the **exact** `bzImage` and `rootfs.cpio.gz` pair
in v86 and exercise namespace/veth creation, interface and route changes,
the DHCP lease, A and PTR lookups, all nine named traceroute hops, the local
listener in `ss`, and HTTP fetches. Run all ten `live-test.sh` paths in a
compatible guest. Record results in `manifest/validation-notes.md`. Keep the
baseline image free of lab payload files; package the lab into `/root` only
after the baseline passes, then boot-test the packaged pair again.
