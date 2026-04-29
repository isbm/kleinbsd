# kleinbsd

Small NetBSD image builder.

All build artifacts live inside the project:

- NetBSD source: `build/netbsd-src`
- NetBSD objdir: `build/obj-<profile>`
- Output images: `images/<profile>`

Everything under `build/` and `images/` is gitignored.

Basic workflow:

```sh
make
make profiles
make fetch
make select-profile PROFILE=qemu-amd64
make netbsd
make image
make run
```

Raspberry Pi 4 SD image workflow:

```sh
make select-profile PROFILE=rpi4
make netbsd
make image
make write-sd
```

`make write-sd` asks for the whole disk device interactively and writes the selected profile image.

`make select-profile PROFILE=<name>` writes `.envrc`. After that, plain `make image`, `make netbsd`, and `make run` use the selected profile. You can still override once with `PROFILE=qemu-amd64 make image`.

Each profile uses its own object directory by default, for example `build/obj-qemu-amd64` and `build/obj-rpi4`. This avoids mixing target toolchains between amd64 and evbarm/aarch64.

`make image` applies the selected profile kernel config, builds that kernel, packages it as a kernel set, and creates the reduced image in `images/<profile>/`.

The current `qemu-amd64` profile intentionally uses a narrow QEMU hardware profile: virtio disk, virtio NIC, VGA/wsdisplay console.

Profiles live under `profiles/`. The current profiles are `qemu-amd64` and `rpi4`.

Official Raspberry Pi 4 image test:

```sh
make select-profile PROFILE=rpi4-official
make fetch-official
make write-sd
```

Stable NetBSD 10 Raspberry Pi 4 image test:

```sh
make select-profile PROFILE=rpi4-netbsd10
make fetch-official
make write-sd
```

To try another 10.x release or mirror:

```sh
NETBSD_RELEASE=10.0 make fetch-official
NETBSD_MIRROR=https://cdn.netbsd.org/pub/NetBSD make fetch-official
OFFICIAL_IMAGE_URL=https://example.invalid/arm64mbr.img.gz make fetch-official
```

For Raspberry Pi 4/5, the NetBSD wiki documents `evbarm-aarch64/binary/gzimg/arm64.img.gz` as the standard image. The `rpi4`, `rpi4-official`, and `rpi4-netbsd10` profiles therefore use `arm64.img.gz`, not `arm64mbr.img.gz`.

The scripts live in `scripts/`; the `Makefile` is the intended interface.

Raspberry Pi 4 UEFI test:

```sh
./uefi-test.sh
```

This prepares one SD card following the NetBSD wiki's UEFI approach: a FAT32 partition with RPi4 UEFI firmware and the NetBSD FFS partition copied from `arm64.img` into the rest of the SD. It asks for the whole-disk device path interactively.
