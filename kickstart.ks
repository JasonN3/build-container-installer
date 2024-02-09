%include submodules/fedora-kickstarts/fedora-live-base.ks

%packages
podman
ostree
%end

%post
systemctl set-default anaconda.target
%end