#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

# Auto-fetch or update NetBSD source
if [ ! -d "${NETBSD_DIR}/.git" ]; then
	printf '%s\n' "NetBSD source not found; cloning ..."
	"${PROJECT_DIR}/scripts/fetch-netbsd.sh"
else
	printf '%s\n' "Updating NetBSD source ..."
	git -C "${NETBSD_DIR}" fetch --prune origin
	if [ -n "${NETBSD_BRANCH:-}" ]; then
		git -C "${NETBSD_DIR}" checkout "${NETBSD_BRANCH}"
		git -C "${NETBSD_DIR}" merge --ff-only "origin/${NETBSD_BRANCH}" 2>/dev/null || \
			printf '%s\n' "  (fast-forward not possible; staying at current HEAD)"
	else
		current=$(git -C "${NETBSD_DIR}" rev-parse --abbrev-ref HEAD)
		git -C "${NETBSD_DIR}" merge --ff-only "origin/${current}" 2>/dev/null || \
			printf '%s\n' "  (fast-forward not possible; staying at current HEAD)"
	fi
	printf '%s\n' "  HEAD: $(git -C "${NETBSD_DIR}" log --oneline -1)"
fi

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
printf '\n%s\n' "Watch live build in another terminal:  make watch-logs"
printf '%s\n' "  (tmux: Ctrl-B & to quit, Ctrl-B D to detach)"
printf '\n'

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
