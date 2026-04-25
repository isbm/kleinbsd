#!/usr/bin/env sh

set -eu

printf '%s\n' "Block devices:"
lsblk
printf '%s\n' ""
printf '%s' "FAT partition to patch, e.g. /dev/sdd1: "
read -r PART

case "${PART}" in
	/dev/sd[a-z][0-9]|/dev/mmcblk[0-9]p[0-9]|/dev/nvme[0-9]n[0-9]p[0-9]) ;;
	*)
		printf '%s\n' "Refusing suspicious partition path: ${PART}"
		exit 1
		;;
esac

if [ ! -b "${PART}" ]; then
	printf '%s\n' "Not a block device: ${PART}"
	exit 1
fi

TMP_CONFIG=$(mktemp)
trap 'rm -f "${TMP_CONFIG}"' EXIT

cat > "${TMP_CONFIG}" <<'EOF'
# kleinbsd rpi4 diagnostic config
arm_64bit=1
enable_uart=1
force_turbo=0

# Keep firmware/DTB selection simple and explicit for Raspberry Pi 4.
device_tree=dtb/broadcom/bcm2711-rpi-4-b.dtb
kernel=netbsd.img
kernel_address=0x200000
cmdline=cmdline.txt

# Prefer visible HDMI output while debugging.
hdmi_force_hotplug=1
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_group=1
hdmi_mode=16
hdmi_drive=2
disable_overscan=1
boot_delay=2
EOF

printf '%s\n' "New config.txt:"
cat "${TMP_CONFIG}"
printf '%s\n' ""
printf '%s' "Type ${PART} again to patch config.txt: "
read -r CONFIRM

if [ "${CONFIRM}" != "${PART}" ]; then
	printf '%s\n' "Confirmation mismatch; aborting."
	exit 1
fi

sudo mdel -i "${PART}" ::config.txt || true
sudo mcopy -i "${PART}" "${TMP_CONFIG}" ::config.txt
sync

printf '%s\n' "Patched ${PART}:config.txt"
