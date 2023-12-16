#!/bin/bash -e

source `pwd`/build/common.sh

usage() {
	echo -e "\nUsage: build/mk-image.sh -c rk3399 -t system -r debian/linaro-rootfs.img \n"
	echo -e "       build/mk-image.sh -c rk3399 -t dosboot -b vivid\n"
}

finish() {
	echo -e "\e[31m MAKE IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR

OLD_OPTIND=$OPTIND
while getopts "c:t:r:b:h" flag; do
	case $flag in
		c)
			CHIP="$OPTARG"
			;;
		t)
			TARGET="$OPTARG"
			;;
		r)
			ROOTFS_PATH="$OPTARG"
			;;
		b)
			BOARD="$OPTARG"
			;;
	esac
done
OPTIND=$OLD_OPTIND

if [ ! -f "${EXTLINUXPATH}/${CHIP}.conf" ]; then
	CHIP="rk3288"
fi

if [ ! $CHIP ] && [ ! $TARGET ]; then
	usage
	exit
fi

generate_dosboot_image() {
	BOOT=${OUT}/dosboot.img
	rm -rf ${BOOT}

	echo -e "\e[36m Generate DOS Boot image start\e[0m"

	# 128Mb
	mkfs.vfat -n "dosboot" -S 512 -C ${BOOT} $((128 * 1024))

	mmd -i ${BOOT} ::/extlinux
	mmd -i ${BOOT} ::/overlays

	mcopy -i ${BOOT} -s ${EXTLINUXPATH}/${CHIP}.conf ::/extlinux/extlinux.conf
	mcopy -i ${BOOT} -s ${OUT}/kernel/* ::

	echo -e "\e[36m Generate DOS Boot image : ${BOOT} success! \e[0m"
}

generate_system_image() {
	if [ ! -d "${IMGPATH}" ]; then
		echo -e "\e[31m CAN'T FIND IMGPATH \e[0m"
		usage
		exit
	fi

	if [ ! -f "${ROOTFS_PATH}" ]; then
		echo -e "\e[31m CAN'T FIND ROOTFS IMAGE \e[0m"
		usage
		exit
	fi

	# patch rootfs to disable oem/userdate
	MOUNTPOINT=`mktemp -d`
	mount $ROOTFS_PATH $MOUNTPOINT
	#sed -i "s/^PARTLABEL/#PARTLABEL/g" $MOUNTPOINT/etc/fstab && sync
	echo "PARTLABEL=dosboot	/boot	auto	defaults	0 2" >> $MOUNTPOINT/etc/fstab && sync
	umount $MOUNTPOINT

	[ -f ${SYSTEM} ] && rm -rf ${SYSTEM}

	echo "Generate System image : ${SYSTEM} !"

	# last dd rootfs will extend gpt image to fit the size,
	# but this will overrite the backup table of GPT
	# will cause corruption error for GPT
	IMG_ROOTFS_SIZE=$(stat -L --format="%s" ${ROOTFS_PATH})
	GPTIMG_MIN_SIZE=$(expr $IMG_ROOTFS_SIZE + \( ${IDBIMG_SIZE} + ${UBOOT_SIZE} + ${TRUST_SIZE} + ${MISC_SIZE} + ${BOOT_SIZE} + ${DOSBOOT_SIZE} + 35 \) \* 512)
	GPT_IMAGE_SIZE=$(expr $GPTIMG_MIN_SIZE \/ 1024 \/ 1024 + 10) # 2

	dd if=/dev/zero of=${SYSTEM} bs=1M count=0 seek=$GPT_IMAGE_SIZE

	if [ "$BOARD" == "vivid" ]; then
		parted -s ${SYSTEM} mklabel gpt
		parted -s ${SYSTEM} unit s mkpart idbloader ${IDBIMG_START} $(expr ${UBOOT_START} - 1)
		parted -s ${SYSTEM} unit s mkpart uboot ${UBOOT_START} $(expr ${TRUST_START} - 1)
		parted -s ${SYSTEM} unit s mkpart trust ${TRUST_START} $(expr ${MISC_START} - 1)
		parted -s ${SYSTEM} unit s mkpart misc ${MISC_START} $(expr ${BOOT_START} - 1)
		parted -s ${SYSTEM} unit s mkpart boot ${BOOT_START} $(expr ${DOSBOOT_START} - 1)
		parted -s ${SYSTEM} unit s mkpart dosboot ${DOSBOOT_START} $(expr ${ROOTFS_START} - 1)
		parted -s ${SYSTEM} set 6 boot on
		parted -s ${SYSTEM} -- unit s mkpart rootfs ${ROOTFS_START} -34s
	fi

	if [ "$CHIP" == "rk3328" ] || [ "$CHIP" == "rk3399pro" ]; then
		ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
	elif [ "$CHIP" == "rk3308" ] || [ "$CHIP" == "px30" ] || [ "$CHIP" == "rk3566" ] || [ "$CHIP" == "rk3568" ] || [ "$CHIP" == "rk3588s" ] || [ "$CHIP" == "rk3588" ] || [ "$CHIP" == "rk3399" ]; then
		ROOT_UUID="614e0000-0000-4b53-8000-1d28000054a9" #use 614e0000-0001 for dos, the origin is 614e0000-0000 for sd/emmc
	else
		ROOT_UUID="69DAD710-2CE4-4E3C-B16C-21A1D49ABED3"
	fi

	if [ "$BOARD" == "vivid" ]; then
		gdisk ${SYSTEM} <<EOF
x
c
7
${ROOT_UUID}
w
y
EOF
	fi

	# burn u-boot
	case ${CHIP} in
	px30 | rk3288 | rk3308 | rk3328 | rk3399 | rk3399pro )
		dd if=${OUT}/u-boot/idbloader.img of=${SYSTEM} seek=${IDBIMG_START} conv=notrunc
		dd if=${IMGPATH}/uboot.img of=${SYSTEM} seek=${UBOOT_START} conv=notrunc
		dd if=${IMGPATH}/trust.img of=${SYSTEM} seek=${TRUST_START} conv=notrunc
		dd if=${MISCIMG} of=${SYSTEM} seek=${MISC_START} conv=notrunc
		dd if=${IMGPATH}/boot.img of=${SYSTEM} seek=${BOOT_START} conv=notrunc
		;;
	rk3566 | rk3568 | rk3588s | rk3588)
		dd if=${OUT}/u-boot/idbloader.img of=${SYSTEM} seek=${LOADER1_START} conv=notrunc
		dd if=${OUT}/u-boot/u-boot.itb of=${SYSTEM} seek=${LOADER2_START} conv=notrunc
		;;
	*)
		;;
	esac

	# burn dosboot image
	dd if=${OUT}/dosboot.img of=${SYSTEM} conv=notrunc seek=${DOSBOOT_START}

	# burn rootfs image
	dd if=${ROOTFS_PATH} of=${SYSTEM} conv=notrunc,fsync seek=${ROOTFS_START}


	# restore 
	mount $ROOTFS_PATH $MOUNTPOINT
	#sed -i "s/^#PARTLABEL/PARTLABEL/g" $MOUNTPOINT/etc/fstab && sync
	sed -i '/^PARTLABEL=dosboot/d' $MOUNTPOINT/etc/fstab && sync
	umount $MOUNTPOINT

	# compress img
	echo ""
	echo -e "\e[36m compress image ${SYSTEM} start... \e[0m"
	xz -zk ${SYSTEM} && sync
	echo -e "\e[36m compress image ${SYSTEM}.xz completed \e[0m"
}

if [ "$TARGET" = "dosboot" ]; then
	generate_dosboot_image
elif [ "$TARGET" == "system" ]; then
	generate_system_image
fi
