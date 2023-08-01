#!/bin/bash -e

if [[ "$RELEASE" == "stretch" || "$RELEASE" == "9" ]]; then
	RELEASE='stretch'
elif [[ "$RELEASE" == "buster" || "$RELEASE" == "10" ]]; then
	RELEASE='buster'
elif [[ "$RELEASE" == "bullseye" || "$RELEASE" == "11" ]]; then
	RELEASE='bullseye'
else
    echo -e "\033[41;36m please input the os type: stretch, buster or bullseye...... \033[0m"
	exit
fi

echo "VERSION="$RK_ROOTFS_DEBUG "TARGET="$RK_ROOTFS_TARGET "SOC="$SOC "./mk-"$RELEASE"-rootfs.sh"

./mk-"$RELEASE"-rootfs.sh
