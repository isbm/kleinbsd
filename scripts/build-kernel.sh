#!/usr/bin/env sh
# Build just the kernel (fast iteration).
# Assumes a full release was already built via make build.

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

require_netbsd_tree

# Auto-install custom kernel config if it lives in our configs/ tree
archdir="${MACHINE_ARCH:-${MACHINE}}"
custom_config="${PROJECT_DIR}/configs/${archdir}/${KERNEL_CONFIG}"
netbsd_config="${NETBSD_DIR}/sys/arch/${MACHINE}/conf/${KERNEL_CONFIG}"
if [ -f "${custom_config}" ]; then
	cp "${custom_config}" "${netbsd_config}"
	printf '%s\n' "Installed kernel config: ${KERNEL_CONFIG}"
fi

jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '%s\n' 2)}
set -- $(build_machine_args)
KERNEL_DIR="${OBJ_DIR}/sys/arch/${MACHINE}/compile/${KERNEL_CONFIG}"
KERNEL="${KERNEL_DIR}/netbsd"

printf '%s\n' "Building kernel: ${KERNEL_CONFIG}"
printf '%s\n' "Source: ${NETBSD_DIR}"
printf '%s\n' "Objdir: ${OBJ_DIR}"

if ! "${NETBSD_DIR}/build.sh" -U -u -j"${jobs}" -O "${OBJ_DIR}" "$@" kernel="${KERNEL_CONFIG}"; then
	printf '%s\n' "Kernel build failed."
	exit 1
fi

printf '\n%s\n' "Kernel built: ${KERNEL}"
ls -lh "${KERNEL}"
