---
title: KleinBSD
subtitle: NetBSD image builder for Raspberry Pi 4
date: April 2026
toc: true
geometry: margin=1in
---

# TL;DR

You just cloned this repo. You have an SD card and a Pi 4. You want
NetBSD on it, right now.

```sh
make select-profile rpi4-netbsd11   # pick the 11-stable source-build profile
make build                          # clone NetBSD, checkout branch, compile
make image                          # assemble image + inject UEFI firmware
make write-sd                       # write to SD card (asks which device)
```

# What is this

KleinBSD builds a NetBSD SD card image that actually boots on a
Raspberry Pi 4. The official images don't always boot out of the box
on all Pi 4 boards --- the GPU firmware bundled with them is often too
old or incompatible with newer Pi EEPROM revisions, and you'll get a
black screen with nothing but a red power LED.

We fix this by injecting the [pftf/RPi4](https://github.com/pftf/RPi4)
UEFI firmware into the image's FAT boot partition. This gives the Pi a
UEFI firmware blob it actually recognizes, which then chainloads the
NetBSD bootloader. It's a dumb one-liner fix, but it works.

# How it boots

The Pi 4 has a boot ROM in its EEPROM. On power-up it reads the SD
card looking for firmware it can load. The official NetBSD `arm64.img`
ships with Broadcom GPU firmware files (`start4.elf`, `fixup4.dat`) that
are supposed to load `netbsd.img` directly:

```
EEPROM  -->  start4.elf  -->  config.txt  -->  netbsd.img
```

This path breaks silently on many Pi 4s. The EEPROM either doesn't
like the version of `start4.elf` or expects something else entirely.
Result: red LED, black screen, sadness.

What we do instead: inject a real UEFI firmware image from the
pftf/RPi4 project. This is TianoCore EDK2 compiled for the Pi 4.
The Pi EEPROM knows how to load it, and it in turn loads the NetBSD
EFI bootloader that was already sitting in the `EFI/` directory of
the original image:

```
EEPROM  -->  RPI_EFI.fd (UEFI)  -->  EFI/BOOT/BOOTAA64.EFI  -->  netbsd.img
```

The kernel, the root filesystem, the kernel command line --- none of
that changes. We only replace the tiny boot chain on the FAT partition.

# Directory layout

Everything lives inside the project. Nothing spills into the parent
directory.

```
kleinbsd/
  Makefile               the only interface you need
  build/                 gitignored --- all the heavy stuff
    netbsd-src/           NetBSD source tree (git clone)
    obj-rpi4/             build output for the rpi4 profile
    obj-rpi4-netbsd11/    build output for rpi4-netbsd11
  profiles/
    rpi4/                 build from source, whatever branch
    rpi4-netbsd11/        build from netbsd-11 branch
    rpi4-official/        download official daily HEAD image
    rpi4-netbsd10/        download official 10.x stable image
    qemu-amd64/           QEMU test target
  scripts/                the shell scripts that do the work
  images/                 built SD card images (gitignored)
  vendor/rpi4-uefi/       mirrored UEFI firmware zip + checksums
  configs/rpi4-uefi.sh    pinned firmware versions and SHA256 hashes
  doc/                    this documentation
```

The images are big (1--2 GB). We don't put them in git. The UEFI
firmware zip is 3.4 MB --- that *is* committed to `vendor/` so the
project works even if GitHub goes down.

# Fetching, building, updating

`make build` handles everything. First time it clones the NetBSD
source tree from GitHub into `build/netbsd-src/`. On subsequent runs
it does a `git fetch` and fast-forwards to the latest commit on the
branch your profile wants. Then it compiles.

The build produces two things:

1. A full NetBSD release in `build/obj-<profile>/releasedir/`. This
   includes the standard `arm64.img.gz` that we'll use for the SD card.
2. Toolchain binaries for cross-compiling the kernel later.

Logs go to `logs/<profile>/tools.log` and `logs/<profile>/release.log`.
The build output is hidden so your terminal doesn't drown. You can watch
it live in another terminal:

```sh
make watch-logs
```

This opens tmux with two panes --- tools on the left, release on
the right --- and tails both as the build progresses. Ctrl-B & to quit,
Ctrl-B D to detach and leave it running in the background.

`make build` also prints a reminder about this before starting, with
the tmux quit keys. You won't miss it.

# Choosing a profile

Profiles live in `profiles/<name>/profile.sh`. A profile is just a
shell snippet that sets variables: machine architecture, kernel config,
image size, which sets to include, and whether to apply post-processing.

```sh
make select-profile rpi4-netbsd11
```

That writes the choice to `.envrc`. From then on `make build`, `make
image`, and `make write-sd` use it. You can override once:

```sh
PROFILE=rpi4 make image
```

But positional is nicer:

```sh
make select-profile rpi4
```

Available profiles:

- **rpi4** --- build from source, whatever branch you left checked out
  in `build/netbsd-src`.
- **rpi4-netbsd11** --- build from the `netbsd-11` stable branch.
  `make build` checks it out and fast-forwards automatically.
- **rpi4-official** --- download the latest NetBSD daily HEAD image
  from nycdn.netbsd.org. No compilation, just `make fetch-official`
  and `make write-sd`.
- **rpi4-netbsd10** --- same but for the 10.x stable release.
- **qemu-amd64** --- a small amd64 image for testing with QEMU. Not
  relevant for the Pi.

# Building the image

`make image` takes the `arm64.img.gz` that `make build` produced,
decompresses it, and runs the post-image script. For rpi4 profiles,
the post-image script injects the UEFI firmware into the FAT boot
partition. That's the whole magic.

The output lands in `images/<profile>/NetBSD-kleinbsd-<profile>.img`.
That's the file you `dd` to the SD card.

# Writing to SD

```sh
make write-sd
```

It's interactive. It prints `lsblk`, asks for the device (e.g.
`/dev/sdb`), asks you to type it again as confirmation, unmounts any
mounted partitions, and `dd`s the image. It syncs when done.

Or do it manually:

```sh
lsblk
sudo dd if=images/rpi4-netbsd11/NetBSD-kleinbsd-rpi4-netbsd11.img \
        of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

Always write to the **whole disk** (`/dev/sdb`), never a partition
(`/dev/sdb1`). The image contains its own partition table.

# Kernel customization

The default kernel is `GENERIC64` --- everything including the kitchen
sink. For an embedded use case you'll want to trim it down.

Create a config file, say `configs/RPI4-MINIMAL`:

```
include "arch/evbarm/conf/GENERIC64"
no options      INET6
no pseudo-device bpfilter
# ... remove whatever you don't need ...
```

Then update `profiles/rpi4-netbsd11/profile.sh`:

```
KERNEL_CONFIG=RPI4-MINIMAL
APPLY_KERNEL_CONFIG=yes
PREBUILT_IMAGE_GZ=               # rebuild the image too
IMAGE_MB=512                      # smaller
SETS='base etc'                   # minimal userland
```

Rebuild:

```sh
make build
make image
```

`APPLY_KERNEL_CONFIG=yes` copies your config into the source tree
before compiling.

# The UEFI firmware mirror

The pftf/RPi4 firmware zip is committed to `vendor/rpi4-uefi/`. It's
3.4 MB. Alongside it is a `SHA256SUMS` file with hashes of the zip
and every file inside it. The `configs/rpi4-uefi.sh` file pins the
version and checksum.

The post-image script checks all of this before injecting. If the
checksum doesn't match, it refuses to proceed.

If pftf/RPi4 ever disappears or a newer version breaks:

- The old known-good zip is in git history.
- `configs/rpi4-uefi.sh` pins which version to use.
- `SHA256SUMS` lets you verify nothing got corrupted.
- `scripts/build-rpi4-uefi-firmware.sh` can build `RPI_EFI.fd` from
  EDK2 source if you want zero binary trust.

The only pieces that can't be built from source are `start4.elf` and
`fixup4.dat` --- those are Broadcom GPU firmware blobs from the
Raspberry Pi firmware repo. They're small, well-known, and very
unlikely to disappear.

# Troubleshooting

**Red LED only, no green ACT LED, totally black screen.**

The Pi EEPROM found nothing it could boot. The UEFI firmware didn't
make it onto the FAT partition. Re-run `make image` and check that
`RPI_EFI.fd` shows up in the output. Verify with `make inspect-sd`
after writing.

**Rainbow screen, then nothing.**

The Pi loaded `start4.elf` but couldn't find or load the next stage.
Check that the FAT partition has `config.txt` with `armstub=RPI_EFI.fd`.

**Booting but no network.**

If you get a `169.254.x.x` address, DHCP timed out. Try `dhcpcd -4`
or set a static IP:

```sh
ifconfig genet0 inet 192.168.2.99 netmask 255.255.255.0
route add default 192.168.2.1
```

If the PHY link is up (check `ifconfig genet0 | grep status`) but
static IPs can't ping either, the kernel driver on your branch might
be broken. Switch to a known-good branch (netbsd-10 or netbsd-11).

**EEPROM too old to boot UEFI.**

Boot the Pi with a Raspberry Pi OS SD card once, run
`sudo rpi-eeprom-update -a`, reboot. Then your NetBSD SD card should work.

# Environment overrides

Every variable set by a profile can be overridden from the environment
or the make command line:

```sh
JOBS=8 PROFILE=rpi4 IMAGE_MB=768 make image
NETBSD_DIR=/some/other/path make build
```

# Requirements

- Ubuntu 22.04 or newer, or Debian 11 or newer
- Nothing else. `make build` auto-installs missing packages via apt-get
  on the very first run. You'll see it happen once, then never again.
- About 25 GB of free disk space for a full source build
- An SD card and USB reader
- Raspberry Pi 4 with HDMI and keyboard (or serial console)
- Patience during the first build

# Generating the PDF

```sh
make docs
```

Requires pandoc and xelatex. If they're missing, they'll be
auto-installed on first run just like everything else. Output
goes to `doc/kleinbsd.pdf`.
