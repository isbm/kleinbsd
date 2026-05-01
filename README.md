# KleinBSD

## Foreword

NetBSD image builder for the Raspberry Pi 4. The goal of this project
is to build one of the cutest Unix in the world — NetBSD — directly
from the sources, tailored for your own needs.

It then gets out of your way so you can turn NetBSD into whatever you
need: an embedded blackbox on a tower, a telemetry relay in a ditch,
or just a Pi on your desk that runs an OS you can read the source of.

Everything is self-contained. No dependencies spill outside the project
directory. Process is even simpler than one can imagine. Example
building NetBSD 11:

```sh
make select-profile rpi4-netbsd11
make build
make image
make write-sd
```

You pick a supported profile, it builds NetBSD from sources, injects
the UEFI firmware, and gives you an `arm64-uefi-fw.img` you `dd` to an
SD card. That's it.

> Important: Ubuntu and Debian are the only supported build hosts for now.
