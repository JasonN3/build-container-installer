SHELL = /bin/bash

docs:
	find -name '*.md' | while read -r line; \
	do \
	  source_file=$${line:2}; \
	  final_file=$${source_file//\//_}; \
	  mv "$${source_file}" "$${final_file}"; \
	  no_ext_source=$${source_file:0:-3}; \
	  no_ext_final=$${final_file:0:-3}; \
	  sed -i "s;($${no_ext_source});($${no_ext_final});g" *.md; \
	done