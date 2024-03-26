lorax/branch-$(VERSION):
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout tags/$(shell cd lorax && git tag -l lorax-$(VERSION).* --sort=creatordate | tail -n 1)
	touch lorax/branch-$(VERSION)

install-deps:
	if [ "$(PACKAGE_MANAGER)" =~ apt.* ]; then $(PACKAGE_MANAGER) update; fi
	# Used by external/fedora-lorax-templates/ostree-based-installer/lorax-embed-flatpaks.tmpl
	$(PACKAGE_MANAGER) install -y flatpak dbus-daemon ostree
	# Used to clone proper lorax branch
	$(PACKAGE_MANAGER) install -y git

clean: