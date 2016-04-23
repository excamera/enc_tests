
all: submodules gettests buildtools

submodules:
	@echo -n "Initializing submodules..."
	@git submodule init
	@git submodule update
	@echo "done."

gettests:
	@echo "Getting test vectors."
	@cd tests && ./00download_tests.sh
	@echo "Done."

buildtools:
	@echo "Building daala_tools."
	@make -C daala_tools
	@echo "Done."

clean:
	@echo "Cleaning up."
	@make -C daala_tools clean
	@echo "Done."
