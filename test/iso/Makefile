ISO_NAME=deploy.iso
ISO_TESTS=$(filter-out README.md Makefile,$(wildcard *)))

all: $(ISO_TESTS)

$(ISO_TESTS):
	chmod +x $@
	ISO=../../$(ISO_NAME) ./$@

prep:
	$(eval _VARS = VERSION FLATPAK_REMOTE_NAME _FLATPAK_REPO_URL)

	sudo modprobe loop
	sudo mkdir /mnt/iso /mnt/install
	sudo mount -o loop deploy.iso /mnt/iso
	sudo mount -t squashfs -o loop /mnt/iso/images/install.img /mnt/install

	# install tests
	$(call run_tests,iso,install)
	
	# flapak tests
	if [ -n "$(FLATPAK_REMOTE_REFS)" ]; then $(call run_tests,iso,flatpak); fi

	# Cleanup
	sudo umount /mnt/install
	sudo umount /mnt/iso

.PHONY: all $(ISO_TESTS)