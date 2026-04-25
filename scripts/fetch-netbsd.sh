#!/usr/bin/env sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "${PROJECT_DIR}/lib/project.sh"

if [ -d "${NETBSD_DIR}/.git" ]; then
	printf '%s\n' "Updating existing NetBSD tree: ${NETBSD_DIR}"
	git -C "${NETBSD_DIR}" fetch --prune origin
	printf '%s\n' "Fetch complete. Review/merge/reset manually if you want to move branches."
	exit 0
fi

if [ -e "${NETBSD_DIR}" ]; then
	printf '%s\n' "Refusing to overwrite existing non-git path: ${NETBSD_DIR}"
	exit 1
fi

printf '%s\n' "Cloning NetBSD source into ${NETBSD_DIR}"
git clone https://github.com/netbsd/src "${NETBSD_DIR}"
