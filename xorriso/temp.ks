user --name alice --password $6$4ax95Fe8EwB0S5o7$zz23FfruNX4Tp0EoiDYwRN5D6GUnUqGZHm/d7QkUdXB19lvbh2sd8K19cKSfU0sCO05n8WtMcn5jpcmh9l5I20 --iscrypted --groups wheel
rootpw --lock
lang en_US.UTF-8
keyboard us
timezone UTC
clearpart --all
network --device=link --bootproto=dhcp --onboot=on --activate
reqpart --add-boot

part swap --fstype=swap --size=1024
part / --fstype=ext4 --grow

reboot --eject
%post
bootc switch --mutate-in-place --transport registry quay.io/centos-bootc/centos-bootc:stream9
%end
