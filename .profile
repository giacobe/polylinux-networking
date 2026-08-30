#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; export PATH
PS1='\W$ '
dmesg -n1
cd ~
clear

mkdir -p /mnt/shared
attempt=0
while ! mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/shared 2>/dev/null
do
	attempt=$((attempt + 1))
	if [ "$attempt" -ge 10 ]; then
		echo "Warning; could not mount shared folder after 10 attempts"
		break
	fi
	sleep 1
done

./install.sh

DAILY_HASH=$(cat /root/.daily_hash)
VM1_OCTET=$(( (0x$(echo "$DAILY_HASH" | cut -c1-4) % 253) + 2 ))
if [ "$VM1_OCTET" -eq 1 ]; then VM1_OCTET=3; fi

ip addr add 192.168.50.$VM1_OCTET/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.50.1

su -l level1
