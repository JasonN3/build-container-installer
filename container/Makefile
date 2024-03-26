container/$(IMAGE_NAME)-$(IMAGE_TAG):
	mkdir $(_BASE_DIR)/container || true
	skopeo copy docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) oci:$(_BASE_DIR)/container/$(IMAGE_NAME)-$(IMAGE_TAG)

install-deps:
	if [ "$(PACKAGE_MANAGER)" =~ apt.* ]; then $(PACKAGE_MANAGER) update; fi
	$(PACKAGE_MANAGER) install -y skopeo

FILES=$(filter-out Makefile,$(wildcard *))
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif