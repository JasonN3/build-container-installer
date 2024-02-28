# Configuration vars
## Formatting = UPPERCASE
ARCH = x86_64
VERSION = 39
IMAGE_REPO = ghcr.io/ublue-os
IMAGE_NAME = base-main
IMAGE_TAG = $(VERSION)
EXTRA_BOOT_PARAMS =
VARIANT = Kinoite
WEB_UI = false
ENROLLMENT_PASSWORD = ublue-os
SECURE_BOOT_KEY_URL =

# Generated vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_VOLID = $(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)

ifeq ($(VARIANT),'Server')
_LORAX_ARGS = --macboot --noupgrade
else
_LORAX_ARGS = --nomacboot
endif

ifeq ($(WEB_UI),true)
_LORAX_ARGS += -i anaconda-webui
endif

# Step 7: Move end ISO to root
## Default action
$(IMAGE_NAME)-$(IMAGE_TAG).iso: output/$(IMAGE_NAME)-$(IMAGE_TAG).iso
	mv output/$(IMAGE_NAME)-$(IMAGE_TAG).iso $(IMAGE_NAME)-$(IMAGE_TAG).iso

# Step 6: Build end ISO file
output/$(IMAGE_NAME)-$(IMAGE_TAG).iso: boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	mkdir $(_BASE_DIR)/output || true
	xorriso -dialog on < $(_BASE_DIR)/xorriso/input.txt

# Step 1: Generate Lorax Templates
lorax_templates/%.tmpl: lorax_templates/%.tmpl.in
	sed 's/@IMAGE_NAME@/$(IMAGE_NAME)/'                        $(_BASE_DIR)/lorax_templates/$*.tmpl.in > $(_BASE_DIR)/lorax_templates/$*.tmpl

	sed 's/@IMAGE_TAG@/$(IMAGE_TAG)/'                          $(_BASE_DIR)/lorax_templates/$*.tmpl > $(_BASE_DIR)/lorax_templates/$*.tmpl.tmp
	mv $(_BASE_DIR)/lorax_templates/$*.tmpl{.tmp,}
	
	sed 's/@IMAGE_REPO_ESCAPED@/$(_IMAGE_REPO_DOUBLE_ESCAPED)/' $(_BASE_DIR)/lorax_templates/$*.tmpl > $(_BASE_DIR)/lorax_templates/$*.tmpl.tmp
	mv $(_BASE_DIR)/lorax_templates/$*.tmpl{.tmp,}

# Step 2: Build boot.iso using Lorax
boot.iso: lorax_templates/set_installer.tmpl lorax_templates/configure_upgrades.tmpl
	rm -Rf $(_BASE_DIR)/results

	# Set the enrollment password
	sed 's/@ENROLLMENT_PASSWORD@/$(ENROLLMENT_PASSWORD)/' $(_BASE_DIR)/scripts/enroll-secureboot-key.sh.in > $(_BASE_DIR)/scripts/enroll-secureboot-key.sh

	# Download the secure boot key
	if [ -n "$(SECURE_BOOT_KEY_URL)" ]; then\
    curl --fail -L -o $(_BASE_DIR)/sb_pubkey.der $(SECURE_BOOT_KEY_URL);\
	fi

	# Remove the "Test this media & install" menu entry
	sed -i '/menuentry '\''Test this media & install @PRODUCT@ @VERSION@'\'' --class fedora --class gnu-linux --class gnu --class os {/,/}/d' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-bios.cfg
	sed -i '/menuentry '\''Test this media & install @PRODUCT@ @VERSION@'\'' --class fedora --class gnu-linux --class gnu --class os {/,/}/d' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-efi.cfg

	# Set the default menu entry to the first one
	sed -i 's/set default="1"/set default="0"/' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-bios.cfg
	sed -i 's/set default="1"/set default="0"/' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-efi.cfg

	# Add Extra Boot Parameters to all menu entries
	sed -i 's/linux @KERNELPATH@ @ROOT@ quiet/linux @KERNELPATH@ @ROOT@ quiet $(EXTRA_BOOT_PARAMS)/g' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-bios.cfg
	sed -i 's/linuxefi @KERNELPATH@ @ROOT@ quiet/linuxefi @KERNELPATH@ @ROOT@ quiet $(EXTRA_BOOT_PARAMS)/g' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-efi.cfg

	sed -i 's/linux @KERNELPATH@ @ROOT@ nomodeset quiet/linux @KERNELPATH@ @ROOT@ nomodeset quiet $(EXTRA_BOOT_PARAMS)/g' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-bios.cfg
	sed -i 's/linuxefi @KERNELPATH@ @ROOT@ nomodeset quiet/linuxefi @KERNELPATH@ @ROOT@ nomodeset quiet $(EXTRA_BOOT_PARAMS)/g' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-efi.cfg

	sed -i 's/linux @KERNELPATH@ @ROOT@ inst.rescue quiet/linux @KERNELPATH@ @ROOT@ inst.rescue quiet $(EXTRA_BOOT_PARAMS)/g' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-bios.cfg
	sed -i 's/linuxefi @KERNELPATH@ @ROOT@ inst.rescue quiet/linuxefi @KERNELPATH@ @ROOT@ inst.rescue quiet $(EXTRA_BOOT_PARAMS)/g' /usr/share/lorax/templates.d/99-generic/config_files/x86/grub2-efi.cfg

	# Build boot.iso
	lorax -p $(IMAGE_NAME) -v $(VERSION) -r $(VERSION) -t $(VARIANT) \
          --isfinal --buildarch=$(ARCH) --volid=$(_VOLID) \
          $(_LORAX_ARGS) \
          --repo /etc/yum.repos.d/fedora.repo \
          --repo /etc/yum.repos.d/fedora-updates.repo \
          --add-template $(_BASE_DIR)/lorax_templates/set_installer.tmpl \
		  --add-template $(_BASE_DIR)/lorax_templates/configure_upgrades.tmpl \
		  --add-template $(_BASE_DIR)/lorax_templates/secure_boot_key.tmpl \
          $(_BASE_DIR)/results/
	mv $(_BASE_DIR)/results/images/boot.iso $(_BASE_DIR)/

# Step 3: Download container image
container/$(IMAGE_NAME)-$(IMAGE_TAG):
	mkdir container || true
	podman pull $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	podman save --format oci-dir -o $(_BASE_DIR)/container/$(IMAGE_NAME)-$(IMAGE_TAG) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	podman rmi $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

install-deps:
	dnf install -y lorax xorriso podman git

# Step 4: Generate xorriso script
xorriso/%.sh: xorriso/%.sh.in
	sed 's/@IMAGE_NAME@/$(IMAGE_NAME)/' $(_BASE_DIR)/xorriso/$*.sh.in > $(_BASE_DIR)/xorriso/$*.sh

	sed 's/@IMAGE_TAG@/$(IMAGE_TAG)/'   $(_BASE_DIR)/xorriso/$*.sh > $(_BASE_DIR)/xorriso/$*.sh.tmp
	mv $(_BASE_DIR)/xorriso/$*.sh{.tmp,}

	sed 's/@ARCH@/$(ARCH)/'             $(_BASE_DIR)/xorriso/$*.sh > $(_BASE_DIR)/xorriso/$*.sh.tmp
	mv $(_BASE_DIR)/xorriso/$*.sh{.tmp,}

# Step 5: Generate xorriso input
xorriso/input.txt: xorriso/gen_input.sh
	bash $(_BASE_DIR)/xorriso/gen_input.sh | tee $(_BASE_DIR)/xorriso/input.txt


clean:
	rm -Rf $(_BASE_DIR)/container || true
	rm -Rf $(_BASE_DIR)/debugdata || true
	rm -Rf $(_BASE_DIR)/pkglists || true
	rm -Rf $(_BASE_DIR)/results || true
	rm -f $(_BASE_DIR)/lorax_templates/*.tmpl || true
	rm -f $(_BASE_DIR)/xorriso/input.txt || true
	rm -f $(_BASE_DIR)/xorriso/*.sh || true
	rm -f $(_BASE_DIR)/{original,final}-pkgsizes.txt || true
	rm -f $(_BASE_DIR)/lorax.conf || true
	rm -f $(_BASE_DIR)/*.iso || true
	rm -f $(_BASE_DIR)/*.log || true
	
.PHONY: clean	
