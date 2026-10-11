# Level design

All generated addresses are confined to the disposable VM. The level seed is
SHA-256 of exact UTF-8 bytes `email + ISO_date + exercise_password + level_password`.
Labeled SHA-256 derivations vary interface names, host values, ports, service
names, codes, and the Level 9 code position. Formats and objectives stay fixed.

| Level | Primary skill | Live fixture and learner action | Exact answer shape |
| --- | --- | --- | --- |
| 1 | Interface state | A down veth in the learner namespace; bring it up and inspect links. | `interface-name` |
| 2 | Manual IPv4 | An unnumbered veth; apply the assigned address and inspect it. | `IPv4/prefix` |
| 3 | Subnet mask | A /24 site and seeded host count; compute the smallest fitting prefix and assign the first host. | `network/prefix` |
| 4 | VLSM | A documentation /24 split among 90, 50, and 20-host segments; assign the first Sensors address. | `network/prefix` |
| 5 | Default gateway | A numbered interface without a default route; add the router as gateway. | Gateway IPv4 |
| 6 | DNS configuration | A bad per-namespace resolver file and a local DNS service; correct the resolver and resolve a seeded name. | Resolved IPv4 |
| 7 | DHCP | An unnumbered veth and local DHCP service with a deterministic MAC reservation; request a lease. | `lease-IPv4\|gateway-IPv4\|DNS-IPv4` |
| 8 | Reachability and listeners | A reachable peer plus a web listener bound to learner loopback; ping, inspect `ss`, and curl. | Decimal port |
| 9 | Traceroute and PTR | Eight lyric-named hops plus one code hop, inserted after lyric line 2–6; repair the route and compare numeric/named traces. | Twelve lowercase hex characters |
| 10 | DNS and HTTP | A peer namespace with local DNS and HTTP; resolve then fetch `/code.txt`. | `resolved-IPv4\|HTTP-status\|12-character-code` |

## Level 9 invariant

The first and last visible story hops are lyric lines. The nine visible lines
consist of the first eight lines of Penn State's current alma mater and one
seeded PolyLab code line. The code position changes with the learner and date.
Router and destination IPs are in `198.51.100.0/24`; each adjacent link uses
its own /30. The destination is `trace.lab.test`. The first router supplies
local forward and reverse DNS. No public network or second VM is involved.

## Prototype boundaries

The namespace infrastructure and its DNS/HTTP files are intentional live
evidence, not a separate answer store. The client offers no correctness
decision. The source-only `verify.sh` must be excluded from a future VM
payload. Every level is independent of the others' answers and mutable state.
