$(IMAGE_NAME)-$(IMAGE_TAG):
	skopeo copy $(if $(IMAGE_SRC),$(IMAGE_SRC),docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)) oci:$(IMAGE_NAME)-$(IMAGE_TAG)

$(IMAGE_NAME)-$(IMAGE_TAG).tar: $(IMAGE_NAME)-$(IMAGE_TAG)

	umoci unpack --rootless --image $(IMAGE_NAME)-$(IMAGE_TAG)@$(shell jq -r '.manifests[0].digest' ../container/$(IMAGE_NAME)-$(IMAGE_TAG)/index.json) image_root
	tar -C image_root/rootfs -cf $(IMAGE_NAME)-$(IMAGE_TAG).tar

install-deps:
	$(install_pkg) skopeo umoci jq

FILES=$(filter-out Makefile,$(wildcard *))
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif