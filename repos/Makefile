repos: $(_REPO_FILES)

# Step 2: Replace vars in repo files
%.repo: /etc/yum.repos.d/%.repo
	cp /etc/yum.repos.d/$*.repo           $*.repo
	sed -i "s/\$$releasever/$(VERSION)/g" $*.repo
	sed -i "s/\$$basearch/$(ARCH)/g"      $*.repo

install-deps:

FILES=$(wildcard *.repo)
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif