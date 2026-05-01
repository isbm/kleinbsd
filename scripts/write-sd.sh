#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

PROFILE_IMAGES_DIR=$(profile_image_dir)
IMAGE=${IMAGE:-"${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img"}

if [ ! -f "${IMAGE}" ]; then
	printf '%s\n' "Image not found: ${IMAGE}"
	printf '%s\n' "Run make image first."
	exit 1
fi

printf '%s\n' "Selected profile: ${PROFILE}"
printf '%s\n' "Image: ${IMAGE}"
printf '%s\n' ""

# Find removable candidates (exclude system disk, NVMe, loops)
candidates=$(lsblk -e 7 -nrpo NAME,SIZE,TYPE 2>/dev/null | \
	awk '$3 == "disk" { print $1, $2 }' | \
	grep -v '/dev/sda\|/dev/nvme\|/dev/loop')
if [ -z "${candidates}" ]; then
	printf '%s\n' "lsblk:"
	lsblk -e 7
	printf '%s\n' ""
fi
printf '%s\n' "Removable devices:"
printf '%s\n' "${candidates}" | while read -r dev size; do
	printf '%s\n' "  ${dev}  (${size})"
done
printf '%s\n' ""
printf '%s' "Device to overwrite: "
read -r DEVICE

case "${DEVICE}" in
	/dev/sd[a-z]|/dev/mmcblk[0-9]|/dev/nvme[0-9]n[0-9]) ;;
	*)
		printf '%s\n' "Refusing suspicious device path: ${DEVICE}"
		printf '%s\n' "Use a whole disk like /dev/sdd, /dev/mmcblk0, or /dev/nvme0n1."
		exit 1
		;;
esac

if [ ! -b "${DEVICE}" ]; then
	printf '%s\n' "Not a block device: ${DEVICE}"
	exit 1
fi

printf '%s\n' ""
printf '%s\n' "About to overwrite ${DEVICE} with ${IMAGE}."
printf '%s\n' "All data on ${DEVICE} will be destroyed."
printf '%s' "Type the device path again to confirm: "
read -r CONFIRM

if [ "${CONFIRM}" != "${DEVICE}" ]; then
	printf '%s\n' "Confirmation mismatch; aborting."
	exit 1
fi

printf '%s\n' "Unmounting mounted partitions under ${DEVICE}..."
lsblk -nrpo NAME,MOUNTPOINT "${DEVICE}" | while read -r name mountpoint; do
	if [ -n "${mountpoint}" ]; then
		printf '%s\n' "Unmounting ${name} from ${mountpoint}"
		sudo umount "${name}"
	fi
done

printf '%s\n' "Writing image..."
sudo dd if="${IMAGE}" of="${DEVICE}" bs=4M conv=fsync status=progress
sync
printf '%s\n' "Unmounting partitions under ${DEVICE} ..."
lsblk -nrpo NAME,MOUNTPOINT "${DEVICE}" | while read -r name mountpoint; do
	if [ -n "${mountpoint}" ]; then
		sudo umount "${name}" 2>/dev/null || true
	fi
done
printf '%s\n' "Done. Safe to remove."
