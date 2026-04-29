# rpi4-uefi — pinned artifact versions and checksums
#
# Source this file to get the canonical versions.
# Override any variable from the environment before sourcing to customize.
#
# Two tiers of reproducibility:
#   Tier 1 (default): Download prebuilt pftf release zip, verify sha256.
#   Tier 2 (from source): Build RPI_EFI.fd via scripts/build-rpi4-uefi-firmware.sh
#                         using the EDK2 source commits pinned below.

# ---- pftf/RPi4 prebuilt release (tier 1) ----------------------------

UEFI_FW_VERSION="1.51"
UEFI_FW_URL="https://github.com/pftf/RPi4/releases/download/v${UEFI_FW_VERSION}/RPi4_UEFI_Firmware_v${UEFI_FW_VERSION}.zip"
UEFI_FW_SHA256="000b6c518e83bb93262ed6b264a0e9498509c46513dabf58c0dbb73d4c2e7c18"

# ---- EDK2 source pins for v1.51 (tier 2) ----------------------------

# These are the exact submodule commits used to build v1.51.
# Run scripts/build-rpi4-uefi-firmware.sh to reproduce.
EDK2_COMMIT="b7a715f7c03c45c6b4575bf88596bfd79658b8ce"
EDK2_PLATFORMS_COMMIT="a243e267429b9f961632ff8a0a1c64ef9fc82ebd"
EDK2_NONOSI_COMMIT="94d048981116e2e3eda52dad1a89958ee404098d"

# ---- NetBSD stable release ------------------------------------------

NETBSD_RELEASE="10.1"
NETBSD_ARM64_IMG_URL="https://cdn.netbsd.org/pub/NetBSD/NetBSD-${NETBSD_RELEASE}/evbarm-aarch64/binary/gzimg/arm64.img.gz"
NETBSD_ARM64_IMG_SHA256="78bcd1d10dde8b92b7e7fd99fe4fd308d519b603886c97b66c709c6b78741ab0"

# ---- RPi GPU firmware blobs (not buildable from source) -------------

# Shipped inside the pftf zip. Can be fetched independently:
RPI_FIRMWARE_REPO="https://github.com/raspberrypi/firmware"
