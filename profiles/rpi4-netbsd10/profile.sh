PROFILE=rpi4-netbsd10
IMAGE_BASE=NetBSD-${NETBSD_RELEASE:-10.1}-rpi4

# Stable NetBSD release image for Raspberry Pi 4 testing.
# Override NETBSD_RELEASE, NETBSD_MIRROR, or OFFICIAL_IMAGE_URL if needed.
NETBSD_RELEASE=${NETBSD_RELEASE:-10.1}
NETBSD_MIRROR=${NETBSD_MIRROR:-https://cdn.netbsd.org/pub/NetBSD}
OFFICIAL_IMAGE_URL=${OFFICIAL_IMAGE_URL:-${NETBSD_MIRROR}/NetBSD-${NETBSD_RELEASE}/evbarm-aarch64/binary/gzimg/arm64.img.gz}
