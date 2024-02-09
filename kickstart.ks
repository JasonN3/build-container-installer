%include submodules/fedora-kickstarts/fedora-live-workstation.ks

%packages
podman
ostree
%end

%post
systemctl set-default anaconda.target
%end