# KleinBSD

NetBSD image builder for Raspberry Pi 4.

All build artifacts stay inside the project --- nothing spills into the parent directory.

```sh
make select-profile rpi4-netbsd11
make build
make image
make write-sd
```

Dependencies are auto-installed on first run. The NetBSD source is cloned
automatically. UEFI firmware is injected automatically. You just need an
SD card, a Pi 4, and patience.

Everything under `build/`, `images/`, `logs/`, `work/`, and `tmp/` is
gitignored. Profiles live in `profiles/`, scripts in `scripts/`, config
in `configs/`, mirrored firmware in `vendor/`. The `Makefile` is the
only interface.

Full documentation: `doc/kleinbsd.md`. PDF: `make docs`.
