# Makefile for enc_tests, an encoder testing package for alfalfa
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)
#          See README.md for licensing information.

# configuration flags
#
# override defaults on commandline
QUIET ?= 1

# turn options into useful crap
ifeq ($(QUIET),1)
QPFX := @
else
QPFX :=
endif

TESTVECS := ../test_vectors/*.y4m ../test_vectors/subset1-y4m/*.y4m

all: runxc

.PHONY: submodules getvecs build_tools clean
submodules:
	$(QPFX)echo -n "Initializing submodules..."
	$(QPFX)git submodule update --init
	$(QPFX)echo "done."

getvecs:
	$(QPFX)echo "Getting test vectors."
	$(QPFX)cd test_vectors && ./00download_tests.sh
	$(QPFX)echo "Done."

build_tools:
	$(QPFX)echo "Building daala_tools."
	$(QPFX)make -C daala_tools
	$(QPFX)echo "Done."

runvp8: submodules getvecs build_tools
	$(QPFX)echo "Regenerating vp8 test data."
	$(QPFX)mkdir -p run vp8_data
	$(QPFX)cd run && XC_ROOT=../../alfalfa TESTS_ROOT=.. ../bin/run_tests.sh -R $(TESTVECS)
	$(QPFX)mv run/*vp8.out vp8_data
	$(QPFX)echo "Done".

runxc: submodules getvecs build_tools
	$(QPFX)echo "Running xc tests."
	$(QPFX)mkdir -p run
	$(QPFX)cd run && XC_ROOT=../../alfalfa TESTS_ROOT=.. ../bin/run_tests.sh $(TESTVECS)
	$(QPFX)cd run && ../bin/ssim_vs_bpp.sh *xc.out
	$(QPFX)echo "Done."

clean:
	$(QPFX)echo "Cleaning up."
	$(QPFX)make -C daala_tools clean
	$(QPFX)rm -rf run
	$(QPFX)echo "Done."
