all: $(filter-out README.md Makefile,$(wildcard *))

$(filter-out README.md Makefile,$(wildcard *)):
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(MAKE) -w -C $(DIR)

$(filter-out README.md Makefile,$(wildcard */*)):
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(eval TARGET=$(subst $(DIR)/,,$@))
	$(MAKE) -w -C $(DIR) $(TARGET)

.DEFAULT:
	$(eval DIR=$(firstword $(subst /, ,$@)))
	$(if $(filter-out $(DIR),$@), $(eval TARGET=$(subst $(DIR)/,,$@)),$(eval TARGET=))
	$(MAKE) -w -C $(DIR) $(TARGET)

install-deps:
	$(foreach DIR,$(filter-out README.md Makefile,$(wildcard *)),$(MAKE) -w -C $(DIR) install-deps;)

clean:
	$(foreach DIR,$(filter-out README.md Makefile,$(wildcard *)),$(MAKE) -w -C $(DIR) clean;)

.PHONY: all $(filter-out README.md Makefile,$(wildcard *)) $(filter-out README.md Makefile,$(wildcard */*))