VM_TESTS=$(filter-out README.md Makefile files,$(wildcard *))

# Get a list of tests for the feature
# $1 = test type
# $2 = feature
define run_tests
	tests="$(shell ls tests/$(1)/$(2)_*)"; \
	if [ -n "$$tests" ]; \
	then \
		chmod +x $$tests; \
		for test in $$tests; \
		do \
			$(foreach var,$(_VARS),$(var)=$($(var))) ./$${test}; \
			RC=$$?; \
			if [ $$RC != 0 ]; \
			then \
				exit $$RC; \
			fi; \
		done; \
	fi
endef

$(VM_TESTS): start_vm ansible_inventory
	$(eval _VARS = IMAGE_REPO IMAGE_NAME IMAGE_TAG)

	ansible -i ansible_inventory -m ansible.builtin.wait_for_connection vm

	# install tests
	$(call run_tests,vm,install)

	# flapak tests
	if [ -n "$(FLATPAK_REMOTE_REFS)" ]; \
	then \
		$(call run_tests,vm,flatpak); \
	fi

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
	$(install_pkg) qemu qemu-utils xorriso qemu-system-x86 netcat socat jq ansible

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
clean: files/mnt/iso
	sudo umount files/mnt/iso
	rmdir files/mnt/iso


files/install.iso: files/grub.cfg
	xorriso -dialog on << EOF
	-indev $(ISO_NAME)
	-outdev files/install.iso
	-boot_image any replay
	-map files/ks.cfg ks.cfg
	-chmod 0444 ks.cfg
	-map files/grub.cfg boot/grub2/grub.cfg
	-end
	EOF

files/disk.qcow2:
	qemu-img create -f qcow2 files/disk.qcow2 50G

.PHONY: install_os
install_os: files/install.iso files/disk.qcow2
	timeout 1h qemu-system-x86_64 -name "Anaconda" -boot d -m 4096 -cpu qemu64 -display none -cdrom files/install.iso -smp 2 -hda files/disk.qcow2 -serial telnet:localhost:4321,server=on,wait=off & QEMU_PID=$$!
	echo "PID: $$QEMU_PID"
	timeout 1m bash -c "while ! (echo > /dev/tcp/127.0.0.1/4321); do sleep 0.1; done"
	(nc localhost 4321 | tee vm.stdout) &
	wait $$QEMU_PID

.ONESHELL:

.PHONY: start_vm
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
	$(MAKE) ansible_inventory VM_IP=$(VM_IP) VM_PORT=$(VM_PORT) VM_USER=core VM_PASS=foobar