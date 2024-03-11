# Configuration vars
## Formatting = UPPERCASE
# General
ADDITIONAL_TEMPLATES =
ARCH = x86_64
EXTRA_BOOT_PARAMS =
IMAGE_NAME = base
IMAGE_REPO = quay.io/fedora-ostree-desktops
IMAGE_TAG = $(VERSION)
REPOS = $(subst :,\:,$(shell ls /etc/yum.repos.d/*.repo))
ROOTFS_SIZE = 4
VARIANT = Server
VERSION = 39
WEB_UI = false
# Flatpak
FLATPAK_REMOTE_NAME = flathub
FLATPAK_REMOTE_URL = https://flathub.org/repo/flathub.flatpakrepo
FLATPAK_REMOTE_REFS = 
# Secure boot
ENROLLMENT_PASSWORD =
SECURE_BOOT_KEY_URL =
# Cache
DNF_CACHE = 

# Generated/internal vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_VOLID = $(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)
_REPO_FILES = $(subst /etc/yum.repos.d,repos,$(REPOS))
_LORAX_TEMPLATES            = $(shell ls lorax_templates/install_*.tmpl)    $(foreach file,$(notdir $(shell ls lorax_templates/scripts/post/install_*)),lorax_templates/post_$(file).tmpl)
_LORAX_TEMPLATES_FLATPAKS   = $(shell ls lorax_templates/flatpak_*.tmpl)    $(foreach file,$(notdir $(shell ls lorax_templates/scripts/post/flatpak_*)),lorax_templates/post_$(file).tmpl) external/fedora-lorax-templates/ostree-based-installer/lorax-embed-flatpaks.tmpl
_LORAX_TEMPLATES_SECUREBOOT = $(shell ls lorax_templates/secureboot_*.tmpl) $(foreach file,$(notdir $(shell ls lorax_templates/scripts/post/secureboot_*)),lorax_templates/post_$(file).tmpl)
_LORAX_TEMPLATES_CACHE      = $(shell ls lorax_templates/cache_*.tmpl)      $(foreach file,$(notdir $(shell ls lorax_templates/scripts/post/cache_*)),lorax_templates/post_$(file).tmpl)
_LORAX_ARGS = 
_FLATPAK_REPO_URL = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^URL=' | cut -d= -f2)
_FLATPAK_REPO_GPG = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^GPGKey=' | cut -d= -f2)
_TEMPLATE_VARS = ARCH IMAGE_NAME IMAGE_REPO _IMAGE_REPO_DOUBLE_ESCAPED _IMAGE_REPO_ESCAPED IMAGE_TAG REPOS VARIANT VERSION WEB_UI


ifeq ($(findstring redhat.repo,$(REPOS)),redhat.repo)
_LORAX_ARGS += --nomacboot --noupgrade
else ifeq ($(VARIANT),Server)
_LORAX_ARGS += --macboot --noupgrade
else
_LORAX_ARGS += --nomacboot
endif

ifeq ($(WEB_UI),true)
_LORAX_ARGS += -i anaconda-webui
endif

ifneq ($(DNF_CACHE),)
_LORAX_ARGS      += --cachedir $(DNF_CACHE)
_LORAX_TEMPLATES += $(_LORAX_TEMPLATES_CACHE)
endif

ifeq ($(findstring redhat.repo,$(REPOS)),redhat.repo)
_PLATFORM_ID = platform:el$(VERSION)
else
_PLATFORM_ID = platform:f$(VERSION)
endif

ifneq ($(FLATPAK_REMOTE_REFS),)
_LORAX_ARGS      += -i flatpak-libs
_LORAX_TEMPLATES += $(_LORAX_TEMPLATES_FLATPAKS)
_TEMPLATE_VARS   += FLATPAK_REMOTE_NAME FLATPAK_REMOTE_REFS FLATPAK_REMOTE_URL _FLATPAK_REPO_GPG _FLATPAK_REPO_URL
endif

ifneq ($(SECURE_BOOT_KEY_URL),)
_LORAX_TEMPLATES += $(_LORAX_TEMPLATES_SECUREBOOT)
_TEMPLATE_VARS   += ENROLLMENT_PASSWORD
endif

# Step 7: Build end ISO
## Default action
build/deploy.iso:  boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	mkdir $(_BASE_DIR)/build || true
	xorriso -dialog on < $(_BASE_DIR)/xorriso/input.txt
	implantisomd5 build/deploy.iso

# Step 1: Generate Lorax Templates
lorax_templates/post_%.tmpl: lorax_templates/scripts/post/%
	# Support interactive-defaults.ks
	$(eval _ISO_FILE = usr/share/anaconda/interactive-defaults.ks)
	
	header=0; \
	skip=0; \
	while read -r line; \
	do \
		if [[ $$line =~ ^\<\% ]]; \
		then \
			echo $$line >> lorax_templates/post_$*.tmpl; \
			echo >> lorax_templates/post_$*.tmpl; \
		else \
			if [[ $$header == 0 ]]; \
			then \
				if [[ $$line =~ ^##\ (.*)$$ ]]; \
				then \
					echo "append $(_ISO_FILE) \"%post --erroronfail $${BASH_REMATCH[1]}\"" >> lorax_templates/post_$*.tmpl; \
					skip=1; \
				else \
					echo "append $(_ISO_FILE) \"%post --erroronfail\"" >> lorax_templates/post_$*.tmpl; \
				fi; \
				header=1; \
			fi; \
			if [[ $$skip == 0 ]]; \
			then \
				echo "append $(_ISO_FILE) \"$${line//\"/\\\"}\"" >> lorax_templates/post_$*.tmpl; \
			fi; \
			skip=0; \
		fi; \
	done < lorax_templates/scripts/post/$*
	echo "append $(_ISO_FILE) \"%end\"" >> lorax_templates/post_$*.tmpl

	# Support new Anaconda method
	$(eval _ISO_FILE = usr/share/anaconda/post-scripts/configure_upgrades.ks)

	header=0; \
	skip=0; \
	while read -r line; \
	do \
		if [[ $$line =~ ^\<\% ]]; \
		then \
			echo >> lorax_templates/post_$*.tmpl; \
		else \
			if [[ $$header == 0 ]]; \
			then \
				if [[ $$line =~ ^##\ (.*)$$ ]]; \
				then \
					echo "append $(_ISO_FILE) \"%post --erroronfail $${BASH_REMATCH[1]}\"" >> lorax_templates/post_$*.tmpl; \
					skip=1; \
				else \
					echo "append $(_ISO_FILE) \"%post --erroronfail\"" >> lorax_templates/post_$*.tmpl; \
				fi; \
				header=1; \
			fi; \
			if [[ $$skip == 0 ]]; \
			then \
				echo "append $(_ISO_FILE) \"$${line//\"/\\\"}\"" >> lorax_templates/post_$*.tmpl; \
			fi; \
			skip=0; \
		fi; \
	done < lorax_templates/scripts/post/$*
	echo "append $(_ISO_FILE) \"%end\"" >> lorax_templates/post_$*.tmpl


repos: $(_REPO_FILES)

# Step 2: Replace vars in repo files
repos/%.repo: /etc/yum.repos.d/%.repo
	mkdir repos || true
	cp /etc/yum.repos.d/$*.repo           $(_BASE_DIR)/repos/$*.repo
	sed -i "s/\$$releasever/${VERSION}/g" $(_BASE_DIR)/repos/$*.repo
	sed -i "s/\$$basearch/${ARCH}/g"      $(_BASE_DIR)/repos/$*.repo

# Don't do anything for custom repos
%.repo:

# Step 3: Build boot.iso using Lorax
boot.iso: $(findstring lorax_templates/,$(_LORAX_TEMPLATES)) $(_REPO_FILES)
	rm -Rf $(_BASE_DIR)/results || true
	mv /etc/rpm/macros.image-language-conf /etc/rpm/macros.image-language-conf.orig || true
	cp /etc/os-release /etc/os-release.orig || true
	sed -i 's/PLATFORM_ID=.*/PLATFORM_ID="$(_PLATFORM_ID)"/' /etc/os-release

	# Download the secure boot key
	if [ -n "$(SECURE_BOOT_KEY_URL)" ]; \
	then \
    	curl --fail -L -o $(_BASE_DIR)/sb_pubkey.der $(SECURE_BOOT_KEY_URL); \
	fi

	lorax -p $(IMAGE_NAME) -v $(VERSION) -r $(VERSION) -t $(VARIANT) \
		--isfinal --squashfs-only --buildarch=$(ARCH) --volid=$(_VOLID) \
		$(_LORAX_ARGS) \
		$(foreach file,$(_REPO_FILES),--repo $(_BASE_DIR)/$(file)) \
		$(foreach file,$(_LORAX_TEMPLATES),--add-template $(_BASE_DIR)/$(file)) \
		$(foreach file,$(ADDITIONAL_TEMPLATES),--add-template $(file)) \
		$(foreach file,$(_FLATPAK_TEMPLATES),--add-template $(file)) \
		$(foreach file,$(_EXTERNAL_TEMPLATES),--add-template $(_BASE_DIR)/external/$(file)) \
		--rootfs-size $(ROOTFS_SIZE) \
		$(foreach var,$(_TEMPLATE_VARS),--add-template-var "$(shell echo $(var) | tr '[:upper:]' '[:lower:]')=$($(var))") \
		$(_BASE_DIR)/results/
	mv $(_BASE_DIR)/results/images/boot.iso $(_BASE_DIR)/
	mv -f /etc/rpm/macros.image-language-conf.orig /etc/rpm/macros.image-language-conf || true
	mv -f /etc/os-release.orig /etc/os-release || true

# Step 4: Download container image
container/$(IMAGE_NAME)-$(IMAGE_TAG):
	mkdir $(_BASE_DIR)/container || true
	skopeo copy docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) oci:$(_BASE_DIR)/container/$(IMAGE_NAME)-$(IMAGE_TAG)

# Step 5: Generate xorriso script
xorriso/%.sh: xorriso/%.sh.in
	sed -i 's/quiet/quiet $(EXTRA_BOOT_PARAMS)/g' results/boot/grub2/grub.cfg
	sed -i 's/quiet/quiet $(EXTRA_BOOT_PARAMS)/g' results/EFI/BOOT/grub.cfg
	$(eval _VARS = IMAGE_NAME IMAGE_TAG ARCH VERSION)
	$(foreach var,$(_VARS),$(var)=$($(var))) envsubst '$(foreach var,$(_VARS),$$$(var))' < $(_BASE_DIR)/xorriso/$*.sh.in > $(_BASE_DIR)/xorriso/$*.sh 

# Step 6: Generate xorriso input
xorriso/input.txt: xorriso/gen_input.sh
	bash $(_BASE_DIR)/xorriso/gen_input.sh | tee $(_BASE_DIR)/xorriso/input.txt


clean:
	rm -Rf $(_BASE_DIR)/build || true
	rm -Rf $(_BASE_DIR)/container || true
	rm -Rf $(_BASE_DIR)/debugdata || true
	rm -Rf $(_BASE_DIR)/pkglists || true
	rm -Rf $(_BASE_DIR)/repos || true
	rm -Rf $(_BASE_DIR)/results || true
	rm -f $(_BASE_DIR)/lorax_templates/*.tmpl || true
	rm -f $(_BASE_DIR)/xorriso/input.txt || true
	rm -f $(_BASE_DIR)/xorriso/*.sh || true
	rm -f $(_BASE_DIR)/{original,final}-pkgsizes.txt || true
	rm -f $(_BASE_DIR)/lorax.conf || true
	rm -f $(_BASE_DIR)/*.iso || true
	rm -f $(_BASE_DIR)/*.log || true

install-deps:
	dnf install -y lorax xorriso skopeo flatpak dbus-daemon ostree coreutils

test: test-iso test-vm

test-iso:
	$(eval _TESTS = $(filter-out README.md,$(shell ls tests/iso)))
	$(eval _VARS = VERSION FLATPAK_REMOTE_NAME _FLATPAK_REPO_URL)

	sudo apt-get update
	sudo apt-get install -y squashfs-tools
	sudo modprobe loop
	sudo mkdir /mnt/iso /mnt/install
	sudo mount -o loop deploy.iso /mnt/iso
	sudo mount -t squashfs -o loop /mnt/iso/images/install.img /mnt/install

	chmod +x $(foreach test,$(_TESTS),tests/iso/$(test))
	for test in $(_TESTS); \
	do \
	  $(foreach var,$(_VARS),$(var)=$($(var))) ./tests/iso/$${test}; \
	done

	# Cleanup
	sudo umount /mnt/install
	sudo umount /mnt/iso

test-vm:
	$(eval _TESTS = $(filter-out README.md,$(shell ls tests/vm)))
	chmod +x $(foreach test,$(_TESTS),tests/vm/$(test))
	for test in $(_TESTS); do ./tests/vm/$${test} deploy.iso; done
	
.PHONY: clean install-deps test test-iso test-vm container/$(IMAGE_NAME)-$(IMAGE_TAG)
