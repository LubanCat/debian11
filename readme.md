## 简介

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## 适用板卡

- 使用RK3566处理器的LubanCat板卡
- 使用RK3568处理器的LubanCat板卡
- 使用RK3588处理器的LubanCat板卡

## 安装依赖

构建主机环境最低要求Ubuntu20.04及以上版本，推荐使用Ubuntu20.04

```
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## 构建 Debian11 镜像（仅支持64bit）

- lite：控制台版，无桌面
- xfce：桌面版，使用xfce4桌面套件
- lxde：桌面版，使用lxde桌面套件
- gnome：桌面版，使用gnome桌面套件


#### step1.构建基础 Debian 系统。

```
# 运行以下脚本，根据提示选择要构建的版本
./mk-base-debian.sh
```
#### step2.添加 rk overlay 层,并打包linaro-rootfs镜像

```
# 根据提示选择要构建桌面版本和SOC版本

VERSION=debug ./mk-bullseye-rootfs.sh

```


---

## Cross Compile for ARM Debian

[Docker + Multiarch](http://opensource.rock-chips.com/wiki_Cross_Compile#Docker)

## Package Code Base

Please apply [those patches](https://github.com/rockchip-linux/rk-rootfs-build/tree/master/packages-patches) to release code base before rebuilding!

## License information

Please see [debian license](https://www.debian.org/legal/licenses/)

## FAQ

- noexec or nodev issue
noexec or nodev issue /usr/share/debootstrap/functions: line 1450:
../rootfs/ubuntu-build-service/bullseye-desktop-arm64/chroot/test-dev-null:
Permission denied E: Cannot install into target
...
mounted with noexec or nodev

Solution: mount -o remount,exec,dev xxx (xxx is the mount place), then rebuild it.
