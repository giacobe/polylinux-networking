# PolyLinux Networking

Ten account-based Linux networking levels run in one disposable VM. Levels
1–7 emphasize local configuration, Level 8 inspects a local service, Level 9
uses nine routed hops with reverse DNS, and Level 10 reaches an internal web
service. Each `levelN` account has its own network namespace.

## Boot and learner flow

The runtime payload includes `/root/.profile`, which runs `/root/install.sh`
on root login. The installer asks for and confirms the learner's email, records
an ISO exercise date, creates `level1` through `level10`, prepares a pending
`README.txt` in every home, and starts ten independent level builders. It
logs into `level1` when that level is ready. `nextlevel` and `prevlevel`
switch both the account and its network namespace. Login instructions come
from `/etc/profile`; the canonical color palette is installed in
`/etc/profile.d/polylinux-colors.sh`.

Learners can run `ip` and `udhcpc` in their own accounts. Read-only commands
run directly; the small root-owned helpers permit only the network changes
used by the relevant level. No answer checker or answer file is installed.

## Builder2 handoff

The complete baseline config set is in
[builder-config/networking-prototype-v1](builder-config/networking-prototype-v1).
It extends `basic-compression-networking` with DNS/DHCP, traceroute, curl,
BusyBox httpd and account applets, `sudo`, network namespaces, and veth.
Install or refresh it on the Linux build host:

`sh install-builder-config.sh --refresh /path/to/buildroot-builder2`

Then the human build operator runs Builder2 script 02 with
`--config networking-prototype-v1`. The resulting baseline must be checked
in the guest before publication.

Builder2 script 03 clones a Git repository and packages every file under
its selected payload directory. Use `--payload-subdir payload` for this lab.
The committed `payload/` tree contains only guest runtime files, including
the hidden `.profile`; it excludes `verify.sh`, `test.sh`, and builder
material. The source-only [test.sh](test.sh) checks that its copies match the
top-level runtime scripts. See [BASELINE.md](BASELINE.md) for the human-run
commands and validation gate.

## Source checks

`sh test.sh` performs nonprivileged deterministic and source checks on a
Linux development host. `sh live-test.sh` is a developer-only guest check
after a human build and installation. Neither test nor a Builder2 build has
been run against the revised image yet; the routed trace, account
permissions, DHCP, and login handoff still require an exact-image v86 test.
