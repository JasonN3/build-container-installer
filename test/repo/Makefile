REPO_TESTS=$(filter-out README.md Makefile,$(shell ls))

all: $(REPO_TESTS)

$(REPO_TESTS):
	chmod +x $*
	./$*

.PHONY: $(REPO_TESTS)