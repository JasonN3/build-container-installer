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

# Generated vars
## Formatting = _UPPERCASE
_BASE_DIR = $(shell pwd)
_IMAGE_REPO_ESCAPED = $(subst /,\/,$(IMAGE_REPO))
_IMAGE_REPO_DOUBLE_ESCAPED = $(subst \,\\\,$(_IMAGE_REPO_ESCAPED))
_VOLID = $(firstword $(subst -, ,$(IMAGE_NAME)))-$(ARCH)-$(IMAGE_TAG)
_REPO_FILES = $(notdir $(REPOS))
_LORAX_TEMPLATES = configure_upgrades.tmpl set_installer.tmpl disable_localization.tmpl

ifeq ($(VARIANT),'Server')
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

# Step 1: Generate Lorax Templates
lorax_templates/%.tmpl: lorax_templates/%.tmpl.in
	sed 's/@IMAGE_NAME@/$(IMAGE_NAME)/'                         $(_BASE_DIR)/lorax_templates/$*.tmpl.in > $(_BASE_DIR)/lorax_templates/$*.tmpl

	sed 's/@IMAGE_TAG@/$(IMAGE_TAG)/'                           $(_BASE_DIR)/lorax_templates/$*.tmpl > $(_BASE_DIR)/lorax_templates/$*.tmpl.tmp
	mv $(_BASE_DIR)/lorax_templates/$*.tmpl{.tmp,}
	
	sed 's/@IMAGE_REPO_ESCAPED@/$(_IMAGE_REPO_DOUBLE_ESCAPED)/' $(_BASE_DIR)/lorax_templates/$*.tmpl > $(_BASE_DIR)/lorax_templates/$*.tmpl.tmp
	mv $(_BASE_DIR)/lorax_templates/$*.tmpl{.tmp,}

# Step 2: Replace vars in repo files
%.repo: /etc/yum.repos.d/%.repo
	cp /etc/yum.repos.d/$*.repo $(_BASE_DIR)/$*.repo
	sed -i "s/\$$releasever/${VERSION}/g" $(_BASE_DIR)/$*.repo
	sed -i "s/\$$basearch/${ARCH}/g" $(_BASE_DIR)/$*.repo

# Step 3: Build boot.iso using Lorax
boot.iso: $(_LORAX_TEMPLATES) $(_REPO_FILES)
	rm -Rf $(_BASE_DIR)/results
	lorax -p $(IMAGE_NAME) -v $(VERSION) -r $(VERSION) -t $(VARIANT) \
          --isfinal --squashfs-only --buildarch=$(ARCH) --volid=$(_VOLID) \
          $(_LORAX_ARGS) \
          $(foreach file,$(_REPO_FILES),--repo $(_BASE_DIR)/$(file)) \
          $(foreach file,$(_LORAX_TEMPLATES),--add-template $(file)) \
		  $(foreach file,$(ADDITIONAL_TEMPLATES),--add-template $(file)) \
		  --rootfs-size 4 \
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
	sed 's/@IMAGE_NAME@/$(IMAGE_NAME)/' $(_BASE_DIR)/xorriso/$*.sh.in > $(_BASE_DIR)/xorriso/$*.sh

	sed 's/@IMAGE_TAG@/$(IMAGE_TAG)/'   $(_BASE_DIR)/xorriso/$*.sh > $(_BASE_DIR)/xorriso/$*.sh.tmp
	mv $(_BASE_DIR)/xorriso/$*.sh{.tmp,}

	sed 's/@ARCH@/$(ARCH)/'             $(_BASE_DIR)/xorriso/$*.sh > $(_BASE_DIR)/xorriso/$*.sh.tmp
	mv $(_BASE_DIR)/xorriso/$*.sh{.tmp,}

# Step 6: Generate xorriso input
xorriso/input.txt: xorriso/gen_input.sh
	bash $(_BASE_DIR)/xorriso/gen_input.sh | tee $(_BASE_DIR)/xorriso/input.txt


clean:
	rm -Rf $(_BASE_DIR)/container || true
	rm -Rf $(_BASE_DIR)/debugdata || true
	rm -Rf $(_BASE_DIR)/pkglists || true
	rm -Rf $(_BASE_DIR)/results || true
	rm -Rf $(_BASE_DIR)/build || true
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