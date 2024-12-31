lorax/branch-$(VERSION):
	git config advice.detachedHead false
	cd lorax && git reset --hard HEAD && git checkout $(if $(_RHEL),rhel$(word 1,$(subst ., ,$(VERSION)))-branch,tags/$(shell cd lorax && git tag -l lorax-$(VERSION).* --sort=creatordate | grep -v 'lorax-40.5' | tail -n 1))
	touch lorax/branch-$(VERSION)

install-deps:
# Used by external/fedora-lorax-templates/ostree-based-installer/lorax-embed-flatpaks.tmpl
	$(install_pkg) flatpak dbus-daemon ostree
# Used to clone proper lorax branch
	$(install_pkg) git

clean: