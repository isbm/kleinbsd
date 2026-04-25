#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

require_netbsd_tree

if [ "${APPLY_KERNEL_CONFIG}" = no ]; then
	printf '%s\n' "Profile ${PROFILE} uses stock ${KERNEL_CONFIG}; not applying local kernel config."
	exit 0
fi

src=${PROJECT_DIR}/configs/${KERNEL_CONFIG}
dst=${NETBSD_DIR}/sys/arch/${MACHINE}/conf/${KERNEL_CONFIG}

if [ ! -f "${src}" ]; then
	printf '%s\n' "Missing kernel config: ${src}"
	exit 1
fi

cp "${src}" "${dst}"
printf '%s\n' "Applied ${src} -> ${dst}"
