#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

PROFILE_IMAGES_DIR=$(profile_image_dir)
IMAGE=${IMAGE:-"${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img"}
PROFILE_RUN=${PROFILE_DIR}/run.sh

if [ ! -f "${IMAGE}" ]; then
	printf '%s\n' "Image not found: ${IMAGE}"
	printf '%s\n' "Run make image PROFILE=${PROFILE} first."
	exit 1
fi

if [ ! -x "${PROFILE_RUN}" ]; then
	printf '%s\n' "Profile has no runnable target: ${PROFILE_RUN}"
	exit 1
fi

exec "${PROFILE_RUN}" "${IMAGE}"
