# kleinbsd

Small NetBSD image builder.

This project keeps local policy outside the NetBSD source tree. By default it expects:

- NetBSD source: `../netbsd`
- NetBSD objdir: `../obj-<profile>`
- Output images: `./images/<profile>`

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

Each profile uses its own object directory by default, for example `../obj-qemu-amd64` and `../obj-rpi4`. This avoids mixing target toolchains between amd64 and evbarm/aarch64.

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

The scripts live in `scripts/`; the `Makefile` is the intended interface.
