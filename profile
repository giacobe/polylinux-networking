#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; export PATH
PS1='\W$ '
cd ~
clear
echo "********************************************************************"
echo "* Welcome to the PolyLinux Networking Lab. Solve each level by *"
echo "* following the instructions. ULTRON has been secretely trying to *"
echo "* gain access to Avengers tower and we need you to see whats going on. *"
echo "* To change to the next level, type the command 'nextlevel'.	*"
echo "* To change to the previous level, type the command 'prevlevel'.	*"
echo "********************************************************************"
echo "* Level	: "$USER
cat README.txt
