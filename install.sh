#!/bin/sh

# Set passwords for the system and for each level
export SYSTEM_PASSWORD="systemPassword"
levelPasswordRoot="levelPassword"

#Host System date and time
export currentDate=$(date +"%m-%d-%Y" | head -n 1)
confirmation="no"
while [ "$confirmation" != "y" ]
	do
		export USER_ID=""
		echo "Enter your email address: "
		read USER_ID
		read -p "Is $USER_ID your email address? (y/n)" confirmation
		done

export USER_HASH=$(echo -n "$USER_ID" | md5sum)
echo "$USER_HASH" > /root/.user_hash
echo "$USER_HASH" | cut -d' ' -f1 > /mnt/shared/user_hash

export DAILY_HASH=$(echo -n "$USER_ID$currentDate" | md5sum | cut -d' ' -f1)
echo "$DAILY_HASH" > /root/.daily_hash
echo "$DAILY_HASH" > /mnt/shared/daily_hash

if [ ! -f /root/.levels_built ]; then
	mkdir /home
	cp profile /etc
	cp nextlevel /usr/bin
	cp prevlevel /usr/bin
	chmod 755 /usr/bin/nextlevel
	chmod 755 /usr/bin/prevlevel

	export origInstallDir=$(pwd)

	echo -n Building 8 levels [
	for levelnumber in 1 2 3 4 5 6 7 8
	do
		levelsetname="basic"
		echo -n $levelnumber
		export levelToBuild=$levelsetname$levelnumber
		newPass=$levelPasswordRoot$levelnumber
		export level_HASH=$(echo -n "$USER_ID$currentDate$SYSTEM_PASSWORD$newPass" | sha256sum | grep -o '^\S\+')
		export readMeLocation=$levelToBuild"/README.txt"
		adduser -D -g "User" $levelToBuild
		passwd -d $levelToBuild > /dev/null 2>&1
		mkdir -p /home/$levelToBuild
		echo "* Create date: " $currentDate > /home/$readMeLocation
		echo "* User: " $USER_ID >> /home/$readMeLocation
		echo "***************************************" >> /home/$readMeLocation
		echo "* Instructions for this level:		*" >> /home/$readMeLocation
		./$levelsetname$levelnumber.sh&
		chown -R $levelToBuild:$levelToBuild /home/$levelToBuild
		chmod -R o-rx /home/$levelToBuild
		cd $origInstallDir
	done
	echo ]
	echo done
	touch /root/.levels_built
fi
