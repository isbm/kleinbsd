#!/usr/bin/env sh

set -eu

PROJECT_DIR=${PROJECT_DIR:-$(pwd -P)}

if [ -f "${PROJECT_DIR}/.envrc" ]; then
	. "${PROJECT_DIR}/.envrc"
fi

NETBSD_DIR=${NETBSD_DIR:-"${PROJECT_DIR}/build/netbsd-src"}
IMAGES_DIR=${IMAGES_DIR:-"${PROJECT_DIR}/images"}
PROFILE=${PROFILE:-qemu-amd64}
PROFILE_DIR=${PROFILE_DIR:-"${PROJECT_DIR}/profiles/${PROFILE}"}

if [ -f "${PROFILE_DIR}/profile.sh" ]; then
	. "${PROFILE_DIR}/profile.sh"
else
	printf '%s\n' "Missing profile: ${PROFILE_DIR}/profile.sh"
	exit 1
fi

MACHINE=${MACHINE:-amd64}
MACHINE_ARCH=${MACHINE_ARCH:-}
OBJ_DIR=${OBJ_DIR:-"${PROJECT_DIR}/build/obj-${PROFILE}"}
KERNEL_CONFIG=${KERNEL_CONFIG:-FASTVM}
APPLY_KERNEL_CONFIG=${APPLY_KERNEL_CONFIG:-yes}
IMAGE_BASE=${IMAGE_BASE:-NetBSD-kleinbsd-${PROFILE}}
IMAGE_MB=${IMAGE_MB:-512}
SETS=${SETS:-base etc rescue modules}
LIVEIMAGE_SUBDIR=${LIVEIMAGE_SUBDIR:-distrib/${MACHINE}/liveimage/emuimage}
RELEASE_MACHINE=${RELEASE_MACHINE:-${MACHINE}}
PREBUILT_IMAGE_GZ=${PREBUILT_IMAGE_GZ:-}
POST_IMAGE=${POST_IMAGE:-yes}
NETBSD_BRANCH=${NETBSD_BRANCH:-}
RPI_UEFI=${RPI_UEFI:-}

nbmake_path() {
	if [ -n "${NBMAKE:-}" ]; then
		printf '%s\n' "${NBMAKE}"
		return
	fi

	for candidate in "${OBJ_DIR}"/tooldir.*/bin/nbmake-${MACHINE}; do
		if [ -x "${candidate}" ]; then
			printf '%s\n' "${candidate}"
			return
		fi
	done

	printf '%s\n' ""
}

build_machine_args() {
	printf '%s\n' "-m"
	printf '%s\n' "${MACHINE}"
	if [ -n "${MACHINE_ARCH}" ]; then
		printf '%s\n' "-a"
		printf '%s\n' "${MACHINE_ARCH}"
	fi
}

require_netbsd_tree() {
	if [ ! -x "${NETBSD_DIR}/build.sh" ]; then
		printf '%s\n' "Missing NetBSD source tree: ${NETBSD_DIR}"
		printf '%s\n' "Run make fetch first."
		exit 1
	fi
}

profile_image_dir() {
	printf '%s\n' "${IMAGES_DIR}/${PROFILE}"
}
