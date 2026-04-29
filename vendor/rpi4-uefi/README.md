# vendor/rpi4-uefi

Mirrored copy of the [pftf/RPi4](https://github.com/pftf/RPi4) UEFI firmware
release used to make NetBSD boot on a Raspberry Pi 4.

## What's here

| File | Purpose | Buildable from source? |
|------|---------|------------------------|
| `RPI_EFI.fd` | TianoCore EDK2 UEFI firmware for RPi4 | Yes — `scripts/build-rpi4-uefi-firmware.sh` |
| `bcm2711-rpi-*-b.dtb` | Device tree blobs for Pi4 variants | Yes — from Linux kernel source |
| `config.txt` | RPi boot configuration (chainloads `RPI_EFI.fd`) | N/A (text file, versioned here) |
| `start4.elf` | Broadcom GPU firmware blob | **No** — proprietary, from raspberrypi/firmware |
| `fixup4.dat` | Broadcom GPU firmware co-processor blob | **No** — proprietary, from raspberrypi/firmware |
| `overlays/*.dtbo` | Device tree overlays (miniuart, upstream-pi4) | Yes — from Linux kernel source |
| `firmware/brcm/*` | Cypress WiFi/Bluetooth firmware blobs | **No** — proprietary |
| `RPi4_UEFI_Firmware_v1.51.zip` | Full release archive (all above) | Partially — RPI_EFI.fd is built from EDK2 |
| `SHA256SUMS` | Checksums of the zip and every file inside | Verification target |

## Version policy

- `configs/rpi4-uefi.sh` pins the canonical version.
- The zip is committed to git so the project is self-contained if GitHub goes down.
- `SHA256SUMS` provides per-file integrity so a corrupt or tampered release is detected.
- If a newer version breaks, pin back to the last known-good version in `configs/rpi4-uefi.sh`.

## Updating to a new release

```sh
# edit configs/rpi4-uefi.sh with new version + URL + sha256
# download and verify:
curl -LO "https://github.com/pftf/RPi4/releases/download/v<VER>/RPi4_UEFI_Firmware_v<VER>.zip"
sha256sum RPi4_UEFI_Firmware_v<VER>.zip   # compare to config
# recompute internal checksums and replace SHA256SUMS
# commit the new zip + SHA256SUMS + updated config

# old zip can be removed from git (git rm) or kept as history
```

## License

- `RPI_EFI.fd`: BSD-2-Clause-Patent (TianoCore EDK2)
- `start4.elf`, `fixup4.dat`: Raspberry Pi boot files license
- `firmware/brcm/*`: Cypress wireless driver license
