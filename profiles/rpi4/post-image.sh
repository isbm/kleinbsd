#!/usr/bin/env sh
# post-image.sh — rpi4 profile
# Called by build-image.sh after decompressing the built arm64.img.
# Injects RPi4 UEFI firmware (pftf/RPi4) into the FAT boot partition
# so the Pi4 boot ROM finds valid firmware and chainloads NetBSD.
#
# Also callable standalone: ./profiles/rpi4/post-image.sh some-image.img

set -eu

if [ $# -ne 1 ]; then
	printf '%s\n' "usage: $0 IMAGE"
	exit 1
fi

IMAGE=$1

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)

. "${PROJECT_DIR}/configs/rpi4-uefi.sh" 2>/dev/null || true

CACHE_DIR="${PROJECT_DIR}/images/rpi4-uefi"
VENDOR_DIR="${PROJECT_DIR}/vendor/rpi4-uefi"
WORK_DIR="${PROJECT_DIR}/work/rpi4-post-image"
MNT="${WORK_DIR}/mnt"

UEFI_FW_VERSION="${UEFI_FW_VERSION:-1.51}"
UEFI_FW_URL="${UEFI_FW_URL:-https://github.com/pftf/RPi4/releases/download/v${UEFI_FW_VERSION}/RPi4_UEFI_Firmware_v${UEFI_FW_VERSION}.zip}"
UEFI_FW_SHA256="${UEFI_FW_SHA256:-000b6c518e83bb93262ed6b264a0e9498509c46513dabf58c0dbb73d4c2e7c18}"
UEFI_FW_FNAME="RPi4_UEFI_Firmware_v${UEFI_FW_VERSION}.zip"

# Lookup order: images/ (cache) -> vendor/ (mirrored) -> download
UEFI_FW_ZIP=""
for candidate in "${CACHE_DIR}/${UEFI_FW_FNAME}" "${VENDOR_DIR}/${UEFI_FW_FNAME}"; do
	if [ -f "${candidate}" ]; then
		UEFI_FW_ZIP="${candidate}"
		break
	fi
done

mkdir -p "${CACHE_DIR}" "${WORK_DIR}" "${MNT}"

cleanup() {
	trap - EXIT
	sudo umount "${MNT}" 2>/dev/null || true
	rmdir "${MNT}" 2>/dev/null || true
	if [ -n "${LOOP_DEV:-}" ]; then
		sudo losetup -d "${LOOP_DEV}" 2>/dev/null || true
	fi
}
trap cleanup EXIT

# ---- locate / download UEFI firmware ---------------------------------

if [ -z "${UEFI_FW_ZIP}" ]; then
	printf '%s\n' "Downloading RPi4 UEFI firmware v${UEFI_FW_VERSION} ..."
	UEFI_FW_ZIP="${CACHE_DIR}/${UEFI_FW_FNAME}"
	curl -L --fail --output "${UEFI_FW_ZIP}.tmp" "${UEFI_FW_URL}"
	if [ -n "${UEFI_FW_SHA256}" ]; then
		actual=$(sha256sum "${UEFI_FW_ZIP}.tmp" | awk '{print $1}')
		if [ "${actual}" != "${UEFI_FW_SHA256}" ]; then
			printf '%s\n' "UEFI firmware checksum mismatch:"
			printf '%s\n' "  expected: ${UEFI_FW_SHA256}"
			printf '%s\n' "  actual:   ${actual}"
			rm -f "${UEFI_FW_ZIP}.tmp"
			exit 1
		fi
		printf '%s\n' "  checksum OK"
	fi
	mv "${UEFI_FW_ZIP}.tmp" "${UEFI_FW_ZIP}"
else
	printf '%s\n' "Using UEFI firmware: ${UEFI_FW_ZIP}"
	if [ -n "${UEFI_FW_SHA256}" ]; then
		actual=$(sha256sum "${UEFI_FW_ZIP}" | awk '{print $1}')
		if [ "${actual}" != "${UEFI_FW_SHA256}" ]; then
			printf '%s\n' "UEFI firmware checksum mismatch:"
			printf '%s\n' "  expected: ${UEFI_FW_SHA256}"
			printf '%s\n' "  actual:   ${actual}"
			printf '%s\n' "  Remove ${UEFI_FW_ZIP} and retry."
			exit 1
		fi
	fi
fi

# ---- mount FAT boot partition ---------------------------------------

printf '%s\n' "Mounting FAT partition from ${IMAGE} ..."
LOOP_DEV=$(sudo losetup -f --show -P "${IMAGE}")
sleep 1
sudo partprobe "${LOOP_DEV}" 2>/dev/null || true
sleep 1

FAT_PART=""
for part in "${LOOP_DEV}p1" "${LOOP_DEV}p2" "${LOOP_DEV}p3"; do
	if [ -b "${part}" ]; then
		ptype=$(sudo blkid -s TYPE -o value "${part}" 2>/dev/null || true)
		if [ "${ptype}" = "vfat" ]; then
			FAT_PART="${part}"
			break
		fi
	fi
done

if [ -z "${FAT_PART}" ]; then
	FAT_OFFSET=16777216
	printf '%s\n' "Falling back to offset mount at ${FAT_OFFSET}"
	sudo mount -o loop,offset="${FAT_OFFSET}" "${IMAGE}" "${MNT}"
else
	sudo mount "${FAT_PART}" "${MNT}"
fi

printf '%s\n' "FAT partition before injection:"
ls -la "${MNT}"/

# ---- inject UEFI firmware -------------------------------------------

printf '%s\n' "Injecting UEFI firmware v${UEFI_FW_VERSION} ..."
sudo unzip -o "${UEFI_FW_ZIP}" -d "${MNT}"

printf '%s\n' "FAT partition after injection:"
ls -la "${MNT}"/

# ---- done -----------------------------------------------------------

sudo umount "${MNT}"
rmdir "${MNT}" || true
sudo losetup -d "${LOOP_DEV}" 2>/dev/null || true
LOOP_DEV=""
trap - EXIT

printf '%s\n' "UEFI firmware injected — image is RPi4-bootable: ${IMAGE}"
