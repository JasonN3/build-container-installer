docs:
	find -name '*.md' | while read -r line; \
	do \
	  mv "$${line:2}" "$$($${line:2} | tr '/' '_')"; \
	done