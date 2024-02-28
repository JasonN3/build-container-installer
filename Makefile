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
ADDITIONAL_TEMPLATES = ""
ROOTFS_SIZE = 4

# Generated vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_VOLID = $(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)
_REPO_FILES = $(subst /etc/yum.repos.d,repos,$(REPOS))
_LORAX_TEMPLATES = $(subst .in,,$(shell ls lorax_templates/*.tmpl.in))

ifeq ($(VARIANT),Server)
_LORAX_ARGS = --macboot --noupgrade
else
_LORAX_ARGS = --nomacboot
endif

ifeq ($(WEB_UI),true)
_LORAX_ARGS += -i anaconda-webui
endif

# Step 7: Buid end ISO
## Default action
build/deploy.iso:  boot.iso container/$(IMAGE_NAME)-$(IMAGE_TAG) xorriso/input.txt
	mkdir $(_BASE_DIR)/build || true
	xorriso -dialog on < $(_BASE_DIR)/xorriso/input.txt
	implantisomd5 build/deploy.iso

# Step 1: Generate Lorax Templates
lorax_templates/%.tmpl: lorax_templates/%.tmpl.in
	$(eval _VARS = IMAGE_NAME IMAGE_TAG _IMAGE_REPO_DOUBLE_ESCAPED)
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
	lorax -p $(IMAGE_NAME) -v $(VERSION) -r $(VERSION) -t $(VARIANT) \
          --isfinal --squashfs-only --buildarch=$(ARCH) --volid=$(_VOLID) \
          $(_LORAX_ARGS) \
          $(foreach file,$(_REPO_FILES),--repo $(_BASE_DIR)/$(file)) \
          $(foreach file,$(_LORAX_TEMPLATES),--add-template $(_BASE_DIR)/$(file)) \
		  $(foreach file,$(ADDITIONAL_TEMPLATES),--add-template $(file)) \
		  --rootfs-size $(ROOTFS_SIZE) \
          $(_BASE_DIR)/results/
	mv $(_BASE_DIR)/results/images/boot.iso $(_BASE_DIR)/

# Step 4: Download container image
container/$(IMAGE_NAME)-$(IMAGE_TAG):
	mkdir container || true
	podman pull $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	podman save --format oci-dir -o $(_BASE_DIR)/container/$(IMAGE_NAME)-$(IMAGE_TAG) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	podman rmi $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

# Step 5: Generate xorriso script
xorriso/%.sh: xorriso/%.sh.in
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
	dnf install -y lorax xorriso podman
	
.PHONY: clean install-deps

