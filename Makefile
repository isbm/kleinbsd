PROFILE ?= $(shell if [ -f .envrc ]; then . ./.envrc >/dev/null 2>&1; printf '%s' "$$PROFILE"; else printf '%s' qemu-amd64; fi)

.PHONY: help setup docs fetch fetch-official apply-config build watch-logs image run write-sd inspect-sd patch-rpi4-sd clean-images profiles select-profile

Y := \033[1;33m
N := \033[0m

help:
	@printf '%b\n' "$(Y)KleinBSD targets:$(N)"
	@printf '%s\n' ''
	@printf '  %-31s %s\n' 'make select-profile <name>' 'Persist active profile in .envrc'
	@printf '  %-31s %s\n' 'make profiles'             'List image profiles'
	@printf '  %-31s %s\n' 'make fetch'                'Clone/fetch NetBSD source into build/netbsd-src'
	@printf '  %-31s %s\n' 'make fetch-official'       'Download official image for selected profile'
	@printf '  %-31s %s\n' 'make build'                'Build NetBSD tools and release into build/obj-PROFILE'
	@printf '  %-31s %s\n' 'make apply-config'         'Apply selected profile kernel config into build/netbsd-src'
	@printf '  %-31s %s\n' 'make image'                'Build selected profile into images/PROFILE'
	@printf '  %-31s %s\n' 'make write-sd'             'Write selected profile image to SD card'
	@printf '  %-31s %s\n' 'make inspect-sd'           'Inspect FAT boot partition on an SD card'
	@printf '  %-31s %s\n' 'make patch-rpi4-sd'        'Patch SD config.txt for boot diagnostics'
	@printf '  %-31s %s\n' 'make clean-images'         'Remove built image files'
	@printf '  %-31s %s\n' 'make docs'                 'Generate doc/kleinbsd.pdf'
	@printf '  %-31s %s\n' 'make watch-logs'           'Tail build logs in tmux split panes'
	@printf '%s\n' ''
	@printf '%b\n' "$(Y)Selected profile:$(N)"
	@printf '%s\n' '  $(PROFILE)'
	@printf '%s\n' ''
	@printf '%b\n' "$(Y)Raspberry Pi 4 from source:$(N)"
	@printf '%s\n' '  make select-profile rpi4'
	@printf '%s\n' '  make build'
	@printf '%s\n' '  make image'
	@printf '%s\n' '  make write-sd'
	@printf '%s\n' ''
	@printf '%b\n' "$(Y)Useful overrides:$(N)"
	@printf '%s\n' '  PROFILE=qemu-amd64 JOBS=8 IMAGE_MB=768 make image'
	@printf '%s\n' '  NETBSD_DIR=build/netbsd-src OBJ_DIR=build/obj-rpi4 make image'

# ---- dependency setup (Ubuntu / Debian) ------------------------------

APT_PKGS := build-essential bison flex curl gzip unzip git sudo tmux
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
		-V mainfont="Latin Modern Roman" \
		-V monofont="Latin Modern Mono" \
		-V geometry:margin=1in \
		--toc
	@printf '%s\n' 'Generated: doc/kleinbsd.pdf'

profiles:
	@find profiles -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort

select-profile:
	@name="$$(printf '%s\n' '$(MAKECMDGOALS)' | tr ' ' '\n' | grep -vx 'select-profile' | head -1)"; \
	if [ -z "$${name}" ]; then \
		printf '%s\n' 'usage: make select-profile <name>'; \
		printf '%s\n' '       make select-profile PROFILE=<name>'; \
		exit 1; \
	fi; \
	if [ -n '$(PROFILE)' ] && [ -z "$${name}" ]; then \
		name='$(PROFILE)'; \
	fi; \
	if [ ! -f "profiles/$${name}/profile.sh" ]; then \
		printf '%s\n' "unknown profile: $${name}"; \
		printf '%s\n' 'available profiles:'; \
		find profiles -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort; \
		exit 1; \
	fi; \
	printf '%s\n' "export PROFILE=$${name}" > .envrc; \
	printf '%s\n' "Selected profile: $${name}"

fetch:
	./scripts/fetch-netbsd.sh

fetch-official:
	PROFILE=$(PROFILE) ./scripts/fetch-official-image.sh

apply-config:
	PROFILE=$(PROFILE) ./scripts/apply-kernel-config.sh

build: setup
	PROFILE=$(PROFILE) ./scripts/build-netbsd.sh

watch-logs:
	@. lib/project.sh >/dev/null 2>&1; \
	TLOG="$${PROJECT_DIR}/logs/$${PROFILE}/tools.log"; \
	RLOG="$${PROJECT_DIR}/logs/$${PROFILE}/release.log"; \
	if command -v tmux >/dev/null 2>&1 && [ -z "$${TMUX:-}" ]; then \
		tmux new-session -s kleinbsd-logs \
			"tail -F \"$$TLOG\"" \; \
			split-window -h "tail -F \"$$RLOG\"" \; \
			set-option -w remain-on-exit on; \
	elif command -v tmux >/dev/null 2>&1; then \
		tmux split-window -h "tail -F \"$$RLOG\""; \
		tail -F "$$TLOG"; \
	else \
		printf '%s\n' "Install tmux for split-pane log watching."; \
		printf '%s\n' "Or run: tail -f %s" "$$TLOG"; \
		printf '%s\n' "        tail -f %s" "$$RLOG"; \
	fi

image: setup
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

# Catch-all: allows "make select-profile rpi4" without make complaining
# that "rpi4" is an unknown target.
%:
	@:
