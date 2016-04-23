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

all: submodules getvecs buildtools runtests

submodules:
	$(QPFX)echo -n "Initializing submodules..."
	$(QPFX)git submodule init
	$(QPFX)git submodule update
	$(QPFX)echo "done."

getvecs:
	$(QPFX)echo "Getting test vectors."
	$(QPFX)cd test_vectors && ./00download_tests.sh
	$(QPFX)echo "Done."

buildtools:
	$(QPFX)echo "Building daala_tools."
	$(QPFX)make -C daala_tools
	$(QPFX)echo "Done."

runtests:
	$(QPFX)echo "Running tests."
	$(QPFX)mkdir -p run
	$(QPFX)cd run && TESTS_ROOT=.. ../bin/run_tests.sh ../test_vectors/*.y4m
	$(QPFX)for i in run/*.out; do bin/ssim_vs_bpp.pl $$i | gnuplot -e "ofile='"$$i".png';otitle='"$$i", SSIM vs bpp';" plt/bpp_vs_ssim.plt; done
	$(QPFX)echo "Done."

clean:
	$(QPFX)echo "Cleaning up."
	$(QPFX)make -C daala_tools clean
	$(QPFX)rm -rf run
	$(QPFX)echo "Done."
