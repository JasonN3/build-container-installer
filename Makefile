arch = x86_64
version = 39
base_dir = $(shell pwd)
image_repo = ghcr.io/ublue-os
image_name = base-main
variant = Server

image_repo_escaped = $(subst /,\/,$(image_repo))
image_repo_double_escaped = $(subst \,\\\,$(image_repo_escaped))

deploy.iso: boot.iso xorriso/input.txt $(image_name)-$(version)
	xorriso -dialog on < xorriso/input.txt

boot.iso: lorax_templates/set_installer.tmpl lorax_templates/configure_upgrades.tmpl
	rm -Rf results
	lorax -p $(image_name) -v $(version) -r $(version) -t $(variant) \
          --isfinal --buildarch=$(arch) --volid=$(image_name)-$(arch)-$(version) \
          --macboot --noupgrade \
          --repo /etc/yum.repos.d/fedora.repo \
          --repo /etc/yum.repos.d/fedora-updates.repo \
          --add-template $(base_dir)/lorax_templates/set_installer.tmpl \
		  --add-template $(base_dir)/lorax_templates/configure_upgrades.tmpl \
          --rootfs-size 2 \
          ./results/
	mv results/images/boot.iso $(base_dir)/

$(image_name)-$(version):
	podman pull $(image_repo)/$(image_name):$(version)
	podman save --format oci-dir -o $(image_name)-$(version) $(image_repo)/$(image_name):$(version)
	podman rmi $(image_repo)/$(image_name):$(version)

install-deps:
	dnf install -y lorax xorriso podman git rpm-ostree



lorax_templates/%.tmpl: lorax_templates/%.tmpl.in
	sed 's/@IMAGE_NAME@/$(image_name)/'                        lorax_templates/$*.tmpl.in > lorax_templates/$*.tmpl
	sed 's/@IMAGE_REPO@/$(image_repo_escaped)/'                lorax_templates/$*.tmpl > lorax_templates/$*.tmpl
	sed 's/@VERSION@/$(version)/'                              lorax_templates/$*.tmpl > lorax_templates/$*.tmpl
	sed 's/@IMAGE_REPO_ESCAPED@/$(image_repo_double_escaped)/' lorax_templates/$*.tmpl > lorax_templates/$*.tmpl



xorriso/input.txt: xorriso/gen_input.sh
	bash xorriso/gen_input.sh > xorriso/input.txt

xorriso/%.sh: xorriso/%.sh.in
	sed 's/@IMAGE_NAME@/$(image_name)-$(version)/' xorriso/$*.sh.in > xorriso/$*.sh
	sed 's/@VERSION@/$(version)/'                  xorriso/$*.sh > xorriso/$*.sh


clean:
	rm -f boot.iso || true
	rm -f deploy.iso || true
	rm -Rf $(image_name)-$(version) || true
	rm lorax_templates/*.tmpl || true
	rm xorriso/input.txt || true
	rm xorriso/*.sh || true
