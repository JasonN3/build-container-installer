VM_TESTS=$(filter-out README.md,$(shell ls))

# Get a list of tests for the feature
# $1 = test type
# $2 = feature
run_tests = \
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

$(VM_TESTS):
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
	echo "      ansible_host: ${VM_IP}" >> ansible_inventory
	echo "      ansible_port: ${VM_PORT}" >> ansible_inventory
	echo "      ansible_user: ${VM_USER}" >> ansible_inventory
	echo "      ansible_password: ${VM_PASS}" >> ansible_inventory
	echo "      ansible_become_pass: ${VM_PASS}" >> ansible_inventory
	echo "      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'" >> ansible_inventory

.PHONY: $(VM_TESTS)