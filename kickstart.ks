%include submodules/fedora-kickstarts/fedora-disk-server.ks

%packages
-@arm-tools
podman
ostree
%end
