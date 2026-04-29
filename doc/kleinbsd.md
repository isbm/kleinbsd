---
title: kleinbsd
subtitle: Small NetBSD image builder for Raspberry Pi 4
date: April 2026
toc: true
geometry: margin=1in
mainfont: DejaVu Sans
monofont: DejaVu Sans Mono
---

# Overview

kleinbsd builds a bootable NetBSD SD card image for the Raspberry Pi 4.
Two paths are available:

| Path | Command | What it does |
|------|---------|--------------|
| **Quick** (official binary) | `./uefi-test-community.sh` | Downloads the official NetBSD 10.1 `arm64.img`, injects UEFI firmware, outputs a bootable image. No source build needed. |
| **Full** (from source) | `make netbsd && make image` | Builds the entire NetBSD release from source, then injects UEFI firmware. Everything is compiled locally. |

Both paths produce the same result: an SD card image that boots on a Raspberry Pi 4.

# Quick start (first time)

```
make setup              # install dependencies (Ubuntu/Debian)
make                    # show available targets
make select-profile PROFILE=rpi4
make fetch              # clone NetBSD source into ../netbsd
make netbsd             # build NetBSD from source (takes a while)
make image              # build the SD card image
make write-sd           # write it to an SD card (interactive)
```

To skip the source build and use the official NetBSD 10.1 binary instead:

```
./uefi-test-community.sh
sudo dd if=images/rpi4-uefi/arm64-uefi-fw.img of=/dev/sdX bs=4M conv=fsync status=progress
```

# Requirements

- Ubuntu 22.04 or newer / Debian 11 or newer
- At least 10 GB free disk space for a full source build
- An SD card and a USB SD card reader
- A Raspberry Pi 4 with HDMI display + keyboard, or serial console

# How it boots

The Raspberry Pi 4 boot ROM (EEPROM) does **not** directly boot `netbsd.img`. It needs firmware it recognizes on the SD card's FAT partition.

The official NetBSD `arm64.img` relies on the **GPU firmware path**:

```
Pi4 EEPROM -> start4.elf -> config.txt -> netbsd.img -> NetBSD
```

This path fails on many Pi4 boards because the EEPROM version may reject the bundled `start4.elf` / `fixup4.dat` blobs (version mismatch, boot mode configuration, etc.).

kleinbsd fixes this by injecting the **pftf/RPi4 UEFI firmware** into the FAT partition. The boot chain becomes:

```
Pi4 EEPROM -> RPI_EFI.fd (TianoCore EDK2 UEFI) -> EFI/BOOT/BOOTAA64.EFI -> netbsd.img -> NetBSD
```

`RPI_EFI.fd` is a standard UEFI firmware image the Pi4 EEPROM knows how to load. It then chainloads the NetBSD EFI bootloader, which was already present in the original `arm64.img` (under `EFI/`). The kernel and FFS root partition remain untouched.

The UEFI firmware is sourced from [pftf/RPi4](https://github.com/pftf/RPi4), which builds [TianoCore EDK2](https://github.com/tianocore/edk2) for the Raspberry Pi 4 platform.

# UEFI firmware: mirroring and reproducibility

All UEFI firmware artifacts are pinned in `configs/rpi4-uefi.sh`:

- **Prebuilt release:** URL and SHA256 checksum for the pftf/RPi4 release zip (currently v1.51).
- **EDK2 source commits:** Exact submodule pins for `edk2`, `edk2-platforms`, and `edk2-non-osi` used to build the release. Run `scripts/build-rpi4-uefi-firmware.sh` to reproduce `RPI_EFI.fd` from source.

The only components that **cannot** be built from source are `start4.elf` and `fixup4.dat` (Broadcom GPU firmware blobs). These are shipped inside the pftf zip and cached locally.

# Project structure

```
kleinbsd/
  configs/
    rpi4-uefi.sh          pinned firmware versions + checksums
    FASTVM                example minimal kernel config (amd64)
  doc/
    kleinbsd.md           this documentation
  images/                 built images (gitignored)
  lib/
    project.sh            shared shell library
  profiles/
    rpi4/
      profile.sh          machine, kernel, image settings
      post-image.sh       UEFI firmware injection
    qemu-amd64/           QEMU test profile
    rpi4-official/        official NetBSD daily HEAD image
    rpi4-netbsd10/        official NetBSD 10.x release image
  scripts/
    build-netbsd.sh       full NetBSD source build
    build-image.sh        image assembly
    build-rpi4-uefi-firmware.sh  build RPI_EFI.fd from EDK2 source
    fetch-netbsd.sh       clone NetBSD source tree
    fetch-official-image.sh      download official NetBSD image
    write-sd.sh           interactive SD card writer
    inspect-sd.sh         inspect FAT boot partition on SD card
    patch-rpi4-sd.sh      patch config.txt on an existing SD card
    run.sh                QEMU runner
  uefi-test-community.sh  quick-start: download official image + inject UEFI
  Makefile                primary interface
  .envrc                  currently selected profile
```

# Profiles

Profiles define machine architecture, kernel config, image size, and post-processing.

| Profile | Purpose | Machine | Kernel |
|---------|---------|---------|--------|
| `rpi4` | Build from source, inject UEFI | evbarm / aarch64 | GENERIC64 |
| `qemu-amd64` | QEMU test target | amd64 | FASTVM |
| `rpi4-official` | Official NetBSD daily HEAD | (downloaded) | (prebuilt) |
| `rpi4-netbsd10` | Official NetBSD 10.x stable | (downloaded) | (prebuilt) |

Select a profile:

```
make select-profile PROFILE=rpi4
```

This writes `.envrc`. After that, plain `make netbsd`, `make image`, and `make write-sd` use the selected profile.

# Workflow reference

## One-time setup

```
make setup              # install build dependencies
make select-profile PROFILE=rpi4
make fetch              # clone NetBSD source (once)
```

## Build cycle

```
make netbsd             # build NetBSD release (long, one-time)
make image              # assemble image + inject UEFI firmware
make write-sd           # write to SD card (interactive)
```

## Quick rebuilds

If only the kernel config or image settings changed, rebuild just the image:

```
make image              # skips the full release build, reuses arm64.img.gz
```

## Inspection and debugging

```
make inspect-sd         # inspect FAT boot partition on an SD card
make patch-rpi4-sd      # patch config.txt with HDMI/diagnostic settings
```

# The UEFI injection step in detail

The key to making NetBSD boot on a Raspberry Pi 4 is `profiles/rpi4/post-image.sh`. It is called automatically by `make image` and performs the following:

1. Downloads (or loads from cache) the pftf/RPi4 UEFI firmware zip, verifying its SHA256 checksum.
2. Mounts the FAT boot partition from the built `arm64.img` using a loop device.
3. Extracts the UEFI firmware zip into the FAT partition, which places `RPI_EFI.fd`, updated `start4.elf` / `fixup4.dat`, device tree blobs, and a `config.txt` that chainloads into the UEFI firmware.
4. Unmounts and cleans up.

The existing NetBSD EFI bootloader (`EFI/BOOT/BOOTAA64.EFI`), kernel (`netbsd.img`), and FFS root partition are preserved. Only the boot chain on the FAT partition is replaced.

# Kernel customization (embedded use)

The default profile uses `KERNEL_CONFIG=GENERIC64` which includes drivers for many devices. To trim the kernel to a bare minimum:

1. Create a minimal kernel config in `configs/`, e.g., `configs/RPI4-MINIMAL`:

```
include "arch/evbarm/conf/GENERIC64"
no options        INET6
no pseudo-device  bpfilter
# ... remove unneeded drivers ...
```

2. Update `profiles/rpi4/profile.sh`:

```
KERNEL_CONFIG=RPI4-MINIMAL
APPLY_KERNEL_CONFIG=yes
PREBUILT_IMAGE_GZ=            # disable prebuilt path, rebuild from source
IMAGE_MB=512                  # smaller image for embedded
SETS='base etc'               # minimal userland
```

3. Rebuild:

```
make netbsd                     # rebuild with custom kernel
make image                      # assemble minimal image
```

The `APPLY_KERNEL_CONFIG=yes` line copies your config into the NetBSD source tree before building.

# SD card writing

`make write-sd` is interactive: it lists block devices, asks for the device path, and asks for confirmation before overwriting.

Alternatively, write manually:

```
lsblk                              # find your SD card (e.g., /dev/sdb)
sudo dd if=images/rpi4/NetBSD-kleinbsd-rpi4.img of=/dev/sdb bs=4M conv=fsync status=progress
sync
```

**Always write to the whole disk** (e.g., `/dev/sdb`), never a partition (e.g., `/dev/sdb1`).

# Troubleshooting

**Only red power LED, no green ACT LED, black screen:**
The Pi4 EEPROM found no valid boot firmware on the SD card. Ensure the UEFI injection step ran successfully. Re-run `make image` and check that `RPI_EFI.fd` appears on the FAT partition (use `make inspect-sd` after writing).

**Rainbow screen then black:**
The Pi4 loaded `start4.elf` but couldn't find or load the next stage. Check that `config.txt` contains `armstub=RPI_EFI.fd`.

**Kernel panic after boot:**
Check `cmdline.txt` on the FAT partition. The default `root=ld0a` should work with the standard image layout.

**EEPROM too old:**
If the Pi4 refuses to load UEFI firmware from SD, update the EEPROM:
- Boot the Pi4 with a Raspberry Pi OS SD card
- Run `sudo rpi-eeprom-update -a`
- Reboot

**Build fails with "Cannot find nbmake-\*":**
Run `make netbsd` first. The full NetBSD build must complete before `make image` can use its tools.

# Environment overrides

All variables defined in profile scripts and config files can be overridden from the environment:

```
JOBS=8 PROFILE=rpi4 IMAGE_MB=768 make image
NETBSD_DIR=/path/to/src OBJ_DIR=/path/to/obj make image
```

# Generating this document

```
make docs              # produces doc/kleinbsd.pdf
```

Requires `pandoc` and `texlive-xetex` (installed by `make setup`).
