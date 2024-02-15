arch = x86_64
version = 39
base_dir = $(shell pwd)
image_repo = ghcr.io/ublue-os
image_name = base-main
variant = Silverblue

image_repo_escaped = $(subst /,\/,$(image_repo))
image_repo_double_escaped = $(subst \,\\\,$(image_repo_escaped))

ifeq ($(variant),'Server')
lorax_args = --macboot --noupgrade
else
lorax_args = --nomacboot
endif

$(image_name)-$(version).iso: boot.iso container/$(image_name)-$(version) xorriso/input.txt 
	xorriso -dialog on < $(base_dir)/xorriso/input.txt

boot.iso: lorax_templates/set_installer.tmpl lorax_templates/configure_upgrades.tmpl
	rm -Rf $(base_dir)/results
	lorax -p $(image_name) -v $(version) -r $(version) -t $(variant) \
          --isfinal --buildarch=$(arch) --volid=$(image_name)-$(arch)-$(version) \
          $(lorax_args) \
	  --rootfs-size 3 \
          --repo /etc/yum.repos.d/fedora.repo \
          --repo /etc/yum.repos.d/fedora-updates.repo \
          --add-template $(base_dir)/lorax_templates/set_installer.tmpl \
		  --add-template $(base_dir)/lorax_templates/configure_upgrades.tmpl \
	  -i anaconda-webui \
          $(base_dir)/results/
	mv $(base_dir)/results/images/boot.iso $(base_dir)/

container/$(image_name)-$(version):
	mkdir container
	podman pull $(image_repo)/$(image_name):$(version)
	podman save --format oci-dir -o $(base_dir)/container/$(image_name)-$(version) $(image_repo)/$(image_name):$(version)
	podman rmi $(image_repo)/$(image_name):$(version)

install-deps:
	dnf install -y lorax xorriso podman git rpm-ostree



lorax_templates/%.tmpl: lorax_templates/%.tmpl.in
	sed 's/@IMAGE_NAME@/$(image_name)/'                        $(base_dir)/lorax_templates/$*.tmpl.in > $(base_dir)/lorax_templates/$*.tmpl
	sed 's/@IMAGE_REPO@/$(image_repo_escaped)/'                $(base_dir)/lorax_templates/$*.tmpl > $(base_dir)/lorax_templates/$*.tmpl.tmp
	mv $(base_dir)/lorax_templates/$*.tmpl{.tmp,}
	sed 's/@VERSION@/$(version)/'                              $(base_dir)/lorax_templates/$*.tmpl > $(base_dir)/lorax_templates/$*.tmpl.tmp
	mv $(base_dir)/lorax_templates/$*.tmpl{.tmp,}
	sed 's/@IMAGE_REPO_ESCAPED@/$(image_repo_double_escaped)/' $(base_dir)/lorax_templates/$*.tmpl > $(base_dir)/lorax_templates/$*.tmpl.tmp
	mv $(base_dir)/lorax_templates/$*.tmpl{.tmp,}



xorriso/input.txt: xorriso/gen_input.sh
	bash $(base_dir)/xorriso/gen_input.sh | tee $(base_dir)/xorriso/input.txt

xorriso/%.sh: xorriso/%.sh.in
	sed 's/@IMAGE_NAME@/$(image_name)/' $(base_dir)/xorriso/$*.sh.in > $(base_dir)/xorriso/$*.sh
	sed 's/@VERSION@/$(version)/'       $(base_dir)/xorriso/$*.sh > $(base_dir)/xorriso/$*.sh.tmp
	mv $(base_dir)/xorriso/$*.sh{.tmp,}
	sed 's/@ARCH@/$(arch)/'             $(base_dir)/xorriso/$*.sh > $(base_dir)/xorriso/$*.sh.tmp
	mv $(base_dir)/xorriso/$*.sh{.tmp,}


clean:
	rm -Rf $(base_dir)/container || true
	rm -Rf $(base_dir)/debugdata || true
	rm -Rf $(base_dir)/pkglists || true
	rm -Rf $(base_dir)/results || true
	rm -f $(base_dir)/lorax_templates/*.tmpl || true
	rm -f $(base_dir)/xorriso/input.txt || true
	rm -f $(base_dir)/xorriso/*.sh || true
	rm -f $(base_dir)/{original,final}-pkgsizes.txt || true
	rm -f $(base_dir)/lorax.conf || true
	rm -f $(base_dir)/*.iso || true
	rm -f $(base_dir)/*.log || true	
	
	
