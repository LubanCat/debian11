#!/bin/bash -e

if [ ! $TARGET ]; then
	echo "---------------------------------------------------------"
	echo "please enter desktop type number:"
	echo "请输入要构建桌面的序号:"
	echo "[0] Exit Menu"
	echo "[1] xfce"
	echo "[2] lxde"
	echo "[3] gnome"
	echo "[4] lite"
	echo "---------------------------------------------------------"
	read input

	case $input in
		0)
			exit;;
		1)
			TARGET=xfce
			;;
		2)
			TARGET=lxde
			;;
		3)
			TARGET=gnome
			;;
		4)
			TARGET=lite
			;;
		*)
			echo 'input desktop type error, exit !'
			exit;;
	esac
fi

if [[ "$RELEASE" == "stretch" || "$RELEASE" == "9" ]]; then
	RELEASE='stretch'
elif [[ "$RELEASE" == "buster" || "$RELEASE" == "10" ]]; then
	RELEASE='buster'
elif [[ "$RELEASE" == "bullseye" || "$RELEASE" == "11" ]]; then
	RELEASE='bullseye'
else
	RELEASE='bullseye'
	echo -e "\033[47;36m set default RELEASE=bullseye...... \033[0m"
fi

if [ "$ARCH" == "armhf" ]; then
	ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
	ARCH='arm64'
else
	ARCH="arm64"
	echo -e "\033[47;36m set default ARCH=arm64...... \033[0m"
fi

if [ "$TARGET" == "lite" ]; then
	BUILD_VERSION='base'
	echo -e "\033[47;36m set TARGET=lite, use $RELEASE-base-$ARCH to build ...... \033[0m"
else
	BUILD_VERSION=$TARGET
fi

if [ -e linaro-$RELEASE-$TARGET-alip-*.tar.gz ]; then
	rm linaro-$RELEASE-$TARGET-alip-*.tar.gz
fi


cd ubuntu-build-service/$RELEASE-$BUILD_VERSION-$ARCH

echo -e "\033[47;36m Staring Download...... \033[0m"

make clean

./configure

make

DATE=$(date +%Y%m%d)
if [ -e linaro-$RELEASE-alip-*.tar.gz ]; then
	sudo chmod 0666 linaro-$RELEASE-alip-*.tar.gz
	mv linaro-$RELEASE-alip-*.tar.gz ../../linaro-$RELEASE-$TARGET-alip-$DATE.tar.gz
else
	echo -e "\e[41;31m Failed to run livebuild, please check your network connection. \e[0m"
fi
