$(IMAGE_NAME)-$(IMAGE_TAG):
	skopeo copy $(if $(IMAGE_SRC),$(IMAGE_SRC),docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)) oci:$(IMAGE_NAME)-$(IMAGE_TAG)

install-deps:
	$(install_pkg) skopeo

FILES=$(filter-out Makefile,$(wildcard *))
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif