$(IMAGE_NAME)-$(IMAGE_TAG):
	skopeo copy docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) oci:$(IMAGE_NAME)-$(IMAGE_TAG)

$(IMAGE_NAME)-$(IMAGE_TAG)-tar:
	skopeo copy oci-archive:$(IMAGE_TAR) oci:$(IMAGE_NAME):$(IMAGE_TAG)

install-deps:
	$(install_pkg) skopeo

FILES=$(filter-out Makefile,$(wildcard *))
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif
