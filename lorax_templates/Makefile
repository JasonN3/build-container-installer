# Converts a post script to a template
# $1 = script to convert
# $2 = file on ISO to write
# $3 = whether to copy the '<%' lines to the template
define convert_post_to_tmpl
	header=0; \
	skip=0; \
	while read -r line; \
	do \
		if [[ $$line =~ ^\<\% ]]; \
		then \
			if [[ '$(3)' == 'true' ]]; \
			then \
				echo $$line >> post_$(1).tmpl; \
			fi; \
			echo >> post_$(1).tmpl; \
		else \
			if [[ $$header == 0 ]]; \
			then \
				if [[ $$line =~ ^\#\#\ (.*)$$ ]]; \
				then \
					echo "append $(2) \"%post --erroronfail $${BASH_REMATCH[1]}\"" >> post_$(1).tmpl; \
					skip=1; \
				else \
					echo "append $(2) \"%post --erroronfail\"" >> post_$(1).tmpl; \
				fi; \
				header=1; \
			fi; \
			if [[ $$skip == 0 ]]; \
			then \
				echo "append $(2) \"$${line//\"/\\\"}\"" >> post_$(1).tmpl; \
			fi; \
			skip=0; \
		fi; \
	done < scripts/post/$(1); \
	echo "append $(2) \"%end\"" >> post_$(1).tmpl
endef

post_%.tmpl: scripts/post/%
	$(call convert_post_to_tmpl,$*,usr/share/anaconda/post-scripts/$*.ks,true)

install_include_post.tmpl:
        echo '<%page />' > install_include_post.tmpl
        for file in $(patsubst post_%.tmpl, %, $(filter post_%, $(notdir $(_LORAX_TEMPLATES)))); do echo "append usr/share/anaconda/interactive-defaults.ks \"%include /usr/share/anaconda/post-scripts/$${file}.ks\"" >> install_include_post.tmpl; done

install-deps:

FILES=$(wildcard post_*)
clean:
ifneq ($(FILES),)
	rm -Rf $(FILES)
endif