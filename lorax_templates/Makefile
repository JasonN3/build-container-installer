%.tmpl:
	sed 's/@IMAGE_NAME@/$(image_name)' $*.in > $*
	sed 's/@IMAGE_REPO@/$(image_repo)' $* > $*
	sed 's/@VERSION@/$(version)' $* $*

clean:
	rm *.tmpl