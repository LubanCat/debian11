#!/bin/bash -e

TARGET_ROOTFS_DIR=./binary
ROOTFSIMAGE=linaro-$IMAGE_VERSION-rootfs.img
EXTRA_SIZE_MB=200
IMAGE_SIZE_MB=$(( $(sudo du -sh -m ${TARGET_ROOTFS_DIR} | cut -f1) + ${EXTRA_SIZE_MB} ))


echo Making rootfs!

if [ -e ${ROOTFSIMAGE} ]; then
	rm ${ROOTFSIMAGE}
fi

# for script in ./post-build.sh ../device/rockchip/common/post-build.sh; do
# 	[ -x $script ] || continue
# 	sudo $script "$(realpath "$TARGET_ROOTFS_DIR")"
# done

sudo ./add-build-info.sh ${TARGET_ROOTFS_DIR}

dd if=/dev/zero of=${ROOTFSIMAGE} bs=1M count=0 seek=${IMAGE_SIZE_MB}

sudo mkfs.ext4 -d ${TARGET_ROOTFS_DIR} ${ROOTFSIMAGE}

echo Rootfs Image: ${ROOTFSIMAGE}
