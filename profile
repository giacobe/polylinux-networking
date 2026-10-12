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
current_ns=$(ip netns identify "$$" 2>/dev/null || true)
if [ "$current_ns" != "$expected_ns" ]; then
    echo "Enter this account with nextlevel or prevlevel." >&2
    exit 1
fi
PS1="$USER$ "
export PS1
nextlevel() { . /usr/bin/nextlevel; }
prevlevel() { . /usr/bin/prevlevel; }
cd "$HOME" || exit 1
echo 'PolyLinux: Networking from the Command Line'
echo 'Use nextlevel and prevlevel to move between accounts.'
echo 'Submit answers through the exercise grading form.'
cat README.txt
