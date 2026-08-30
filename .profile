#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; export PATH
PS1='\W$ '
dmesg -n1
cd ~
clear
./install.sh
