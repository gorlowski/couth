AWESOME_CFG_DIR := $(HOME)/.config/awesome
COUTH_INST_DIR := $(AWESOME_CFG_DIR)/couth

help:
	@echo '----------------------------------------------------'
	@echo "To install, run: "
	@echo "                 make install"
	@echo '----------------------------------------------------'

#
#	TODO: make the tests real unit tests
#
test:
	lua test/test.lua

install:
	@if [ ! -d "$(AWESOME_CFG_DIR)" ]; then \
	    echo "ERROR: $(AWESOME_CFG_DIR) NOT FOUND! Aborting."; exit 1; \
	fi
	$(RM) -f "$(COUTH_INST_DIR)"
	ln -s "$(PWD)/lib" "$(COUTH_INST_DIR)"
	@echo '----------------------------------------------------'
	@echo "Couth symlink created: $(COUTH_INST_DIR)"
	@echo '----------------------------------------------------'
	@echo
	@echo "	   You should now edit your $(AWESOME_CFG_DIR)/rc.lua to require the couth"
	@echo "	   modules that you want to use, and bind them to key bindings."
	@echo
	@echo "	   -- you MUST require this to use ANY couth modules: "
	@echo "	   require('couth.couth') "
	@echo
	@echo "	   -- These are optional. Only require the ones that you want to use. "
	@echo "	   require('couth.alsa') "
	@echo "	   require('couth.mpc') "
	@echo	
	@echo "	   Read the README.rst for more details."
	@echo

.PHONY: install help test
