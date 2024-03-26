TESTS=$(filter-out README.md Makefile,$(wildcard *)) $(filter-out README.md Makefile,$(wildcard */*))

all: $(TESTS)

$(TESTS):
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(eval TARGET=$(subst $(DIR)/,,$@))
	$(MAKE) -w -C $(DIR) $(TARGET)

install-deps:
	if [ "$(PACKAGE_MANAGER)" =~ apt.* ]; then $(PACKAGE_MANAGER) update; fi
	$(PACKAGE_MANAGER) install -y qemu qemu-utils xorriso unzip qemu-system-x86 netcat socat jq isomd5sum ansible make coreutils squashfs-tools

.PHONY: all $(TESTS)