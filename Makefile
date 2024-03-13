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
FLATPAK_REMOTE_REFS_DIR =
# Secure boot
ENROLLMENT_PASSWORD =
SECURE_BOOT_KEY_URL =
# Cache
DNF_CACHE = 

# Functions
## Formatting = lowercase
# Get a list of templates for the feature
# $1 = feature
get_templates = $(shell ls lorax_templates/$(1)_*.tmpl) \
                $(foreach file,$(notdir $(shell ls lorax_templates/scripts/post/$(1)_*)),lorax_templates/post_$(file).tmpl)

# Converts a post script to a template
# $1 = script to convert
# $2 = file on ISO to write
# $3 = whether to copy the '<%' lines to the template
convert_post_to_tmpl = header=0; \
	skip=0; \
	while read -r line; \
	do \
		if [[ $$line =~ ^\<\% ]]; \
		then \
			if [[ '$(3)' == 'true' ]]; \
			then \
				echo $$line >> lorax_templates/post_$(1).tmpl; \
			fi; \
			echo >> lorax_templates/post_$(1).tmpl; \
		else \
			if [[ $$header == 0 ]]; \
			then \
				if [[ $$line =~ ^\#\#\ (.*)$$ ]]; \
				then \
					echo "append $(2) \"%post --erroronfail $${BASH_REMATCH[1]}\"" >> lorax_templates/post_$(1).tmpl; \
					skip=1; \
				else \
					echo "append $(2) \"%post --erroronfail\"" >> lorax_templates/post_$(1).tmpl; \
				fi; \
				header=1; \
			fi; \
			if [[ $$skip == 0 ]]; \
			then \
				echo "append $(2) \"$${line//\"/\\\"}\"" >> lorax_templates/post_$(1).tmpl; \
			fi; \
			skip=0; \
		fi; \
	done < lorax_templates/scripts/post/$(1); \
	echo "append $(2) \"%end\"" >> lorax_templates/post_$(1).tmpl

# Generated/internal vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_LORAX_ARGS = 
_LORAX_TEMPLATES = $(call get_templates,install)
_REPO_FILES = $(subst /etc/yum.repos.d,repos,$(REPOS))
_TEMP_DIR = $(shell mktemp -d)
_TEMPLATE_VARS = ARCH IMAGE_NAME IMAGE_REPO _IMAGE_REPO_DOUBLE_ESCAPED _IMAGE_REPO_ESCAPED IMAGE_TAG REPOS _RHEL VARIANT VERSION WEB_UI
_VOLID = $(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)

ifeq ($(findstring redhat.repo,$(REPOS)),redhat.repo)
_RHEL = true
else
_RHEL = false
endif

ifeq ($(_RHEL),true)
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
_LORAX_TEMPLATES += $(call get_templates,cache)
_TEMPLATE_VARS   += DNF_CACHE
endif

ifneq ($(FLATPAK_REMOTE_REFS_DIR),)
COLLECTED_REFS = $(foreach file,$(shell ls $(FLATPAK_REMOTE_REFS_DIR)/*),$(shell cat $(file)))
FLATPAK_REMOTE_REFS += $(sort $(COLLECTED_REFS))
endif

ifneq ($(FLATPAK_REMOTE_REFS),)
_FLATPAK_REPO_GPG = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^GPGKey=' | cut -d= -f2)
_FLATPAK_REPO_URL = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^URL=' | cut -d= -f2)
_LORAX_ARGS      += -i flatpak-libs
_LORAX_TEMPLATES += $(call get_templates,flatpak) \
					external/fedora-lorax-templates/ostree-based-installer/lorax-embed-flatpaks.tmpl
_TEMPLATE_VARS   += FLATPAK_REMOTE_NAME FLATPAK_REMOTE_REFS FLATPAK_REMOTE_URL _FLATPAK_REPO_GPG _FLATPAK_REPO_URL

endif

ifneq ($(SECURE_BOOT_KEY_URL),)
_LORAX_TEMPLATES += $(call get_templates,secureboot)
_TEMPLATE_VARS   += ENROLLMENT_PASSWORD
endif

# Step 7: Build end ISO
## Default action
build/deploy.iso: boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	mkdir $(_BASE_DIR)/build || true
	xorriso -dialog on < $(_BASE_DIR)/xorriso/input.txt
	implantisomd5 build/deploy.iso

external/lorax/branch-$(VERSION):
	git config advice.detachedHead false
	cd external/lorax && git reset --hard HEAD && git checkout tags/$(shell cd external/lorax && git tag -l lorax-$(VERSION).* --sort=creatordate | tail -n 1)
	touch external/lorax/branch-$(VERSION)

# Step 1: Generate Lorax Templates
lorax_templates/post_%.tmpl: lorax_templates/scripts/post/%
	# Support interactive-defaults.ks
	([ ${_RHEL} == false ] && [ $(VERSION) -le 38 ]) && ($(call convert_post_to_tmpl,$*,usr/share/anaconda/interactive-defaults.ks,true)) || true

	# Support new Anaconda method
	([ ${_RHEL} == true ] || [ $(VERSION) -ge 39 ]) && ($(call convert_post_to_tmpl,$*,usr/share/anaconda/post-scripts/$*.sh,true)) || true

repos: $(_REPO_FILES)

# Step 2: Replace vars in repo files
repos/%.repo: /etc/yum.repos.d/%.repo
	mkdir repos || true
	cp /etc/yum.repos.d/$*.repo           $(_BASE_DIR)/repos/$*.repo
	sed -i "s/\$$releasever/${VERSION}/g" $(_BASE_DIR)/repos/$*.repo
	sed -i "s/\$$basearch/${ARCH}/g"      $(_BASE_DIR)/repos/$*.repo

# Step 3: Build boot.iso using Lorax
boot.iso: external/lorax/branch-$(VERSION) $(filter lorax_templates/%,$(_LORAX_TEMPLATES)) $(_REPO_FILES)
	rm -Rf $(_BASE_DIR)/results || true
	mv /etc/rpm/macros.image-language-conf $(_TEMP_DIR)/macros.image-language-conf || true

	# Download the secure boot key
	if [ -n "$(SECURE_BOOT_KEY_URL)" ]; \
	then \
    	curl --fail -L -o $(_BASE_DIR)/sb_pubkey.der $(SECURE_BOOT_KEY_URL); \
	fi

	lorax -p $(IMAGE_NAME) -v $(VERSION) -r $(VERSION) -t $(VARIANT) \
		--isfinal --squashfs-only --buildarch=$(ARCH) --volid=$(_VOLID) --sharedir $(_BASE_DIR)/external/lorax/share/templates.d/99-generic \
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
	mv -f $(_TEMP_DIR)/macros.image-language-conf /etc/rpm/macros.image-language-conf || true

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
	dnf install -y lorax xorriso skopeo flatpak dbus-daemon ostree coreutils gettext git

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

	# install tests
	chmod +x $(foreach test,$(filter install_%,$(_TESTS)),tests/iso/$(test))
	for test in $(_TESTS); \
	do \
	  $(foreach var,$(_VARS),$(var)=$($(var))) ./tests/iso/$${test}; \
	done

	# flapak tests
	if [ -n "$(FLATPAK_REMOTE_REFS)" ]; \
	then \
		chmod +x $(foreach test,$(filter flatpak_%,$(_TESTS)),tests/iso/$(test)); \
		for test in $(_TESTS); \
		do \
		$(foreach var,$(_VARS),$(var)=$($(var))) ./tests/iso/$${test}; \
		done; \
	fi

	# Cleanup
	sudo umount /mnt/install
	sudo umount /mnt/iso

test-vm:
	$(eval _TESTS = $(filter-out README.md,$(shell ls tests/vm)))
	chmod +x $(foreach test,$(_TESTS),tests/vm/$(test))
	for test in $(_TESTS); do ./tests/vm/$${test} deploy.iso; done

.PHONY: clean install-deps test test-iso test-vm
