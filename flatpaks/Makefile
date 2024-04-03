IMAGE := $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
FLATPAK_DIR := $(if $(GITHUB_WORKSPACE),$(shell mktemp -d -p $(GITHUB_WORKSPACE) flatpak.XXX),$(PWD))

.PHONY: full_list
full_list: repo
	cat $(FLATPAK_DIR)/list.txt >&2
	

repo: script.sh
	$(if $(GITHUB_WORKSPACE),cp script.sh $(FLATPAK_DIR)/)
	docker run --rm --privileged --entrypoint bash -e FLATPAK_SYSTEM_DIR=/flatpak/flatpak -e FLATPAK_TRIGGERSDIR=/flatpak/triggers --volume $(FLATPAK_DIR):/flatpak_dir $(IMAGE) /flatpak_dir/script.sh
	$(if $(GITHUB_OUTPUT),echo "flatpak_dir=$(FLATPAK_DIR)" >> $(GITHUB_OUTPUT))
	docker rmi $(IMAGE)

script.sh:
	cat << EOF > script.sh
	set -ex
	mkdir -p /flatpak/flatpak /flatpak/triggers
	mkdir /var/tmp || true
	chmod -R 1777 /var/tmp
	flatpak config --system --set languages "*"
	flatpak remote-add --system $(FLATPAK_REMOTE_NAME) $(FLATPAK_REMOTE_URL)
	flatpak install --system -y $(FLATPAK_REMOTE_REFS)
	ostree init --repo=/flatpak_dir/repo --mode=archive-z2
	for i in \$$(ostree refs --repo=\$${FLATPAK_SYSTEM_DIR}/repo | grep '^deploy/' | sed 's/^deploy\///g')
	do
	echo "Copying \$${i}..."
	ostree --repo=/flatpak_dir/repo pull-local \$${FLATPAK_SYSTEM_DIR}/repo \$$(ostree --repo=\$${FLATPAK_SYSTEM_DIR}/repo rev-parse $(FLATPAK_REMOTE_NAME)/\$${i})
	mkdir -p \$$(dirname /flatpak_dir/repo/refs/heads/\$${i})
	ostree --repo=\$${FLATPAK_SYSTEM_DIR}/repo rev-parse $(FLATPAK_REMOTE_NAME)/\$${i} > /flatpak_dir/repo/refs/heads/\$${i}
	done
	flatpak build-update-repo /flatpak_dir/repo
	ostree refs --repo=/flatpak_dir/repo > /flatpak_dir/list.txt
	EOF

install-deps:

clean:

.ONESHELL: