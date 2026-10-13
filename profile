#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin:/bin
export PATH
[ -f /etc/profile.d/polylinux-colors.sh ] &&
    . /etc/profile.d/polylinux-colors.sh
USER=$(id -un)
export USER
case "$USER" in
    level[1-9]|level10) ;;
    *) return 0 ;;
esac
expected_ns=pln-l${USER#level}
current_ns=$(ip netns identify 2>/dev/null || true)
if [ "$current_ns" != "$expected_ns" ]; then
    printf 'ERROR: %s login is in network namespace %s (expected %s).\n' \
        "$USER" "${current_ns:-unidentified}" "$expected_ns" >&2
    exit 1
fi
PS1="$USER$ "
export PS1
nextlevel() { . /usr/bin/nextlevel; }
prevlevel() { . /usr/bin/prevlevel; }
cd "$HOME" || exit 1
box_line() { printf '* %-36.36s *\n' "$1"; }
echo '****************************************'
box_line 'PolyLinux: Networking'
box_line 'Read README.txt to begin.'
box_line 'Submit answers to the exercise'
box_line 'grading form.'
box_line 'Use nextlevel and prevlevel.'
echo '****************************************'
cat README.txt
