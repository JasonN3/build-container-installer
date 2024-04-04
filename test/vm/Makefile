VM_TESTS=$(wildcard install_*) $(if $(FLATPAK_REMOTE_REFS),$(wildcard flatpak_*))$(if $(FLATPAK_DIR),$(wildcard flatpak_*))

all: $(VM_TESTS) clean

$(VM_TESTS): start_vm ansible_inventory
	$(eval _VARS = IMAGE_REPO IMAGE_NAME IMAGE_TAG)

	ansible -i ansible_inventory -m ansible.builtin.wait_for_connection vm

	chmod +x $@
	$(foreach var,$(_VARS),$(var)=$($(var))) ./$@

ansible_inventory: 
	echo "ungrouped:" > ansible_inventory
	echo "  hosts:" >> ansible_inventory
	echo "    vm:" >> ansible_inventory
	echo "      ansible_host: $(VM_IP)" >> ansible_inventory
	echo "      ansible_port: $(VM_PORT)" >> ansible_inventory
	echo "      ansible_user: $(VM_USER)" >> ansible_inventory
	echo "      ansible_password: $(VM_PASS)" >> ansible_inventory
	echo "      ansible_become_pass: $(VM_PASS)" >> ansible_inventory
	echo "      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'" >> ansible_inventory

.PHONY: $(VM_TESTS) install-deps

install-deps:
	$(install_pkg) qemu qemu-utils xorriso qemu-system-x86 netcat socat jq ansible curl

files/mnt/iso:
	$(if $(wildcard files/mnt),,mkdir files/mnt)
	$(if $(wildcard files/mnt/iso),,mkdir files/mnt/iso)
	sudo mount -o loop ../../$(ISO_NAME) files/mnt/iso

files/grub.cfg: files/mnt/iso
	cp files/mnt/iso/boot/grub2/grub.cfg files/grub.cfg
	sed -i 's/quiet/console=ttyS0,115200n8 inst.ks=cdrom:\/ks.cfg/' files/grub.cfg
	sed -i 's/set default="1"/set default="0"/'                     files/grub.cfg
	sed -i 's/set timeout=60/set timeout=1/'                        files/grub.cfg

.PHONY: clean
clean:
	$(if $(wildcard start_vm), kill "$(shell cat start_vm)")
	$(if $(wildcard files/mnt/iso),sudo umount files/mnt/iso)
	$(if $(wildcard files/mnt/iso),rmdir files/mnt/iso)
	$(if $(wildcard ansible_inventory),rm ansible_inventory)
	$(if $(wildcard files/install.iso),rm files/install.iso)
	$(if $(wildcard files/disk.qcow2),rm files/disk.qcow2)
	$(if $(wildcard install_os),rm install_os)
	$(if $(wildcard start_vm),rm start_vm)

files/install.iso: files/grub.cfg
	xorriso -dialog on << EOF
	-indev ../../$(ISO_NAME)
	-outdev files/install.iso
	-boot_image any replay
	-joliet on
	-compliance joliet_long_names
	-map files/ks.cfg ks.cfg
	-chmod 0444 ks.cfg
	-map files/grub.cfg boot/grub2/grub.cfg
	-end
	EOF

files/disk.qcow2:
	qemu-img create -f qcow2 files/disk.qcow2 50G

install_os: files/install.iso files/disk.qcow2
	timeout 1h qemu-system-x86_64 -name "Anaconda" -boot d -m 4096 -cpu qemu64 -display none -cdrom files/install.iso -smp 2 -hda files/disk.qcow2 -serial telnet:localhost:4321,server=on,wait=off & QEMU_PID=$$!
	echo "PID: $$QEMU_PID"
	timeout 1m bash -c "while ! (echo > /dev/tcp/127.0.0.1/4321); do sleep 0.1; done"
	(nc localhost 4321 | tee vm.stdout) &
	wait $$QEMU_PID
	touch install_os

.ONESHELL:

start_vm: install_os
	mkfifo vm.stdin
	qemu-system-x86_64 -name "Anaconda" \
	-m 4096 -cpu qemu64 -display none -smp 2 \
	-chardev socket,path=/tmp/qga.sock,server=on,wait=off,id=qga0 \
	-device e1000,netdev=net0 \
	-netdev user,id=net0,hostfwd=tcp::$(VM_PORT)-:22 \
	-device virtio-serial \
	-device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0 \
	-boot c -hda files/disk.qcow2 -serial telnet:localhost:4321,server=on,wait=off & export QEMU_PID=$$!
	echo "PID: $$QEMU_PID"

	timeout 1m bash -c "while ! (echo > /dev/tcp/127.0.0.1/4321); do sleep 0.1; done"
	(tail -f vm.stdin | nc localhost 4321 | tee vm.stdout) &
	
	timeout 30m bash -c "while ! (echo > /dev/tcp/$(VM_IP)/$(VM_PORT)); do sleep 1; done"

	if ! (echo > /dev/tcp/$(VM_IP)/$(VM_PORT))
	then
	echo "SSH must be installed and enabled inside the container"
	fi
	
	echo "VM ready for tests at IP $(VM_IP):$(VM_PORT)"
	echo $$QEMU_PID > start_vm