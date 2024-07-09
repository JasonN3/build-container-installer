SHELL = /bin/bash

docs:
	find -name '*.md' | while read -r line; \
	do \
	  mv "$${line:2}" "$$(echo $${line:2} | tr '/' '_')"; \
	done