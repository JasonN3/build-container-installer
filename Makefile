include Makefile.inputs

###################
# Hidden vars

export SHELL = /bin/sh
# Cache
export DNF_CACHE = 
export PACKAGE_MANAGER = dnf

# Functions
## Formatting = lowercase
# Get a list of templates for the feature
# $1 = feature
define get_templates
	$(wildcard lorax_templates/$(1)_*.tmpl)
    $(foreach file,$(notdir $(wildcard lorax_templates/scripts/post/$(1)_*)),lorax_templates/post_$(file).tmpl)
endef

define install_pkg
	$(PACKAGE_MANAGER) install -y
endef
export install_pkg

# Generated/internal vars
## Formatting = _UPPERCASE
export _BASE_DIR = $(shell pwd)
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

include Makefile.flatpak


ifneq ($(SECURE_BOOT_KEY_URL),)
_LORAX_TEMPLATES += $(call get_templates,secureboot)
_TEMPLATE_VARS   += ENROLLMENT_PASSWORD
endif

_SUBDIRS = container external flatpak_refs lorax_templates repos xorriso test

# Create checksum
## Default action
$(ISO_NAME)-CHECKSUM: $(ISO_NAME)
	cd $(dir $(ISO_NAME)) && sha256sum $(notdir $(ISO_NAME)) > $(notdir $(ISO_NAME))-CHECKSUM

# Build end ISO
$(ISO_NAME): results/images/boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	$(if $(wildcard $(dir $(ISO_NAME))),,mkdir -p $(dir $(ISO_NAME)); chmod ugo=rwX $(dir $(ISO_NAME)))
	xorriso -dialog on < $(_BASE_DIR)/xorriso/input.txt
	implantisomd5 $(ISO_NAME)
	chmod ugo=r $(ISO_NAME)
	$(if $(GITHUB_OUTPUT), echo "iso_name=$(ISO_NAME)" >> $(GITUHB_OUTPUT))

# Build boot.iso using Lorax
results/images/boot.iso: external/lorax/branch-$(VERSION) $(filter lorax_templates/%,$(_LORAX_TEMPLATES)) $(_REPO_FILES)
	$(if $(wildcard results), rm -Rf results)
	$(if $(wildcard /etc/rpm/macros.image-language-conf),mv /etc/rpm/macros.image-language-conf $(_TEMP_DIR)/macros.image-language-conf)

# Download the secure boot key
	$(if $(SECURE_BOOT_KEY_URL), curl --fail -L -o $(_BASE_DIR)/sb_pubkey.der $(SECURE_BOOT_KEY_URL))

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
	$(if $(wildcard $(_TEMP_DIR)/macros.image-language-conf),mv -f $(_TEMP_DIR)/macros.image-language-conf /etc/rpm/macros.image-language-conf)


FILES_TO_CLEAN = $(wildcard build debugdata pkglists results original-pkgsizes.txt final-pkgsizes.txt lorax.conf *.iso *log)
.PHONY: clean
clean:
	rm -Rf $(FILES_TO_CLEAN)
	$(foreach DIR,$(_SUBDIRS),$(MAKE) -w -C $(DIR) clean;)

.PHONY: install-deps
install-deps:
	$(install_pkg) lorax xorriso coreutils gettext
	$(foreach DIR,$(filter-out test,$(_SUBDIRS)),$(MAKE) -w -C $(DIR) install-deps;)


.PHONY: $(_SUBDIRS) $(wildcard test/*) $(wildcard test/*/*)
test $(addsuffix /*,$(_SUBDIRS)):
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(if $(filter-out $(DIR),$@), $(eval TARGET=$(subst $(DIR)/,,$@)),$(eval TARGET=))
	$(MAKE) -w -C $(DIR) $(TARGET)

.DEFAULT:
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(if $(filter-out $(DIR),$@), $(eval TARGET=$(subst $(DIR)/,,$@)),$(eval TARGET=))
	$(MAKE) -w -C $(DIR) $(TARGET)
