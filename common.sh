#!/bin/bash -e

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
TOOLPATH=${LOCALPATH}/rkbin/tools
EXTLINUXPATH=${LOCALPATH}/build/extlinux
IMGPATH=${LOCALPATH}/rockdev
PATH=$PATH:$TOOLPATH

export ARCH=arm64
#export CROSS_COMPILE=aarch64-linux-gnu-
DEFCONFIG=rockchip_vivid_linux_defconfig
UBOOT_DEFCONFIG=vivid_defconfig
UBOOT_NOR_CONFIG=vivid_nor
DTB=rk3399-vivid-unit-v13.dtb
TARGET_ROOTFS_IMG=$LOCALPATH/debian/linaro-rootfs.img
MISCIMG=$LOCALPATH/build/miscfiles/blank-misc.img
CHIP="rk3399"
BOARD="vivid"

[ ! -d ${OUT} ] && mkdir ${OUT}
[ ! -d ${OUT}/u-boot ] && mkdir ${OUT}/u-boot
[ ! -d ${OUT}/u-boot/spinor ] && mkdir ${OUT}/u-boot/spinor
[ ! -d ${OUT}/kernel ] && mkdir ${OUT}/kernel
[ ! -d ${OUT}/kernel/overlays ] && mkdir ${OUT}/kernel/overlays

SYSTEM=${OUT}/vivid-unit-debian-bullseye-xfce4-arm64-`date +%Y%m%d`.img

# UBOOT:4M
# TRUST:4M
# MISC: 4M
# BOOT: 64M
# DOSBOOT: 128M
# ROOTFS: -

IDBIMG_SIZE=8192
UBOOT_SIZE=8192
TRUST_SIZE=8192
MISC_SIZE=8192
BOOT_SIZE=131072
DOSBOOT_SIZE=262144

SYSTEM_START=0
IDBIMG_START=64
UBOOT_START=16384
TRUST_START=$(expr ${UBOOT_START} + ${UBOOT_SIZE})
MISC_START=$(expr ${TRUST_START} + ${TRUST_SIZE})
BOOT_START=$(expr ${MISC_START} + ${MISC_SIZE})
DOSBOOT_START=$(expr ${BOOT_START} + ${BOOT_SIZE})
ROOTFS_START=$(expr ${DOSBOOT_START} + ${DOSBOOT_SIZE})
