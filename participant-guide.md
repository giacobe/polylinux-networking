---
title: "Networking from the Command Line"
short_title: "Networking"
panel_title: "Learning Path"
form_url: ""

---

# Networking from the Command Line

This prototype runs in one disposable Linux virtual machine. Each level has
an isolated network so changes to an address, route, or resolver in one level
do not disturb the others. An internal router, DNS/DHCP service, and web
service support the later exercises. No public internet access is required.

The prototype is entered from the root shell with `sh labctl enter 1` after
installation. Read the level's `README.txt`. Use `nextlevel` and `prevlevel`
to move freely; completing one level is not required to enter another.

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
9. Compare numeric and named traces. The extra line contains the PolyLab
   code; it is not a lyric line.
10. Resolve the service name before requesting its HTTP path.

## Troubleshooting

If a level shell is closed, re-enter it with `sh labctl enter N` from the
guest root shell. The VM is disposable: restarting it recreates the seeded
scenario for the same email and date. An incomplete or missing named trace
should be reported with the level number and output; route and DNS behavior
must be validated in the packaged guest.
