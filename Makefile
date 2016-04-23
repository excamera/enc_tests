
all: submodules getvecs buildtools

submodules:
	@echo -n "Initializing submodules..."
	@git submodule init
	@git submodule update
	@echo "done."

getvecs:
	@echo "Getting test vectors."
	@cd test_vectors && ./00download_tests.sh
	@echo "Done."

buildtools:
	@echo "Building daala_tools."
	@make -C daala_tools
	@echo "Done."

clean:
	@echo "Cleaning up."
	@make -C daala_tools clean
	@echo "Done."
