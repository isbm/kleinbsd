#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

require_netbsd_tree

NBMAKE=$(nbmake_path)
if [ -z "${NBMAKE}" ]; then
	printf '%s\n' "Cannot find nbmake-${MACHINE} under ${OBJ_DIR}/tooldir.*/bin."
	printf '%s\n' "Run ./build-netbsd.sh first."
	exit 1
fi

jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '%s\n' 2)}
set -- $(build_machine_args)
KERN_SET=${KERN_SET:-kern-${KERNEL_CONFIG}}
LIVEIMAGE_DIR=${NETBSD_DIR}/${LIVEIMAGE_SUBDIR}
SOURCE_SETS=${OBJ_DIR}/releasedir/${RELEASE_MACHINE}/binary/sets
CUSTOM_SETS=${OBJ_DIR}/kleinbsd-sets/${PROFILE}
KERNEL=${OBJ_DIR}/sys/arch/${MACHINE}/compile/${KERNEL_CONFIG}/netbsd
RAW_IMAGE=${OBJ_DIR}/${LIVEIMAGE_SUBDIR}/${IMAGE_BASE}.img
PROFILE_IMAGES_DIR=$(profile_image_dir)
GZ_IMAGE=${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img.gz
LOG_DIR=${PROJECT_DIR}/logs/${PROFILE}
KERNEL_LOG=${LOG_DIR}/kernel-${KERNEL_CONFIG}.log
IMAGE_LOG=${LOG_DIR}/image.log

mkdir -p "${LOG_DIR}"

if [ -n "${PREBUILT_IMAGE_GZ}" ]; then
	mkdir -p "${PROFILE_IMAGES_DIR}"
	SOURCE_IMAGE_GZ=${OBJ_DIR}/releasedir/${RELEASE_MACHINE}/${PREBUILT_IMAGE_GZ}
	if [ ! -f "${SOURCE_IMAGE_GZ}" ]; then
		printf '%s\n' "Missing prebuilt image: ${SOURCE_IMAGE_GZ}"
		printf '%s\n' "Run make netbsd first."
		exit 1
	fi
	printf '%s\n' "Using prebuilt profile image: ${SOURCE_IMAGE_GZ}"
	rm -f "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img" "${GZ_IMAGE}"
	cp "${SOURCE_IMAGE_GZ}" "${GZ_IMAGE}"
	gzip -dc "${GZ_IMAGE}" > "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img"
	if [ "${POST_IMAGE}" != no ] && [ -x "${PROFILE_DIR}/post-image.sh" ]; then
		"${PROFILE_DIR}/post-image.sh" "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img"
		rm -f "${GZ_IMAGE}"
		gzip -n -9c "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img" > "${GZ_IMAGE}"
	fi
	printf '\n%s\n' "Built images:"
	ls -lh "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img" "${GZ_IMAGE}"
	exit 0
fi

"${PROJECT_DIR}/scripts/apply-kernel-config.sh"

printf '%s\n' "Building ${KERNEL_CONFIG} kernel"
printf '%s\n' "Kernel build log: ${KERNEL_LOG}"
if ! "${NETBSD_DIR}/build.sh" -U -u -j"${jobs}" -O "${OBJ_DIR}" "$@" kernel="${KERNEL_CONFIG}" >"${KERNEL_LOG}" 2>&1; then
	printf '%s\n' "Kernel build failed. Last log lines:"
	tail -80 "${KERNEL_LOG}"
	exit 1
fi

if [ ! -f "${KERNEL}" ]; then
	printf '%s\n' "Kernel not found after build: ${KERNEL}"
	exit 1
fi

if [ ! -d "${SOURCE_SETS}" ]; then
	printf '%s\n' "Missing release sets: ${SOURCE_SETS}"
	printf '%s\n' "Run ./build-netbsd.sh first."
	exit 1
fi

rm -rf "${CUSTOM_SETS}"
mkdir -p "${CUSTOM_SETS}" "${CUSTOM_SETS}/kernel-work" "${PROFILE_IMAGES_DIR}"

for setfile in "${SOURCE_SETS}"/*.tar.xz; do
	ln -s "${setfile}" "${CUSTOM_SETS}/$(basename -- "${setfile}")"
done

cp "${KERNEL}" "${CUSTOM_SETS}/kernel-work/netbsd"
( cd "${CUSTOM_SETS}/kernel-work" && tar -cpf - . ) | xz -9 > "${CUSTOM_SETS}/${KERN_SET}.tar.xz"
rm -rf "${CUSTOM_SETS}/kernel-work"

"${NBMAKE}" -C "${LIVEIMAGE_DIR}" cleandir
printf '%s\n' "Image build log: ${IMAGE_LOG}"
if ! "${NBMAKE}" -C "${LIVEIMAGE_DIR}" live_image \
	LIVEIMGBASE="${IMAGE_BASE}" \
	LIVEIMAGEMB="${IMAGE_MB}" \
	KERN_SET="${KERN_SET}" \
	SETS="${SETS}" \
	SETS_DIR="${CUSTOM_SETS}" \
	LIVEIMG_RELEASEDIR="${PROFILE_IMAGES_DIR}" >"${IMAGE_LOG}" 2>&1; then
	printf '%s\n' "Image build failed. Last log lines:"
	tail -80 "${IMAGE_LOG}"
	exit 1
fi

if [ -f "${RAW_IMAGE}" ]; then
	cp "${RAW_IMAGE}" "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img"
fi

if [ "${POST_IMAGE}" != no ] && [ -x "${PROFILE_DIR}/post-image.sh" ]; then
	"${PROFILE_DIR}/post-image.sh" "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img"
	rm -f "${GZ_IMAGE}"
	gzip -n -9c "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img" > "${GZ_IMAGE}"
fi

printf '\n%s\n' "Built images:"
ls -lh "${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img" "${GZ_IMAGE}"
