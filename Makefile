include Makefile.inputs

###################
# Hidden vars

export SHELL := /bin/sh
# Cache
export DNF_CACHE := 
export PACKAGE_MANAGER := dnf

# Functions
## Formatting = lowercase
# Get a list of templates for the feature
# $1 = feature
define get_templates
	$(wildcard lorax_templates/$(1)_*.tmpl)
    $(foreach file,$(notdir $(wildcard lorax_templates/scripts/post/$(1)_*)),lorax_templates/post_$(file).tmpl)
endef

define install_pkg
	$(PACKAGE_MANAGER) install -y $(if $(findstring dnf,$(PACKAGE_MANAGER)),--disablerepo='*-testing')
endef
export install_pkg

# Generated/internal vars
## Formatting = _UPPERCASE
_IMAGE_REPO_ESCAPED        := $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED := $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_LORAX_ARGS                := 
_LORAX_TEMPLATES           := $(call get_templates,install)
_REPO_FILES                := $(subst /etc/yum.repos.d,repos,$(REPOS))
_TEMP_DIR                  := $(shell mktemp -d)
_TEMPLATE_VARS             := ARCH IMAGE_NAME IMAGE_REPO _IMAGE_REPO_DOUBLE_ESCAPED _IMAGE_REPO_ESCAPED IMAGE_SIGNED IMAGE_TAG REPOS _RHEL VARIANT VERSION WEB_UI
_VOLID                     := $(shell echo "$(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)" | cut -c 1-32)

ifeq ($(findstring redhat.repo,$(REPOS)),redhat.repo)
export _RHEL := true
_LORAX_TEMPLATES += $(call get_templates,rhel)
else
undefine _RHEL
endif

ifeq ($(_RHEL),true)
_LORAX_ARGS += --nomacboot --noupgrade
else ifeq ($(VARIANT),Server)
_LORAX_ARGS += --macboot --noupgrade --squashfs-only
else
_LORAX_ARGS += --nomacboot --squashfs-only
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
_FLATPAK_REPO_GPG := $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^GPGKey=' | cut -d= -f2)
export _FLATPAK_REPO_URL := $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^URL=' | cut -d= -f2)
_LORAX_ARGS      += -i flatpak-libs
_LORAX_TEMPLATES += $(call get_templates,flatpak)
_TEMPLATE_VARS   += FLATPAK_DIR FLATPAK_REMOTE_NAME FLATPAK_REMOTE_REFS FLATPAK_REMOTE_URL _FLATPAK_REPO_GPG _FLATPAK_REPO_URL
else
ifneq ($(FLATPAK_REMOTE_REFS_DIR),)
       COLLECTED_REFS      := $(foreach file,$(filter-out README.md Makefile,$(wildcard $(FLATPAK_REMOTE_REFS_DIR)/*)),$(shell cat $(file)))
export FLATPAK_REMOTE_REFS += $(sort $(COLLECTED_REFS))
endif

ifneq ($(FLATPAK_REMOTE_REFS),)
_FLATPAK_REPO_GPG := $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^GPGKey=' | cut -d= -f2)
export _FLATPAK_REPO_URL := $(shell curl -L $(FLATPAK_REMOTE_URL) | grep -i '^URL=' | cut -d= -f2)
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

_SUBDIRS := container external flatpak_refs lorax_templates repos xorriso test

# Create checksum
## Default action
$(ISO_NAME)-CHECKSUM: $(ISO_NAME)
	cd $(dir $(ISO_NAME)) && sha256sum $(notdir $(ISO_NAME)) > $(notdir $(ISO_NAME))-CHECKSUM

# Build end ISO
$(ISO_NAME): results/images/boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	$(if $(wildcard $(dir $(ISO_NAME))),,mkdir -p $(dir $(ISO_NAME)); chmod ugo=rwX $(dir $(ISO_NAME)))
	xorriso -dialog on < xorriso/input.txt
	implantisomd5 $(ISO_NAME)
	chmod ugo=r $(ISO_NAME)
	$(if $(GITHUB_OUTPUT), echo "iso_name=$(ISO_NAME)" >> $(GITUHB_OUTPUT))

# Download the secure boot key
sb_pubkey.der:
	curl --fail -L -o sb_pubkey.der $(SECURE_BOOT_KEY_URL)

# Build boot.iso using Lorax
results/images/boot.iso: external/lorax/branch-$(VERSION) $(filter lorax_templates/%,$(_LORAX_TEMPLATES)) $(filter repos/%,$(_REPO_FILES)) $(if $(SECURE_BOOT_KEY_URL),sb_pubkey.der)
	$(if $(wildcard results), rm -Rf results)
	$(if $(wildcard /etc/rpm/macros.image-language-conf),mv /etc/rpm/macros.image-language-conf $(_TEMP_DIR)/macros.image-language-conf)

	lorax -p $(IMAGE_NAME) -v $(VERSION) -r $(VERSION) -t $(VARIANT) \
		--isfinal --buildarch=$(ARCH) --volid=$(_VOLID) --sharedir $(PWD)/external/lorax/share/templates.d/99-generic \
		$(_LORAX_ARGS) \
		$(foreach file,$(_REPO_FILES),--repo $(patsubst repos/%,$(PWD)/repos/%,$(file))) \
		$(foreach file,$(_LORAX_TEMPLATES),--add-template $(PWD)/$(file)) \
		$(foreach file,$(ADDITIONAL_TEMPLATES),--add-template $(file)) \
		$(foreach file,$(_FLATPAK_TEMPLATES),--add-template $(file)) \
		$(foreach file,$(_EXTERNAL_TEMPLATES),--add-template $(PWD)/external/$(file)) \
		--rootfs-size $(ROOTFS_SIZE) \
		$(foreach var,$(_TEMPLATE_VARS),--add-template-var "$(shell echo $(var) | tr '[:upper:]' '[:lower:]')=$($(var))") \
		results/
	$(if $(wildcard $(_TEMP_DIR)/macros.image-language-conf),mv -f $(_TEMP_DIR)/macros.image-language-conf /etc/rpm/macros.image-language-conf)


FILES_TO_CLEAN := $(wildcard build debugdata pkglists results original-pkgsizes.txt final-pkgsizes.txt lorax.conf *.iso *log)
.PHONY: clean
clean:
	rm -Rf $(FILES_TO_CLEAN)
	$(foreach DIR,$(_SUBDIRS),$(MAKE) -w -C $(DIR) clean;)

.PHONY: install-deps
install-deps:
	$(install_pkg) lorax xorriso coreutils gettext syslinux-nonlinux
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
