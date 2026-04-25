#!/usr/bin/env sh

set -eu

if [ $# -ne 2 ]; then
	printf '%s\n' "usage: $0 IMAGE DEVICE"
	printf '%s\n' "example: $0 images/rpi4/NetBSD-kleinbsd-rpi4.img /dev/sdX"
	exit 1
fi

IMAGE=$1
DEVICE=$2

printf '%s\n' "This will overwrite ${DEVICE}."
printf '%s\n' "Run the dd command yourself after verifying the device:"
printf '%s\n' "  sudo dd if=${IMAGE} of=${DEVICE} bs=4M conv=fsync status=progress"
