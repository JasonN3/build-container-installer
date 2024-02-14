arch = "x86_64"
version = "39"
base_dir = $(shell pwd)
image_repo = "ghcr.io/ublue-os"
image_name = "base-main"

deploy.iso: boot.iso xorriso/input.txt $(image_name)-$(version)
	xorriso -dialog on < xorriso/input.txt

boot.iso: lorax_templates/set_installer.tmpl
	lorax -p Fedora -v $(version) -r $(version) -t Server \
          --isfinal --buildarch=$(arch) --volid=Fedora-S-dvd-$(arch)-$(version) \
          --macboot --noupgrade \
          --repo /etc/yum.repos.d/fedora.repo \
          --repo /etc/yum.repos.d/fedora-updates.repo \
          --add-template $(base_dir)/lorax_templates/set_installer.tmpl \
          --rootfs-size 2 \
          ./results/
	mv results/images/boot.iso $(base_dir)/

$(image_name)-$(version):
	podman pull $(image_repo)/$(image_name):$(version)
	podman save --format oci-dir -o $(image_name)-$(version) $(image_repo)/$(image_name):$(version)
	podman rmi $(image_repo)/$(image_name):$(version)

install-deps:
	dnf install -y lorax xorriso podman git rpm-ostree
