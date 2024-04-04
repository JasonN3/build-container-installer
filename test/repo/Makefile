REPO_TESTS=$(filter-out README.md Makefile,$(wildcard *))

all: $(REPO_TESTS)

$(REPO_TESTS):
	chmod +x $@
	./$@

install-deps:

.PHONY: $(REPO_TESTS)