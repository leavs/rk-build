#!/bin/bash -e

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

BOARD=$1
DEFCONFIG=""
DTB=""
KERNELIMAGE=""
CHIP=""
UBOOT_DEFCONFIG=""

case ${BOARD} in
	"tb-rk3399prod")
		DEFCONFIG=rockchip_linux_defconfig
		UBOOT_DEFCONFIG=rk3399pro_defconfig
		DTB=rk3399pro-toybrick-prod-linux.dtb
		export ARCH=arm64
		export CROSS_COMPILE=aarch64-linux-gnu-
		CHIP="rk3399pro"
		;;
	*)
		echo "board '${BOARD}' not supported!"
		exit -1
		;;
esac

#build on native arm64
if [ "X$(uname -m)" == "Xaarch64" -a "X${ARCH}" == "Xarm64" ]; then
        unset ARCH
        unset CROSS_COMPILE
fi
