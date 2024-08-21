SHELL = /bin/bash

docs:
	find -name '*.md' -print0 | xargs -0 -I {} bash -c ' \
	  source_file=$${1:2}; \
	  final_file=$${source_file//\//_}; \
	  mv "$${source_file}" "$${final_file}"; \
	  no_ext_source=$${source_file:0:-3}; \
	  no_ext_final=$${final_file:0:-3}; \
	  sed -i "s;(\(../\)*$${source_file});($${no_ext_final});g" $$(find -name '*.md'); \
	' _ {}
	find . -type d -empty -delete
