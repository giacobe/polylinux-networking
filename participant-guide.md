---
title: "Networking from the Command Line"
short_title: "Networking"
panel_title: "Learning Path"
form_url: ""

---

# Networking from the Command Line

This lab runs in one disposable Linux virtual machine. Each level account
has its own isolated network, so changes to an address, route, or resolver in
one level do not disturb the others. Internal DNS, DHCP, and web services
support later exercises. No public internet access is required.

At boot, the root login runs the installer automatically. Enter your email
address and confirm it; the lab uses that address and the exercise date to
generate your scenario. The installer displays an exercise code: the date's
`YYYYMMDD` digits converted from decimal to uppercase hexadecimal. Save that
code for the submission form. The installer signs you into `level1`. Read
`README.txt`, then use `nextlevel` and `prevlevel` to move freely among the
ten level accounts. Completing a level is not required to enter another.

Submit the requested value to the external exercise grading form when a form
is published. The VM does not tell you whether an answer is correct. Preserve
the exact punctuation, case, prefix length, and pipe separators requested in
each level's README.

## Command reference

| Command | What to inspect or change |
| --- | --- |
| `ip -br link` | Interface names and link state |
| `ip -4 addr` | IPv4 addresses and prefix lengths |
| `ip route` | Connected and default routes |
| `ip route get ADDRESS` | Route chosen for one destination |
| `udhcpc -i INTERFACE -n -q` | Request a DHCP lease |
| `ping -c 2 ADDRESS` | Test ICMP reachability |
| `ss -ltn` | Listening TCP sockets and bind addresses |
| `traceroute HOST` | Named intermediate hops |
| `traceroute -n HOST` | Numeric intermediate hops |
| `nslookup HOST` | Name and address resolution |
| `curl -i URL` | HTTP status, headers, and body |

## Hints

1. Link state and address assignment are separate. Bringing an interface up
   does not assign an IPv4 address.
2. The address in Level 2 comes from the given network and host number.
3. Include network and broadcast addresses when sizing a conventional IPv4
   subnet for a stated usable-host count.
4. Allocate the largest VLSM subnet first to avoid overlap.
5. A default route requires a next hop reachable on a connected subnet.
6. The resolver file for Level 6 is visible at `/etc/resolv.conf` within its
   shell. Test the configured server with `nslookup`.
7. Inspect the DHCP result in the address, route, and resolver views.
8. A successful ping does not tell you which TCP port a service listens on.
9. Your `.2` address and the `.1` router share a /30 link. Ping that router,
   then compare numeric and named traces. Reverse DNS maps hop IPs to full
   lyric names; partial fragments are not complete DNS names. Link delays
   accumulate in traceroute RTTs. The extra line contains the PolyLab code.
10. Resolve the service name before requesting its HTTP path.

## Troubleshooting

If you leave the level shell, log in as root again; root login restarts the
exercise. Restarting the disposable VM recreates the scenario for the same
email and date. On Level 9, `tracert` is a Windows command; use Linux
`traceroute`. The correct next hop is `198.51.100.1`, while `.2` is your own
interface. Use `nslookup` on a hop IP or a complete lyric name.
Report an incomplete trace with the level number and command output.
