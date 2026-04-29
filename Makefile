PROFILE ?= $(shell if [ -f .envrc ]; then . ./.envrc >/dev/null 2>&1; printf '%s' "$$PROFILE"; else printf '%s' qemu-amd64; fi)

.PHONY: help setup docs fetch fetch-official apply-config netbsd image run write-sd inspect-sd patch-rpi4-sd clean-images profiles select-profile

help:
	@printf '%s\n' 'kleinbsd targets:'
	@printf '%s\n' ''
	@printf '%s\n' '  make setup         Install build dependencies (Ubuntu/Debian)'
	@printf '%s\n' '  make docs          Generate doc/kleinbsd.pdf'
	@printf '%s\n' ''
	@printf '%s\n' '  make select-profile PROFILE=<name>'
	@printf '%s\n' '                     Persist active profile in .envrc'
	@printf '%s\n' '  make profiles      List image profiles'
	@printf '%s\n' '  make fetch         Clone/fetch NetBSD source into ../netbsd'
	@printf '%s\n' '  make fetch-official Download official image for selected profile'
	@printf '%s\n' '  make netbsd        Build NetBSD tools and release into ../obj-PROFILE'
	@printf '%s\n' '  make apply-config  Apply selected profile kernel config into ../netbsd'
	@printf '%s\n' '  make image         Build selected profile into ./images/PROFILE'
	@printf '%s\n' '  make run           Run selected profile image, if runnable'
	@printf '%s\n' '  make write-sd      Interactively write selected profile image to SD'
	@printf '%s\n' '  make inspect-sd    Inspect FAT boot partition on an SD card'
	@printf '%s\n' '  make patch-rpi4-sd Patch rpi4 SD config.txt for boot diagnostics'
	@printf '%s\n' '  make clean-images  Remove built image files'
	@printf '%s\n' ''
	@printf '%s\n' 'Selected profile:'
	@printf '%s\n' '  $(PROFILE)'
	@printf '%s\n' ''
	@printf '%s\n' 'Raspberry Pi 4 from source:'
	@printf '%s\n' '  make setup'
	@printf '%s\n' '  make select-profile PROFILE=rpi4'
	@printf '%s\n' '  make fetch'
	@printf '%s\n' '  make netbsd'
	@printf '%s\n' '  make image'
	@printf '%s\n' '  make write-sd'
	@printf '%s\n' ''
	@printf '%s\n' 'Raspberry Pi 4 quick-start (official binary):'
	@printf '%s\n' '  ./uefi-test-community.sh'
	@printf '%s\n' '  sudo dd if=images/rpi4-uefi/arm64-uefi-fw.img of=/dev/sdX bs=4M conv=fsync status=progress'
	@printf '%s\n' ''
	@printf '%s\n' 'Useful overrides:'
	@printf '%s\n' '  PROFILE=qemu-amd64 JOBS=8 IMAGE_MB=768 make image'
	@printf '%s\n' '  NETBSD_DIR=build/netbsd-src OBJ_DIR=build/obj-rpi4 make image'

# ---- dependency setup (Ubuntu / Debian) ------------------------------

APT_PKGS := build-essential bison flex curl gzip unzip git sudo
APT_PKGS += util-linux coreutils mtools
APT_PKGS += pandoc texlive-xetex texlive-latex-recommended texlive-fonts-recommended lmodern fonts-dejavu

setup:
	@if ! command -v apt-get >/dev/null 2>&1; then \
		printf '%s\n' 'apt-get not found. Only Ubuntu/Debian supported.'; \
		exit 1; \
	fi
	@missing=$$(for pkg in $(APT_PKGS); do \
		dpkg -s "$$pkg" >/dev/null 2>&1 || printf '%s\n' "$$pkg"; \
	done); \
	if [ -z "$$missing" ]; then \
		exit 0; \
	fi; \
	printf '%s\n' '>>> Installing missing packages:'; \
	printf '    %s\n' $$missing; \
	sudo apt-get update; \
	sudo apt-get install -y -o Dpkg::Options::="--force-confold" $$missing; \
	printf '%s\n' '>>> Done.'

# ---- documentation ---------------------------------------------------

docs: setup doc/kleinbsd.md
	pandoc doc/kleinbsd.md -o doc/kleinbsd.pdf \
		--pdf-engine=xelatex \
		-V geometry:margin=1in \
		--toc
	@printf '%s\n' 'Generated: doc/kleinbsd.pdf'

profiles:
	@find profiles -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort

select-profile:
	@if [ -z '$(PROFILE)' ]; then \
		printf '%s\n' 'usage: make select-profile PROFILE=<name>'; \
		exit 1; \
	fi
	@if [ ! -f 'profiles/$(PROFILE)/profile.sh' ]; then \
		printf '%s\n' 'unknown profile: $(PROFILE)'; \
		printf '%s\n' 'available profiles:'; \
		find profiles -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort; \
		exit 1; \
	fi
	@printf '%s\n' 'export PROFILE=$(PROFILE)' > .envrc
	@printf '%s\n' 'Selected profile: $(PROFILE)'

fetch:
	./scripts/fetch-netbsd.sh

fetch-official:
	PROFILE=$(PROFILE) ./scripts/fetch-official-image.sh

apply-config:
	PROFILE=$(PROFILE) ./scripts/apply-kernel-config.sh

netbsd:
	PROFILE=$(PROFILE) ./scripts/build-netbsd.sh

image:
	PROFILE=$(PROFILE) ./scripts/build-image.sh

run:
	PROFILE=$(PROFILE) ./scripts/run.sh

write-sd:
	PROFILE=$(PROFILE) ./scripts/write-sd.sh

inspect-sd:
	./scripts/inspect-sd.sh

patch-rpi4-sd:
	./scripts/patch-rpi4-sd.sh

clean-images:
	rm -f images/*/*.img images/*/*.img.gz images/*/MD5 images/*/SHA512
