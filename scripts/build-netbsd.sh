#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

require_netbsd_tree

jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '%s\n' 2)}
set -- $(build_machine_args)
LOG_DIR=${PROJECT_DIR}/logs/${PROFILE}
TOOLS_LOG=${LOG_DIR}/tools.log
RELEASE_LOG=${LOG_DIR}/release.log

mkdir -p "${LOG_DIR}"

printf '%s\n' "Building NetBSD tools and release"
printf '%s\n' "Source: ${NETBSD_DIR}"
printf '%s\n' "Objdir: ${OBJ_DIR}"
printf '%s\n' "Tools log: ${TOOLS_LOG}"
printf '%s\n' "Release log: ${RELEASE_LOG}"

if ! "${NETBSD_DIR}/build.sh" -U -u -j"${jobs}" -O "${OBJ_DIR}" "$@" tools >"${TOOLS_LOG}" 2>&1; then
	printf '%s\n' "Tools build failed. Last log lines:"
	tail -80 "${TOOLS_LOG}"
	exit 1
fi

if ! "${NETBSD_DIR}/build.sh" -U -u -j"${jobs}" -O "${OBJ_DIR}" "$@" release >"${RELEASE_LOG}" 2>&1; then
	printf '%s\n' "Release build failed. Last log lines:"
	tail -80 "${RELEASE_LOG}"
	exit 1
fi
