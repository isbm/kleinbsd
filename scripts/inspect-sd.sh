#!/usr/bin/env sh

set -eu

printf '%s\n' "Block devices:"
lsblk
printf '%s\n' ""
printf '%s' "FAT partition to inspect, e.g. /dev/sdd1: "
read -r PART

case "${PART}" in
	/dev/sd[a-z][0-9]|/dev/mmcblk[0-9]p[0-9]|/dev/nvme[0-9]n[0-9]p[0-9]) ;;
	*)
		printf '%s\n' "Refusing suspicious partition path: ${PART}"
		exit 1
		;;
esac

if [ ! -b "${PART}" ]; then
	printf '%s\n' "Not a block device: ${PART}"
	exit 1
fi

printf '%s\n' ""
printf '%s\n' "FAT root files:"
sudo mdir -i "${PART}" ::

printf '%s\n' ""
printf '%s\n' "Required Raspberry Pi firmware files:"
for file in start4.elf start.elf fixup4.dat fixup.dat bootcode.bin netbsd.img; do
	if sudo mdir -i "${PART}" ::"${file}" >/dev/null 2>&1; then
		printf '%s\n' "  present: ${file}"
	else
		printf '%s\n' "  MISSING: ${file}"
	fi
done

printf '%s\n' ""
printf '%s\n' "config.txt:"
sudo mtype -i "${PART}" ::config.txt || true

printf '%s\n' ""
printf '%s\n' "cmdline.txt:"
sudo mtype -i "${PART}" ::cmdline.txt || true

printf '%s\n' ""
printf '%s\n' "Broadcom DTBs:"
sudo mdir -i "${PART}" ::dtb/broadcom || true
