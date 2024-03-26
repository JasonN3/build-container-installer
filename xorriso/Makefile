xorriso/input.txt: xorriso/gen_input.sh
	sed -i 's/quiet/quiet $(EXTRA_BOOT_PARAMS)/g' results/boot/grub2/grub.cfg
	sed -i 's/quiet/quiet $(EXTRA_BOOT_PARAMS)/g' results/EFI/BOOT/grub.cfg
	$(eval _VARS = FLATPAK_DIR IMAGE_NAME IMAGE_TAG ARCH VERSION)
	$(foreach var,$(_VARS),$(var)=$($(var))) bash $(_BASE_DIR)/xorriso/gen_input.sh | tee $(_BASE_DIR)/xorriso/input.txt

install-deps:

FILES=$(wildcard input.txt)
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif