ISO_NAME=deploy.iso
ISO_TESTS=$(wildcard install_*) $(if $(FLATPAK_REMOTE_REFS),$(wildcard flatpak_*))$(if $(FLATPAK_DIR),$(wildcard flatpak_*))

all: $(ISO_TESTS) clean

$(ISO_TESTS): mnt/iso
	$(eval _VARS = ISO_NAME VERSION FLATPAK_REMOTE_NAME _FLATPAK_REPO_URL)
	chmod +x $@
	$(foreach var,$(_VARS),$(var)=$($(var))) ./$@

mnt/iso:
	sudo modprobe loop
	sudo mkdir -p mnt/iso mnt/live mnt/install
	sudo mount -o loop ../../$(ISO_NAME) mnt/iso
	sudo mount -t squashfs -o loop mnt/iso/images/install.img $(if $(_RHEL),mnt/live,mnt/install)
	$(if $(_RHEL),sudo mount mnt/live/LiveOS/rootfs.img mnt/install)

clean:
	sudo umount mnt/install
	$(if $(_RHEL),sudo umount mnt/live)
	sudo umount mnt/iso
	sudo rmdir mnt/install mnt/iso $(wildcard mnt/live)

install-deps:
	$(install_pkg) isomd5sum coreutils squashfs-tools curl

.PHONY: all $(ISO_TESTS) clean