# Recovery provenance

- Lab: 9, Networking from the Command Line
- Live packaged initrd: `https://polylab.ist.psu.edu/polylinux/lab9/packaged.rootfs.cpio.gz`
- Packaged initrd SHA-256: `e03329b87c5cb5afd2d90ec92eb76167d01b895febf9475bc8f760d716074e21`
- Live baseline initrd: `https://polylab.ist.psu.edu/polylinux/lab9/rootfs.cpio.gz`
- Baseline initrd SHA-256: `8920555cd6baafa7fc62f7c54fed229f98935630c2ff1cf0a2189067a231e607`
- Recovery date: 2026-08-29
- Recovered boundary: `/root`

The baseline image contains no `/root` payload. The packaged image adds the
installer, `level1.sh` through `level8.sh`, profile, and navigation helpers.
All 12 assessed payload files match the local staged networking prototype
exactly. The original packaged `/root` entry manifest is retained at
`provenance/RECOVERY-MANIFEST.json`.
