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
- `basic1.sh` through `basic8.sh` generate the eight recovered levels.
- `profile`, `nextlevel`, and `prevlevel` provide the learner interface.
- `provenance/RECOVERY-MANIFEST.json` records the recovered `/root` inventory.

Lab-specific VM images are intentionally excluded and deployed separately.

## License

Licensed under the GNU General Public License v3.0. See `LICENSE`.
