#!/bin/sh
# Build RPI_EFI.fd from EDK2 source for Raspberry Pi 4.
#
# This mirrors the pftf/RPi4 CI build locally so you can reproduce the UEFI
# firmware from source instead of relying on a GitHub release zip.
#
# Dependencies (Ubuntu/Debian):
#   sudo apt-get install build-essential python3 uuid-dev nasm acpica-tools \
#                        gcc-aarch64-linux-gnu
#
# The start4.elf / fixup4.dat GPU firmware blobs are *not* built here —
# those are Broadcom proprietary blobs from the Raspberry Pi firmware repo.
# After this script runs, combine RPI_EFI.fd with start4.elf / fixup4.dat
# and a config.txt (see configs/rpi4-uefi.sh) to assemble a full firmware
# bundle equivalent to the pftf release zip.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
WORK_DIR="${SCRIPT_DIR}/work/edk2-build"
IMAGES_DIR="${SCRIPT_DIR}/images/rpi4-uefi"

# Pin the exact submodule commits used by pftf/RPi4 v1.51
EDK2_URL="https://github.com/tianocore/edk2.git"
EDK2_COMMIT="b7a715f7c03c45c6b4575bf88596bfd79658b8ce"

EDK2_PLATFORMS_URL="https://github.com/tianocore/edk2-platforms.git"
EDK2_PLATFORMS_COMMIT="a243e267429b9f961632ff8a0a1c64ef9fc82ebd"

EDK2_NONOSI_URL="https://github.com/tianocore/edk2-non-osi.git"
EDK2_NONOSI_COMMIT="94d048981116e2e3eda52dad1a89958ee404098d"

# Output
RPI_EFI_FD="${IMAGES_DIR}/RPI_EFI.fd"

# --------------------------------------------------------------------

need() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf '%s\n' "Missing: $1"
		exit 1
	fi
}

printf '%s\n' "=== Build RPi4 UEFI firmware (EDK2) ==="
printf '%s\n' ""

# Check host tools
need python3
need make
need gcc
need nasm
need iasl

printf '%s\n' "Checking AARCH64 cross-compiler ..."
if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
	printf '%s\n' "  found: $(which aarch64-linux-gnu-gcc)"
else
	printf '%s\n' "  NOT FOUND. Install with:"
	printf '%s\n' "    sudo apt-get install gcc-aarch64-linux-gnu"
	exit 1
fi

mkdir -p "${WORK_DIR}" "${IMAGES_DIR}"

# --- clone edk2 ------------------------------------------------------

EDK2_DIR="${WORK_DIR}/edk2"
if [ ! -d "${EDK2_DIR}" ]; then
	printf '%s\n' "Cloning edk2 ..."
	git clone "${EDK2_URL}" "${EDK2_DIR}"
	( cd "${EDK2_DIR}" && git checkout "${EDK2_COMMIT}" )
	( cd "${EDK2_DIR}" && git submodule update --init --recursive )
else
	printf '%s\n' "Using existing edk2 checkout"
	( cd "${EDK2_DIR}" && git checkout "${EDK2_COMMIT}" )
fi

# --- clone edk2-platforms --------------------------------------------

PLATFORMS_DIR="${WORK_DIR}/edk2-platforms"
if [ ! -d "${PLATFORMS_DIR}" ]; then
	printf '%s\n' "Cloning edk2-platforms ..."
	git clone "${EDK2_PLATFORMS_URL}" "${PLATFORMS_DIR}"
fi
( cd "${PLATFORMS_DIR}" && git fetch origin && git checkout "${EDK2_PLATFORMS_COMMIT}" )

# --- clone edk2-non-osi ----------------------------------------------

NONOSI_DIR="${WORK_DIR}/edk2-non-osi"
if [ ! -d "${NONOSI_DIR}" ]; then
	printf '%s\n' "Cloning edk2-non-osi ..."
	git clone "${EDK2_NONOSI_URL}" "${NONOSI_DIR}"
fi
( cd "${NONOSI_DIR}" && git fetch origin && git checkout "${EDK2_NONOSI_COMMIT}" )

# --- build BaseTools -------------------------------------------------

printf '%s\n' "Building EDK2 BaseTools ..."
( cd "${EDK2_DIR}" && make -C BaseTools -j"$(nproc)" )

# --- build RPi4 platform ---------------------------------------------

export PACKAGES_PATH="${EDK2_DIR}:${PLATFORMS_DIR}:${NONOSI_DIR}"
export GCC5_AARCH64_PREFIX="aarch64-linux-gnu-"

printf '%s\n' "Building RPi4 UEFI firmware (RELEASE) ..."
(
	cd "${EDK2_DIR}"
	. edksetup.sh --reconfig
	build -a AARCH64 -t GCC5 -p Platform/RaspberryPi/RPi4/RPi4.dsc -b RELEASE -n "$(nproc)"
)

# --- collect output --------------------------------------------------

BUILT_FD="${EDK2_DIR}/Build/RPi4/RELEASE_GCC5/FV/RPI_EFI.fd"
if [ ! -f "${BUILT_FD}" ]; then
	printf '%s\n' "Build failed: RPI_EFI.fd not found at ${BUILT_FD}"
	exit 1
fi

cp "${BUILT_FD}" "${RPI_EFI_FD}"
printf '\n%s\n' "Built successfully: ${RPI_EFI_FD}"
ls -lh "${RPI_EFI_FD}"
printf '\n%s\n' "To assemble a full firmware bundle equivalent to the pftf release,"
printf '%s\n' "combine this RPI_EFI.fd with:"
printf '%s\n' "  - start4.elf, fixup4.dat  (from https://github.com/raspberrypi/firmware)"
printf '%s\n' "  - bcm2711-rpi-4-b.dtb     (device tree blob)"
printf '%s\n' "  - config.txt              (see configs/rpi4-uefi.sh)"
