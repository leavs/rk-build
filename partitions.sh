#!/bin/bash -e

# UBOOT:4M
# TRUST:4M
# MISC: 4M
# BOOT: 64M
# NVMEBOOT: 128M
# ROOTFS: -

IDBIMG_SIZE=8192
UBOOT_SIZE=8192
TRUST_SIZE=8192
MISC_SIZE=8192
BOOT_SIZE=131072
NVMEBOOT_SIZE=262144

SYSTEM_START=0
IDBIMG_START=64
UBOOT_START=16384
TRUST_START=$(expr ${UBOOT_START} + ${UBOOT_SIZE})
MISC_START=$(expr ${TRUST_START} + ${TRUST_SIZE})
BOOT_START=$(expr ${MISC_START} + ${MISC_SIZE})
NVMEBOOT_START=$(expr ${BOOT_START} + ${BOOT_SIZE})
ROOTFS_START=$(expr ${NVMEBOOT_START} + ${NVMEBOOT_SIZE})