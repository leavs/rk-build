#!/bin/bash -e

source `pwd`/build/common.sh

finish() {
        echo -e "\e[31m MAKE KERNEL FAILED.\e[0m"
        exit -1
}
trap finish ERR

cd $LOCALPATH

./build.sh kernel && ./build.sh firmware

cp ${LOCALPATH}/kernel/arch/arm64/boot/Image ${OUT}/kernel/
cp ${LOCALPATH}/kernel/arch/arm64/boot/dts/rockchip/${DTB} ${OUT}/kernel/
cp ${LOCALPATH}/kernel/arch/arm64/boot/dts/rockchip/${DTB} ${LOCALPATH}/u-boot/dts/kern.dtb
cp ${LOCALPATH}/kernel/arch/arm64/boot/dts/rockchip/overlay/*.dtbo ${OUT}/kernel/overlays/

# Change extlinux.conf according board
sed -e "s,fdt .*,fdt /$DTB,g" \
        -i ${EXTLINUXPATH}/${CHIP}.conf

./build/mk-image.sh -c ${CHIP} -t dosboot -b ${BOARD}

cd $LOCALPATH
