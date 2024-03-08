# Configuration vars
## Formatting = UPPERCASE
ARCH = x86_64
VERSION = 39
IMAGE_REPO = quay.io/fedora-ostree-desktops
IMAGE_NAME = base
IMAGE_TAG = $(VERSION)
VARIANT = Server
WEB_UI = false
REPOS = /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
ADDITIONAL_TEMPLATES = 
FLATPAK_REMOTE_NAME = flathub
FLATPAK_REMOTE_URL = https://flathub.org/repo/flathub.flatpakrepo
FLATPAK_REMOTE_REFS = 
ENROLLMENT_PASSWORD =
SECURE_BOOT_KEY_URL =
ADDITIONAL_TEMPLATES =
EXTRA_BOOT_PARAMS =
ROOTFS_SIZE = 4

# Generated vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_VOLID = $(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)
_REPO_FILES = $(subst /etc/yum.repos.d,repos,$(REPOS))
_LORAX_TEMPLATES = $(subst .in,,$(shell ls lorax_templates/*.tmpl.in)) $(foreach file,$(shell ls lorax_templates/scripts/post),lorax_templates/post_$(file).tmpl)
_EXTERNAL_TEMPLATES = fedora-lorax-templates/ostree-based-installer/lorax-embed-flatpaks.tmpl
_FLATPAK_REPO_URL = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^URL=' | cut -d= -f2)
_FLATPAK_REPO_GPG = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^GPGKey=' | cut -d= -f2)
_TEMPLATE_VARS = ARCH VERSION IMAGE_REPO IMAGE_NAME IMAGE_TAG VARIANT WEB_UI REPOS _IMAGE_REPO_ESCAPED _IMAGE_REPO_DOUBLE_ESCAPED FLATPAK_REMOTE_NAME FLATPAK_REMOTE_URL FLATPAK_REMOTE_REFS _FLATPAK_REPO_URL _FLATPAK_REPO_GPG ENROLLMENT_PASSWORD

ifeq ($(VARIANT),Server)
_LORAX_ARGS = --macboot --noupgrade
else
_LORAX_ARGS = --nomacboot
endif

ifeq ($(WEB_UI),true)
_LORAX_ARGS += -i anaconda-webui
endif

ifneq ($(FLATPAK_REMOTE_REFS),)
_LORAX_ARGS += -i flatpak-libs
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

lorax_templates/%.tmpl: lorax_templates/%.tmpl.in
	$(eval _VARS = IMAGE_NAME IMAGE_TAG _IMAGE_REPO_DOUBLE_ESCAPED _IMAGE_REPO_ESCAPED)
	$(foreach var,$(_VARS),$(var)=$($(var))) envsubst '$(foreach var,$(_VARS),$$$(var))' < $(_BASE_DIR)/lorax_templates/$*.tmpl.in > $(_BASE_DIR)/lorax_templates/$*.tmpl

# Step 2: Replace vars in repo files
repos/%.repo: /etc/yum.repos.d/%.repo
	mkdir repos || true
	cp /etc/yum.repos.d/$*.repo           $(_BASE_DIR)/repos/$*.repo
	sed -i "s/\$$releasever/${VERSION}/g" $(_BASE_DIR)/repos/$*.repo
	sed -i "s/\$$basearch/${ARCH}/g"      $(_BASE_DIR)/repos/$*.repo

# Don't do anything for custom repos
%.repo:

# Step 3: Build boot.iso using Lorax
boot.iso: $(_LORAX_TEMPLATES) $(_REPO_FILES)
	rm -Rf $(_BASE_DIR)/results || true
	rm /etc/rpm/macros.image-language-conf || true

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
	
.PHONY: clean install-deps test test-iso test-vm
