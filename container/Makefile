ifeq ($(IMAGE_SRC),)
IMAGE_SRC += docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
endif

$(IMAGE_NAME)-$(IMAGE_TAG):
	skopeo copy $(IMAGE_SRC) oci:$(IMAGE_NAME)-$(IMAGE_TAG)

install-deps:
	$(install_pkg) skopeo

FILES=$(filter-out Makefile,$(wildcard *))
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif