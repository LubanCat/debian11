#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ ! $SOC ]; then
    echo "---------------------------------------------------------"
    echo "please enter soc number:"
    echo "请输入要构建CPU的序号:"
    echo "[0] Exit Menu"
    echo "[1] rk3566/rk3568"
    echo "[2] rk3588/rk3588s"
    echo "---------------------------------------------------------"
    read input

    case $input in
        0)
            exit;;
        1)
            SOC=rk356x
            ;;
        2)
            SOC=rk3588
            ;;
        *)
            echo 'input soc number error, exit !'
            exit;;
    esac
    echo -e "\033[47;36m set SOC=$SOC...... \033[0m"
fi

if [ ! $TARGET ]; then
    echo "---------------------------------------------------------"
    echo "please enter TARGET version number:"
    echo "请输入要构建的根文件系统版本:"
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
            echo -e "\033[47;36m input TARGET version number error, exit ! \033[0m"
            exit;;
    esac
    echo -e "\033[47;36m set TARGET=$TARGET...... \033[0m"
fi

install_packages() {
    case $SOC in
        rk3399|rk3399pro)
        MALI=midgard-t86x-r18p0
        ISP=rkisp
        ;;
        rk3328|rk3528)
        MALI=utgard-450
        ISP=rkisp
        ;;
        rk3562)
        MALI=bifrost-g52-g13p0
        ISP=rkaiq_rk3562
        ;;
        rk356x|rk3566|rk3568)
        MALI=bifrost-g52-g13p0
        ISP=rkaiq_rk3568
        MIRROR=carp-rk356x
        ;;
        rk3588|rk3588s)
        ISP=rkaiq_rk3588
        MALI=valhall-g610-g13p0
        MIRROR=carp-rk3588
        ;;
    esac
}

case "${ARCH:-$1}" in
    arm|arm32|armhf)
        ARCH=armhf
        ;;
    *)
        ARCH=arm64
        ;;
esac

echo -e "\033[47;36m Building for $ARCH \033[0m"

if [ ! $VERSION ]; then
    VERSION="release"
fi

echo -e "\033[47;36m Building for $VERSION \033[0m"

if [ ! -e linaro-bullseye-$TARGET-alip-*.tar.gz ]; then
    echo "\033[41;36m Run mk-base-debian.sh first \033[0m"
    exit -1
fi

finish() {
    sudo umount $TARGET_ROOTFS_DIR/dev
    exit -1
}
trap finish ERR

echo -e "\033[47;36m Extract image \033[0m"
sudo rm -rf $TARGET_ROOTFS_DIR
sudo tar -xpf linaro-bullseye-$TARGET-alip-*.tar.gz

# packages folder
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rpf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

#GPU/CAMERA packages folder
install_packages
sudo mkdir -p $TARGET_ROOTFS_DIR/packages/install_packages
sudo cp -rpf packages/$ARCH/libmali/libmali-*$MALI*-x11*.deb $TARGET_ROOTFS_DIR/packages/install_packages
sudo cp -rpf packages/$ARCH/${ISP:0:5}/camera_engine_$ISP*.deb $TARGET_ROOTFS_DIR/packages/install_packages

# overlay folder
sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

# overlay-firmware folder
sudo cp -rpf overlay-firmware/* $TARGET_ROOTFS_DIR/

# overlay-debug folder
# adb, video, camera  test file
if [ "$VERSION" == "debug" ]; then
    sudo cp -rpf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

echo -e "\033[47;36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
    sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
    sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

ID=$(stat --format %u $TARGET_ROOTFS_DIR)

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

# Fixup owners
if [ "$ID" -ne 0 ]; then
    find / -user $ID -exec chown -h 0:0 {} \;
fi
for u in \$(ls /home/); do
    chown -h -R \$u:\$u /home/\$u
done

ln -sf /run/resolvconf/resolv.conf /etc/resolv.conf

echo "deb http://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free" >> /etc/apt/sources.list
echo "deb-src http://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free" >> /etc/apt/sources.list

if [ $MIRROR ]; then
	mkdir -p /etc/apt/keyrings
	curl -fsSL https://Embedfire.github.io/keyfile | gpg --dearmor -o /etc/apt/keyrings/embedfire.gpg
	chmod a+r /etc/apt/keyrings/embedfire.gpg
	echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/embedfire.gpg] https://cloud.embedfire.com/mirrors/ebf-debian carp-lbc main" | tee /etc/apt/sources.list.d/embedfire-lbc.list > /dev/null
	echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/embedfire.gpg] https://cloud.embedfire.com/mirrors/ebf-debian $MIRROR main" | tee /etc/apt/sources.list.d/embedfire-$MIRROR.list > /dev/null
fi

export LC_ALL=C.UTF-8

apt-get update
apt-get upgrade -y

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

export APT_INSTALL="apt-get install -fy --allow-downgrades"

echo -e "\033[47;36m ---------- LubanCat -------- \033[0m"
\${APT_INSTALL} toilet mpv fire-config u-boot-tools edid-decode logrotate

pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple setuptools wheel
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple python-periphery Adafruit-Blinka

passwd root <<IEOF
root
root
IEOF

systemctl disable apt-daily.service
systemctl disable apt-daily.timer

systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

# set localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
if [[ "$TARGET" == "gnome" ]]; then
    \${APT_INSTALL} fire-config-gui
    #Desktop background picture
    # ln -sf /usr/share/images/desktop-base/lubancat-wallpaper.png /etc/alternatives/desktop-background
elif [[ "$TARGET" == "xfce" ]]; then
    \${APT_INSTALL} fire-config-gui
    #Desktop background picture
    chown -hR cat:cat /home/cat/.config
    ln -sf /usr/share/images/desktop-base/lubancat-wallpaper.png /etc/alternatives/desktop-background
elif [[ "$TARGET" == "lxde" ]]; then
    \${APT_INSTALL} fire-config-gui
    #Desktop background picture
    # ln -sf /usr/share/desktop-base/images/lubancat-wallpaper.png 
elif [ "$TARGET" == "lite" ]; then
    \${APT_INSTALL} bluez bluez-tools
fi

apt install -fy --allow-downgrades /packages/install_packages/*.deb

echo -e "\033[47;36m ----- power management ----- \033[0m"
\${APT_INSTALL} pm-utils triggerhappy bsdmainutils
cp /etc/Powermanager/triggerhappy.service  /lib/systemd/system/triggerhappy.service

echo -e "\033[47;36m ----------- RGA  ----------- \033[0m"
\${APT_INSTALL} /packages/rga2/*.deb


if [[ "$TARGET" == "gnome" || "$TARGET" == "xfce" || "$TARGET" == "lxde" ]]; then
    echo -e "\033[47;36m ------ Setup Video---------- \033[0m"
    \${APT_INSTALL} gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-alsa \
    gstreamer1.0-plugins-base-apps qtmultimedia5-examples

    \${APT_INSTALL} /packages/mpp/*
    \${APT_INSTALL} /packages/gst-rkmpp/*.deb
    \${APT_INSTALL} /packages/gstreamer/*.deb
    \${APT_INSTALL} /packages/gst-plugins-base1.0/*.deb
    \${APT_INSTALL} /packages/gst-plugins-bad1.0/*.deb
    \${APT_INSTALL} /packages/gst-plugins-good1.0/*.deb
    \${APT_INSTALL} /packages/gst-plugins-ugly1.0/*.deb
    \${APT_INSTALL} /packages/gst-libav1.0/*.deb
elif [ "$TARGET" == "lite" ]; then
    echo -e "\033[47;36m ------ Setup Video---------- \033[0m"
    \${APT_INSTALL} /packages/mpp/*
    \${APT_INSTALL} /packages/gst-rkmpp/*.deb
fi

if [[ "$TARGET" == "gnome" ]]; then
    echo -e "\033[47;36m ----- Install Xserver------- \033[0m"
    \${APT_INSTALL} /packages/xserver/xserver-xorg-*.deb

    apt-mark hold xserver-xorg-core xserver-xorg-legacy
elif [[ "$TARGET" == "xfce" || "$TARGET" == "lxde" ]]; then
    echo -e "\033[47;36m ----- Install Xserver------- \033[0m"
    \${APT_INSTALL} /packages/xserver/*.deb

    apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy
fi

if [[ "$TARGET" == "gnome" || "$TARGET" == "xfce" || "$TARGET" == "lxde" ]]; then
    echo -e "\033[47;36m ----- Install Camera ----- - \033[0m"
    \${APT_INSTALL} cheese v4l-utils
    \${APT_INSTALL} /packages/libv4l/*.deb
    \${APT_INSTALL} /packages/cheese/*.deb

    echo -e "\033[47;36m ------ Install openbox ----- \033[0m"
    \${APT_INSTALL} /packages/openbox/*.deb

    echo -e "\033[47;36m ------ update chromium ----- \033[0m"
    \${APT_INSTALL} /packages/chromium/*.deb
fi

echo -e "\033[47;36m ------- Install libdrm ------ \033[0m"
\${APT_INSTALL} /packages/libdrm/*.deb

if [[ "$TARGET" == "gnome" || "$TARGET" == "xfce" || "$TARGET" == "lxde" ]]; then
    echo -e "\033[47;36m ------ libdrm-cursor -------- \033[0m"
    \${APT_INSTALL} /packages/libdrm-cursor/*.deb

    echo -e "\033[47;36m --------  blueman  ---------- \033[0m"
    \${APT_INSTALL} blueman
    echo exit 101 > /usr/sbin/policy-rc.d
    chmod +x /usr/sbin/policy-rc.d
    \${APT_INSTALL} blueman
    rm -f /usr/sbin/policy-rc.d

    \${APT_INSTALL} /packages/blueman/*.deb

    if [ "$VERSION" == "debug" ]; then
    echo -e "\033[47;36m ------ Install glmark2 ------ \033[0m"
    \${APT_INSTALL} /packages/glmark2/*.deb
    fi
fi

if [ -e "/usr/lib/aarch64-linux-gnu" ] ;
then
echo -e "\033[47;36m ------- move rknpu2 --------- \033[0m"
mv /packages/rknpu2/*.tar  /
fi

echo -e "\033[47;36m ----- Install rktoolkit ----- \033[0m"
\${APT_INSTALL} /packages/rktoolkit/*.deb

if [[ "$TARGET" == "gnome" || "$TARGET" == "xfce" || "$TARGET" == "lxde" ]]; then
    # set default xinput for fcitx
    sed -i 's/default/fcitx/g' /etc/X11/xinit/xinputrc

    echo -e "\033[47;36m Install Chinese fonts.................... \033[0m"
    # Uncomment zh_CN.UTF-8 for inclusion in generation
    sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
    echo "LANG=zh_CN.UTF-8" >> /etc/default/locale

    # Generate locale
    locale-gen

    # Export env vars
    echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc
    echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
    echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc

    source ~/.bashrc
fi

\${APT_INSTALL} ttf-wqy-zenhei fonts-aenigma
\${APT_INSTALL} xfonts-intl-chinese

# HACK debian11.3 to fix bug
\${APT_INSTALL} fontconfig --reinstall

# HACK to disable the kernel logo on bootup
#sed -i "/exit 0/i \ echo 3 > /sys/class/graphics/fb0/blank" /etc/rc.local

# mark package to hold
apt list --installed | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold

#---------------Custom Script--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
systemctl disable hostapd
rm /lib/systemd/system/wpa_supplicant@.service

#------remove unused packages------------
apt remove --purge -fy linux-firmware*

#---------------Clean--------------
if [ -e "/usr/lib/arm-linux-gnueabihf/dri" ] ;
then
    # Only preload libdrm-cursor for X
    sed -i "1aexport LD_PRELOAD=/usr/lib/arm-linux-gnueabihf/libdrm-cursor.so.1" /usr/bin/X
    cd /usr/lib/arm-linux-gnueabihf/dri/
    cp kms_swrast_dri.so swrast_dri.so rockchip_dri.so /
    rm /usr/lib/arm-linux-gnueabihf/dri/*.so
    mv /*.so /usr/lib/arm-linux-gnueabihf/dri/
elif [ -e "/usr/lib/aarch64-linux-gnu/dri" ];
then
    # Only preload libdrm-cursor for X
    sed -i "1aexport LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libdrm-cursor.so.1" /usr/bin/X
    cd /usr/lib/aarch64-linux-gnu/dri/
    cp kms_swrast_dri.so swrast_dri.so rockchip_dri.so /
    rm /usr/lib/aarch64-linux-gnu/dri/*.so
    mv /*.so /usr/lib/aarch64-linux-gnu/dri/
    rm /etc/profile.d/qt.sh
fi

rm -rf /home/$(whoami)
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/
rm -rf /sha256sum*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev

IMAGE_VERSION=$TARGET ./mk-image.sh 
