# Configuration vars
## Formatting = UPPERCASE
# General
export ADDITIONAL_TEMPLATES =
export ARCH = x86_64
export EXTRA_BOOT_PARAMS =
export IMAGE_NAME = base
export IMAGE_REPO = quay.io/fedora-ostree-desktops
export IMAGE_TAG = $(VERSION)
REPOS = $(subst :,\:,$(shell ls /etc/yum.repos.d/*.repo))
export ROOTFS_SIZE = 4
export VARIANT = Server
export VERSION = 39
export WEB_UI = false
# Flatpak
export FLATPAK_REMOTE_NAME = flathub
export FLATPAK_REMOTE_URL = https://flathub.org/repo/flathub.flatpakrepo
export FLATPAK_REMOTE_REFS =
export FLATPAK_REMOTE_REFS_DIR =
export FLATPAK_DIR =
# Secure boot
export ENROLLMENT_PASSWORD =
export SECURE_BOOT_KEY_URL =

###################
# Hidden vars

# Cache
export DNF_CACHE = 
export PACKAGE_MANAGER = dnf

# Functions
## Formatting = lowercase
# Get a list of templates for the feature
# $1 = feature
get_templates = $(shell ls lorax_templates/$(1)_*.tmpl) \
                $(foreach file,$(notdir $(shell ls lorax_templates/scripts/post/$(1)_*)),lorax_templates/post_$(file).tmpl)

# Generated/internal vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_LORAX_ARGS = 
_LORAX_TEMPLATES = $(call get_templates,install)
_REPO_FILES = $(subst /etc/yum.repos.d,repos,$(REPOS))
_TEMP_DIR = $(shell mktemp -d)
_TEMPLATE_VARS = ARCH _BASE_DIR IMAGE_NAME IMAGE_REPO _IMAGE_REPO_DOUBLE_ESCAPED _IMAGE_REPO_ESCAPED IMAGE_TAG REPOS _RHEL VARIANT VERSION WEB_UI
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

ifneq ($(FLATPAK_DIR),)
_FLATPAK_REPO_GPG = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^GPGKey=' | cut -d= -f2)
_FLATPAK_REPO_URL = $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^URL=' | cut -d= -f2)
_LORAX_ARGS      += -i flatpak-libs
_LORAX_TEMPLATES += $(call get_templates,flatpak)
_TEMPLATE_VARS   += FLATPAK_DIR FLATPAK_REMOTE_NAME FLATPAK_REMOTE_REFS FLATPAK_REMOTE_URL _FLATPAK_REPO_GPG _FLATPAK_REPO_URL
else
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
_TEMPLATE_VARS   += FLATPAK_DIR FLATPAK_REMOTE_NAME FLATPAK_REMOTE_REFS FLATPAK_REMOTE_URL _FLATPAK_REPO_GPG _FLATPAK_REPO_URL
endif
endif


ifneq ($(SECURE_BOOT_KEY_URL),)
_LORAX_TEMPLATES += $(call get_templates,secureboot)
_TEMPLATE_VARS   += ENROLLMENT_PASSWORD
endif

_SUBDIRS = container external flatpak_refs lorax_templates repos xorriso

# Step 7: Build end ISO
## Default action
build/deploy.iso: boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	mkdir $(_BASE_DIR)/build || true
	xorriso -dialog on < $(_BASE_DIR)/xorriso/input.txt
	implantisomd5 build/deploy.iso

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


FILES_TO_CLEAN = $(wildcard build debugdata pkglists results original-pkgsizes.txt final-pkgsizes.txt lorax.conf *.iso *log)
clean:
	rm -Rf $(FILES_TO_CLEAN)
	$(foreach DIR,$(_SUBDIRS),$(MAKE) -C $(DIR) clean;)

install-deps:
	if [ "$(PACKAGE_MANAGER)" =~ apt.* ]; then $(PACKAGE_MANAGER) update; fi
	$(PACKAGE_MANAGER) install -y lorax xorriso coreutils gettext 
	$(foreach DIR,$(_SUBDIRS),$(MAKE) -C $(DIR) install-deps;)

test-vm: ansible_inventory
	

_SUBMAKES = $(_SUBDIRS) test $(filter-out README.md Makefile,$(wildcard test/*)) $(filter-out README.md Makefile,$(wildcard test/*/*))
$(_SUBMAKES):
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(eval TARGET=$(subst $(DIR)/,,$@))
	$(MAKE) -w -C $(DIR) $(TARGET)

$(addsuffix /%,$(_SUBMAKES)):
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(eval TARGET=$(subst $(DIR)/,,$@))
	$(MAKE) -w -C $(DIR) $(TARGET)

.PHONY: clean install-deps $(_SUBMAKES) test
