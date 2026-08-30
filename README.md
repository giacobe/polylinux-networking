# PolyLinux Lab 9: Networking from the Command Line

This repository preserves the eight-level networking prototype recovered from
an unlinked packaged PolyLinux Lab 9 initrd on 2026-08-29.

The source is intentionally preserved as deployed. It is not a complete modern
PolyLinux lab: it has eight levels, no public participant page, no reference
solver, and no deterministic automated test suite. Treat it as the baseline for
a future ten-level implementation.

See `PROVENANCE.md` before modifying or repackaging the exercise.

## Repository contents

- `install.sh` installs the recovered prototype in a compatible PolyLinux guest.
- `level1.sh` through `level8.sh` generate the eight recovered levels.
- `profile`, `nextlevel`, and `prevlevel` provide the learner interface.
- `provenance/RECOVERY-MANIFEST.json` records the recovered `/root` inventory.

Lab-specific VM images are intentionally excluded and deployed separately.

## License

Licensed under the GNU General Public License v3.0. See `LICENSE`.

## Build the browser VM

This lab uses the `basic-compression-networking` configuration from
[`giacobe/buildroot-builder2`](https://github.com/giacobe/buildroot-builder2),
validated with Buildroot `2025.02.15`:

```sh
git clone https://github.com/giacobe/buildroot-builder2.git
cd buildroot-builder2
BUILDROOT_VERSION=2025.02.15 scripts/01-setup-buildroot.sh
scripts/02-build-baseline.sh --config basic-compression-networking
scripts/03-package-payload.sh \
  --repo https://github.com/giacobe/polylinux-networking.git \
  --ref main \
  --baseline artifacts/basic-compression-networking-<timestamp> \
  --output artifacts/polylinux-networking \
  --output-prefix polylinux-networking
```

Replace `<timestamp>` with the stage-2 artifact directory. Review the manifest,
verify the required networking commands, and boot-test the exact image pair in
v86 before publishing.

## Standard runtime contract

The current release uses the reversible PolyBandit exercise code, the versioned `seed-v1` deterministic seed, ten concurrent level generators, staged `README.txt` readiness, unrestricted `nextlevel`/`prevlevel` navigation, and no client-side answer store or checker. See `lab.json` for the authoritative level count, theme policy, Buildroot configuration, and browser artifact names.

Do not rebuild the assigned Buildroot baseline merely to package this lab. Package the repository payload into the configuration named by `buildroot_configuration`, preserve the baseline kernel, and publish the resulting `packaged.bzImage` and `packaged.rootfs.cpio.gz`.
