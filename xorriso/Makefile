input.txt:
	sed -i 's/@IMAGE_NAME@/$(image_name)-$(version)/' gen_input.sh
	cd $(base_dir)
	bash gen_input.sh > input.txt