# KleinBSD

This is a NetBSD image builder for various targets. Primary it is
Raspberry Pi 4 and QEMU.

## TL;DR

All build artifacts stay inside the project — nothing spills into
the parent directory. Typical routine:

```sh
make select-profile rpi4-netbsd11
make build
make image
make write-sd
```

Done!

Want to know more commands? — just run `make`.

## More Info

Dependencies are auto-installed on first run. The NetBSD source is cloned
automatically. UEFI firmware is injected automatically. You just need an
SD card, a Pi 4, and patience.

Everything under `build/`, `images/`, `logs/`, `work/`, and `tmp/` is
gitignored. Profiles live in `profiles/`, scripts in `scripts/`, config
in `configs/`, mirrored firmware in `vendor/`. The `Makefile` is the
only interface.

And some more info: `doc/kleinbsd.md`. PDF: `make docs`.
