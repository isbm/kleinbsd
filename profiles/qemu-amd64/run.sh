#!/usr/bin/env sh

set -eu

if [ $# -ne 1 ]; then
	printf '%s\n' "usage: $0 IMAGE"
	exit 1
fi

IMAGE=$1

exec qemu-system-x86_64 \
	-nodefaults \
	-m 1024 \
	-smp 2 \
	-display gtk \
	-device VGA \
	-device virtio-net-pci,netdev=n0 \
	-netdev user,id=n0,hostfwd=tcp::2222-:22 \
	-device virtio-blk-pci,drive=d0 \
	-drive if=none,id=d0,file="${IMAGE}",format=raw
