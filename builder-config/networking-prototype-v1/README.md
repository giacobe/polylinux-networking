# networking-prototype-v1 Buildroot config set

This profile extends the builder's `basic-compression-networking` configuration
for the ten-level PolyLinux Networking lab. It targets Buildroot `2025.02.15`
and the existing qemu x86 kernel `6.12.27` used by that profile. The package
fragment adds dnsmasq with DHCP, traceroute, the curl command,
`BR2_PACKAGE_SUDO=y`, and `BR2_PACKAGE_BUSYBOX_HTTPD=y`. That Buildroot symbol
forces BusyBox's `httpd` applet into the binary. The BusyBox fragment also
requests `clear`, `adduser`, `passwd`, and `su`. iproute2 supplies `tc`; the
Linux fragment adds network namespaces, veth pairs, and netem scheduling for
Level 9's real per-link delays.

Use `../../install-builder-config.sh /path/to/buildroot-builder2` from this
repository on the Linux build host. The installer copies this directory into
`config-sets/networking-prototype-v1` and replaces the default-layout relative
fragment paths with absolute paths. Copying the directory directly works only
with the builder's default `work/src` layout. Then run:

```sh
cd /path/to/buildroot-builder2
BUILDROOT_VERSION=2025.02.15 scripts/01-setup-buildroot.sh
scripts/02-build-baseline.sh --config networking-prototype-v1
```

If this profile was already installed, pull the latest lab repository and
refresh the config set. Rebuild BusyBox and Linux from clean package directories
before running stage 2 again; fragment edits alone do not rebuild those
packages. See `BASELINE.md` for the exact commands and checks.

The builder's output under `artifacts/networking-prototype-v1-<timestamp>/`
is a **candidate** baseline. Check the final Buildroot configuration, the
generated BusyBox and Linux configs, command presence, and the exact `bzImage`
plus `rootfs.cpio.gz` in v86. The required live gate is in `../../BASELINE.md`.
