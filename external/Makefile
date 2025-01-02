lorax/branch-$(VERSION): $(if $(_RHEL),lorax/branch-rhel-$(VERSION),lorax/branch-fedora-$(VERSION))
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout $(if $(_RHEL),rhel$(word 1,$(subst ., ,$(VERSION)))-branch,tags/$(shell cd lorax && git tag -l lorax-$(VERSION).* --sort=creatordate | grep -v 'lorax-40\.5\|lorax-41\.7-1' | tail -n 1))
	touch lorax/branch-$(VERSION)

lorax/branch-fedora-39:
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout tags/lorax-39.5-1
	touch lorax/branch-fedora-39

lorax/branch-fedora-40:
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout tags/lorax-40.9-1
	touch lorax/branch-fedora-40

lorax/branch-fedora-41:
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout tags/lorax-41.1-1
	touch lorax/branch-fedora-41

lorax/branch-rhel-$(VERSION):
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout rhel$(word 1,$(subst ., ,$(VERSION)))-branch
	touch lorax/branch-fedora-$(VERSION)

install-deps:
# Used by external/fedora-lorax-templates/ostree-based-installer/lorax-embed-flatpaks.tmpl
	$(install_pkg) flatpak dbus-daemon ostree
# Used to clone proper lorax branch
	$(install_pkg) git

clean: