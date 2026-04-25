#!/usr/bin/env sh

set -eu

if [ $# -ne 1 ]; then
	printf '%s\n' "usage: $0 IMAGE"
	exit 1
fi

IMAGE=$1
BOOT_OFFSET=${BOOT_OFFSET:-16777216}
TMP_CONFIG=$(mktemp)
trap 'rm -f "${TMP_CONFIG}"' EXIT

mtype -i "${IMAGE}@@${BOOT_OFFSET}" ::config.txt > "${TMP_CONFIG}"

if ! grep -q '^# kleinbsd HDMI diagnostics$' "${TMP_CONFIG}"; then
	cat >> "${TMP_CONFIG}" <<'EOF'

# kleinbsd HDMI diagnostics
# Force the primary micro-HDMI port on Pi 4: the port closest to USB-C power.
hdmi_force_hotplug=1
hdmi_force_hotplug:0=1
hdmi_group=1
hdmi_group:0=1
hdmi_mode=16
hdmi_mode:0=16
hdmi_drive=2
config_hdmi_boost=7
disable_overscan=1
framebuffer_width=1024
framebuffer_height=768
max_framebuffers=2

# Show more firmware-stage output before NetBSD takes over.
boot_delay=2
uart_2ndstage=1
EOF
fi

mdel -i "${IMAGE}@@${BOOT_OFFSET}" ::config.txt
mcopy -i "${IMAGE}@@${BOOT_OFFSET}" "${TMP_CONFIG}" ::config.txt

printf '%s\n' "Patched rpi4 HDMI settings in config.txt"
