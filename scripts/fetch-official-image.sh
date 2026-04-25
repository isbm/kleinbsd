#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

if [ -z "${OFFICIAL_IMAGE_URL:-}" ]; then
	printf '%s\n' "Profile ${PROFILE} has no OFFICIAL_IMAGE_URL."
	exit 1
fi

PROFILE_IMAGES_DIR=$(profile_image_dir)
GZ_IMAGE=${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img.gz
RAW_IMAGE=${PROFILE_IMAGES_DIR}/${IMAGE_BASE}.img

mkdir -p "${PROFILE_IMAGES_DIR}"

printf '%s\n' "Downloading: ${OFFICIAL_IMAGE_URL}"
printf '%s\n' "To: ${GZ_IMAGE}"
curl -L --fail --output "${GZ_IMAGE}.tmp" "${OFFICIAL_IMAGE_URL}"
mv "${GZ_IMAGE}.tmp" "${GZ_IMAGE}"

printf '%s\n' "Decompressing: ${RAW_IMAGE}"
gzip -dc "${GZ_IMAGE}" > "${RAW_IMAGE}"

printf '\n%s\n' "Fetched images:"
ls -lh "${RAW_IMAGE}" "${GZ_IMAGE}"
