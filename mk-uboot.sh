#!/bin/bash -e

source `pwd`/build/common.sh

finish() {
        echo -e "\e[31m MAKE U-BOOT FAILED.\e[0m"
        exit -1
}
trap finish ERR

cd ${LOCALPATH}/u-boot
echo -e "\e[36m u-boot build start! \e[0m"

if [ ! -f ${OUT}/u-boot/rk3399_loader_v1.28.126.bin ]; then
	./make.sh loader ../rkbin/RKBOOT/RK3399MINIALL.ini
	mv rk3399_loader_v1.28.126.bin ${OUT}/u-boot/
fi
if [ ! -f ${OUT}/u-boot/idbloader.img ]; then
	tools/mkimage -n rk3399 -T rksd -d ../rkbin/bin/rk33/rk3399_ddr_666MHz_v1.28.bin idbloader.img
	cat ../rkbin/bin/rk33/rk3399_miniloader_v1.26.bin >> idbloader.img
	mv idbloader.img ${OUT}/u-boot/
fi

if [ ! -f ${OUT}/u-boot/spinor/rk3399_loader_spinor_v1.28.114.bin ]; then
	./make.sh loader ../rkbin/RKBOOT/RK3399MINIALL_SPINOR.ini
	mv rk3399_loader_spinor_v1.28.114.bin ${OUT}/u-boot/spinor/
fi
if [ ! -f ${OUT}/u-boot/spinor/idbloader-spinor.img ]; then
	tools/mkimage -n rk3399 -T rkspi -d ../rkbin/bin/rk33/rk3399_ddr_666MHz_v1.28.bin idbloader-spi.img
	cat ../rkbin/bin/rk33/rk3399_miniloader_spinor_v1.14.bin >> idbloader-spinor.img
	mv idbloader-spinor.img ${OUT}/u-boot/spinor/
fi

# generate uboot and repack uboot.img and trust.img for uboot-trust-spinor image
./make.sh ${UBOOT_NOR_CONFIG}
./make.sh uboot --sz-uboot 2048K 1
./make.sh trust --sz-trust 1024K 1

cat > spi.ini <<EOF
[System]
FwVersion=18.08.03
BLANK_GAP=1
FILL_BYTE=0
[UserPart1]
Name=IDBlock
Flag=0
Type=2
File=../rkbin/bin/rk33/rk3399_ddr_666MHz_v1.28.bin,../rkbin/bin/rk33/rk3399_miniloader_spinor_v1.14.bin
PartOffset=0x40
PartSize=0x7C0
[UserPart2]
Name=uboot
Type=0x20
Flag=0
File=./uboot.img
PartOffset=0x800
PartSize=0x1000
[UserPart3]
Name=trust
Type=0x10
Flag=0
File=./trust.img
PartOffset=0x1800
PartSize=0x800
EOF

$LOCALPATH/build/tools/firmwareMerger -P spi.ini ${OUT}/u-boot/spinor/
#mv ${OUT}/u-boot/spinor/Firmware.img ${OUT}/u-boot/spinor/uboot-trust-spinor_`date +%Y%m%d%H%M`.img
#mv ${OUT}/u-boot/spinor/Firmware.md5 ${OUT}/u-boot/spinor/uboot-trust-spinor_`date +%Y%m%d%H%M`.md5
mv ${OUT}/u-boot/spinor/Firmware.img ${OUT}/u-boot/spinor/uboot-trust-spinor_`date +%Y%m%d`.img
mv ${OUT}/u-boot/spinor/Firmware.md5 ${OUT}/u-boot/spinor/uboot-trust-spinor_`date +%Y%m%d`.md5

cd $LOCALPATH
# make rk uboot/trust.img
./build.sh uboot && ./build.sh firmware
echo -e "\e[36m u-boot build success! \e[0m"
