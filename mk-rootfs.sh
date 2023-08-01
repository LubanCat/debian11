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


if [[ "$RK_ROOTFS_TARGET" == "lite" ]]; then
	echo "[ VERSION="$RK_ROOTFS_DEBUG "ARCH="$ARCH "SOC="$SOC "./mk-"$RELEASE"-lite.sh ]"
	VERSION=$RK_ROOTFS_DEBUG ARCH=$ARCH SOC=$SOC TARGET=$RK_ROOTFS_TARGET ./mk-$RELEASE-lite.sh
elif [[ "$RK_ROOTFS_TARGET" == "desktop" || "$RK_ROOTFS_TARGET" == "lxde" || "$RK_ROOTFS_TARGET" == "xfce" || "$RK_ROOTFS_TARGET" == "gnome" ]]; then
	echo "[ VERSION="$RK_ROOTFS_DEBUG "ARCH="$ARCH "SOC="$SOC "TARGET="$RK_ROOTFS_TARGET "./mk-"$RELEASE"-desktop.sh ]"
	VERSION=$RK_ROOTFS_DEBUG ARCH=$ARCH SOC=$SOC TARGET=$RK_ROOTFS_TARGET ./mk-$RELEASE-desktop.sh
else
    echo -e "\033[41;36m please input the TARGET type: lite, lxde, xfce, gnome or desktop... \033[0m "
    echo -e "\033[41;36m the default desktop is xfce ...... \033[0m"
fi
