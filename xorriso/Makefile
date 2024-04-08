input.txt: gen_input.sh
	find ../results/
	sed -i 's/quiet/quiet $(EXTRA_BOOT_PARAMS)/g' ../results/boot/grub2/grub.cfg
	sed -i 's/quiet/quiet $(EXTRA_BOOT_PARAMS)/g' ../results/EFI/BOOT/grub.cfg
	$(eval _VARS = ARCH FLATPAK_DIR IMAGE_NAME IMAGE_TAG ISO_NAME VERSION)
	$(foreach var,$(_VARS),$(var)=$($(var))) bash gen_input.sh | tee input.txt

install-deps:

FILES=$(wildcard input.txt)
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif