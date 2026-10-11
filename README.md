# PolyLinux Networking prototype

This is a one-VM prototype for ten levels of networking from the command line.
Levels 1–7 focus on local configuration, Level 8 compares ICMP reachability
with a local TCP listener, Level 9 traces a named nine-hop route, and Level 10
resolves and contacts an internal HTTP service.

The prototype is separate from the recovered eight-level source snapshot in
`github-sync/polylinux-networking`. It has not been packaged or boot-tested in
v86. Live installation requires a Linux guest with root access, network
namespaces, virtual Ethernet, IPv4 forwarding, and the commands in `TOOLSET.md`.
The current `basic-compression-networking` baseline does not meet that set.

## Buildroot builder profile

The [baseline assessment and build steps](BASELINE.md) identify the missing
packages and kernel options. The portable config files are in
[`builder-config/networking-prototype-v1`](builder-config/networking-prototype-v1).
On the Linux build host, run `sh install-builder-config.sh
/path/to/buildroot-builder2`, then build with
`scripts/02-build-baseline.sh --config networking-prototype-v1` using Buildroot
`2025.02.15`. This creates a candidate baseline; validate the exact image pair
in v86 before packaging the lab.

## Generate instructions without changing the network

```sh
NETLAB_ROOT=/tmp/polylinux-networking-prototype \
USER_ID=student@example.edu CURRENT_DATE=2026-10-11 \
sh install.sh --dry-run
```

## Run in a disposable Linux guest

```sh
USER_ID=student@example.edu CURRENT_DATE=2026-10-11 sh install.sh --live
sh labctl enter 1
```

Use `nextlevel` and `prevlevel` inside the level shell. Run `sh labctl reset`
from the parent guest shell to remove only this lab's namespaces. Re-running
`install.sh --live` resets those same namespaces before rebuilding them.
Developers can run `sh live-test.sh` after installation to exercise and
compare all ten live paths; keep that test and `verify.sh` outside any VM
payload.

Live configuration runs as root inside isolated namespaces because `ip link`,
`ip addr`, `ip route`, and resolver changes require privilege. This is a
prototype interface; the standard level-account presentation and external
grader package still need integration before publication.

The level seed is SHA-256 of the exact UTF-8 concatenation of normalized
email, ISO date, exercise password, and level password, with no separators or
trailing newline. Labeled sub-hashes set addresses, names, ports, the
12-character Level 9 code, and its insertion position. No answer key or local
correctness checker is installed.
