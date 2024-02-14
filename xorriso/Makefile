input.txt: gen_input.sh
	bash gen_input.sh "$(base_dir)" > input.txt

%.sh:
	sed 's/@IMAGE_NAME@/$(image_name)-$(version)/' $*.in > $*

clean:
  rm input.txt
  rm gen_input.sh