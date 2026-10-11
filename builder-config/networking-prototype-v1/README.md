# networking-prototype-v1 Buildroot config set

This profile extends the builder's `basic-compression-networking` configuration
for the ten-level PolyLinux Networking lab. It targets Buildroot `2025.02.15`
and the existing qemu x86 kernel `6.12.27` used by that profile. The package
fragment adds dnsmasq with DHCP, traceroute, and the curl command. BusyBox's
HTTP server and Linux network namespaces plus veth pairs are enabled by the
other two fragments.

Use `../../install-builder-config.sh /path/to/buildroot-builder2` from this
repository on the Linux build host. The installer copies this directory into
`config-sets/networking-prototype-v1` and appends absolute fragment paths to
the copied `features.fragment`; the source files here stay portable. Then run:

```sh
cd /path/to/buildroot-builder2
BUILDROOT_VERSION=2025.02.15 scripts/01-setup-buildroot.sh
scripts/02-build-baseline.sh --config networking-prototype-v1
```

The builder's output under `artifacts/networking-prototype-v1-<timestamp>/`
is a **candidate** baseline. Check the final Buildroot configuration, the
generated BusyBox and Linux configs, command presence, and the exact `bzImage`
plus `rootfs.cpio.gz` in v86. The required live gate is in `../../BASELINE.md`.
