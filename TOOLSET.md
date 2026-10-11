# Toolset and guest requirements

## Learner-facing commands

`ip`, `ping`, `ss`, `traceroute`, `nslookup`, `udhcpc`, and `curl`.
Basic shell commands (`cat`, `printf`, `grep`, `awk`, `sed`) support inspection
and resolver edits. The prototype grants root in each disposable level
namespace so learners can configure interfaces and routes directly.

## Installer and service dependencies

`ip` must support `netns`, `link`, `addr`, `route`, and `-n`. The guest also
needs `dnsmasq` for isolated DHCP/DNS fixtures and BusyBox `httpd` for local
HTTP fixtures. The installer requires `sha256sum`, `cut`, `tr`, `awk`, `sed`,
`grep`, `sleep`, `id`, and standard POSIX shell utilities.

The kernel must support `CONFIG_NET_NS`, `CONFIG_VETH`, IPv4 forwarding,
ICMP Time Exceeded replies, and the namespace-specific resolver bind mounts
used by `ip netns exec`. Confirm these in the exact v86 image.

The preserved `basic-compression-networking` baseline has `ip` and `ping` in
its required-command manifest. Its saved Buildroot configuration disables
`curl` and `dnsmasq`; BusyBox `httpd` and `udhcpd` are disabled in its saved
BusyBox configuration. `ss`, `traceroute`, `nslookup`, and `udhcpc` must be
checked in the actual guest even where a package or applet configuration
suggests they are present. A new baseline configuration is required for live
release of this prototype.

## v86 validation gate

Boot the exact packaged kernel/rootfs pair and verify: namespace creation,
veth forwarding, DHCP lease plus resolver, local DNS A/PTR, all nine named
traceroute hops, loopback-only listener visibility, and local HTTP response.
Command presence alone does not prove these behaviors.
