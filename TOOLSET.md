# Toolset and guest requirements

## Learner-facing commands

`ip`, `ping`, `ss`, `traceroute`, `nslookup`, `udhcpc`, and `curl`.
Basic shell commands (`cat`, `printf`, `grep`, `awk`, `sed`) support inspection
and resolver edits. Learners sign into distinct `levelN` accounts. The
installed `ip` and `udhcpc` wrappers let those accounts make only the
assigned changes in their own namespaces through root-owned `sudo` helpers.

## Installer and service dependencies

`ip` must support `netns`, `link`, `addr`, `route`, and `-n`. The guest also
needs `dnsmasq` for isolated DHCP/DNS fixtures, BusyBox `httpd` for local
HTTP fixtures, and `tc` from iproute2 for Level 9 link delays. Account setup
requires BusyBox `adduser`, `passwd`, `su`, and Buildroot `sudo`. The account
profile uses BusyBox `clear` before each level display. The installer also
requires `sha256sum`, `cut`, `tr`, `awk`,
`sed`, `grep`, `sleep`, `id`, and standard POSIX shell utilities.

The kernel must support `CONFIG_NET_NS`, `CONFIG_VETH`, `CONFIG_NET_SCHED`,
`CONFIG_NET_SCH_NETEM`, IPv4 forwarding, ICMP Time Exceeded replies, and the
namespace-specific resolver bind mounts
used by `ip netns exec`. Confirm these in the exact v86 image.

The preserved `basic-compression-networking` baseline has `ip` and `ping` in
its required-command manifest. Its saved Buildroot configuration disables
`curl` and `dnsmasq`; BusyBox `httpd` and `udhcpd` are disabled in its saved
BusyBox configuration. `ss`, `traceroute`, `nslookup`, and `udhcpc` must be
checked in the actual guest even where a package or applet configuration
suggests they are present. The revised account flow adds `BR2_PACKAGE_SUDO=y`
and pins BusyBox account and `clear` applets. Rebuild the revised config set
before packaging this lab so the kernel has netem and the target has `tc`.

## v86 validation gate

Boot the exact packaged kernel/rootfs pair and verify: automatic root-login
installation, email confirmation, level-account navigation, namespace
creation, narrow network command helpers, veth forwarding, DHCP lease plus
resolver, local DNS A/PTR, all nine named traceroute hops, loopback-only
listener visibility, and local HTTP response.
Command presence alone does not prove these behaviors.
