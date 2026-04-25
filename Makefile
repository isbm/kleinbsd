PROFILE ?= $(shell if [ -f .envrc ]; then . ./.envrc >/dev/null 2>&1; printf '%s' "$$PROFILE"; else printf '%s' qemu-amd64; fi)

.PHONY: help fetch fetch-official apply-config netbsd image run write-sd inspect-sd patch-rpi4-sd clean-images profiles select-profile

help:
	@printf '%s\n' 'kleinbsd targets:'
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
	@printf '%s\n' 'Typical first run:'
	@printf '%s\n' '  make fetch'
	@printf '%s\n' '  make select-profile PROFILE=qemu-amd64'
	@printf '%s\n' '  make netbsd'
	@printf '%s\n' '  make image'
	@printf '%s\n' '  make run'
	@printf '%s\n' ''
	@printf '%s\n' 'Raspberry Pi 4 SD image:'
	@printf '%s\n' '  make select-profile PROFILE=rpi4'
	@printf '%s\n' '  make netbsd'
	@printf '%s\n' '  make image'
	@printf '%s\n' '  make write-sd'
	@printf '%s\n' ''
	@printf '%s\n' 'Official Raspberry Pi 4 image test:'
	@printf '%s\n' '  make select-profile PROFILE=rpi4-official'
	@printf '%s\n' '  make fetch-official'
	@printf '%s\n' '  make write-sd'
	@printf '%s\n' ''
	@printf '%s\n' 'Stable NetBSD 10 Raspberry Pi 4 image test:'
	@printf '%s\n' '  make select-profile PROFILE=rpi4-netbsd10'
	@printf '%s\n' '  make fetch-official'
	@printf '%s\n' '  make write-sd'
	@printf '%s\n' ''
	@printf '%s\n' 'Useful overrides:'
	@printf '%s\n' '  PROFILE=qemu-amd64 JOBS=8 IMAGE_MB=768 make image'
	@printf '%s\n' '  NETBSD_DIR=/path/to/src OBJ_DIR=/path/to/obj-rpi4 make image'

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
