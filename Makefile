# Makefile for enc_tests, an encoder testing package for alfalfa
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)
#          See README.md for licensing information.

# configuration flags
#
# override defaults on commandline
QUIET ?= 1
XC_ROOT ?= $(shell readlink -f ../alfalfa)

# turn options into useful crap
ifeq ($(QUIET),1)
QPFX := @
else
QPFX :=
endif

TESTVECS := $(notdir $(wildcard test_vectors/*.y4m test_vectors/subset1-y4m/*.y4m))
VP8TARGS := $(addprefix vp8_data/,$(addsuffix -vp8.out,$(TESTVECS)))
XCTARGS := $(addprefix run/,$(addsuffix -xc.out,$(TESTVECS)))
PLTTARGS := $(addprefix run/,$(addsuffix .png,$(TESTVECS)))
BPPTARGS := $(addprefix run/,$(addsuffix .bppdiff,$(TESTVECS)))
TESTDIRS := . subset1-y4m

.PHONY: all submodules getvecs build_tools runvp8 runxc plotxc updatexc clean
all: plotxc

# each test vector can be in test_vectors/ or in test_vectors/subset1-y4m or maybe other directories,
# so we define separate rules that match depending on where the input file lives.
# Using $(eval $(call )) this way is convenient because we can add more subdirs just by changing
# the $(TESTDIRS) variable definition, above
define VP8RULE
vp8_data/%-vp8.out: test_vectors/$(1)/% | getvecs build_tools run2 vp8_data
	$(QPFX)echo "Generating vp8 test data for $$<"
	$(QPFX)cd run2 && XC_ROOT="$$(XC_ROOT)" TESTS_ROOT=.. ../bin/run_tests.sh -R ../"$$<"
	$(QPFX)mv run2/"$$(notdir $$@)" vp8_data
endef
# the following line actually defines the vp8_data/%-vp8.out targets based on VP8RULE and $(TESTDIRS)
$(foreach tdir,$(TESTDIRS),$(eval $(call VP8RULE,$(tdir))))

# as above, we make separate rules for each subdir in test_vectors where a vector might live
define XCRULE
run/%-xc.out: test_vectors/$(1)/% | getvecs build_tools run
	$(QPFX)echo "Generating xc test data for $$<"
	$(QPFX)cd run && XC_ROOT="$$(XC_ROOT)" TESTS_ROOT=.. ../bin/run_tests.sh ../"$$<"
endef
$(foreach tdir,$(TESTDIRS),$(eval $(call XCRULE,$(tdir))))

# to make the png, we need the xc out and the vp8 out
run/%.png: run/%-xc.out vp8_data/%-vp8.out
	$(QPFX)echo "Generating $@"
	$(QPFX)cd run && ../bin/ssim_vs_bpp.sh "$(notdir $<)"
 
run:
	$(QPFX)mkdir -p run

run2:
	$(QPFX)mkdir -p run2

vp8_data:
	$(QPFX)mkdir -p vp8_data

xc_data:
	$(QPFX)mkdir -p xc_data

submodules:
	$(QPFX)echo -n "Initializing submodules..."
	$(QPFX)git submodule update --init
	$(QPFX)echo "done."

getvecs:
	$(QPFX)echo "Getting test vectors."
	$(QPFX)cd test_vectors && ./00download_tests.sh
	$(QPFX)echo "Done."

build_tools: submodules
	$(QPFX)echo "Building daala_tools."
	$(QPFX)+make -C daala_tools
	$(QPFX)echo "Done."

runvp8: $(VP8TARGS)

runxc: $(XCTARGS)

plotxc: run/runxc_out.gif run/bppdiff.txt
	$(QPFX)echo "Average %BPP difference: $$(cat run/bppdiff.txt)"

run/runxc_out.gif: $(PLTTARGS)
	$(QPFX)echo "Converting plots to animated GIF."
	$(QPFX)convert -delay 100 -size 640x480 -loop 0 $$(for i in run/*.png; do echo "-page +0+0 $$i"; done | tr '\n' ' ') run/runxc_out.gif
	$(QPFX)echo "Done."

run/bppdiff.txt: $(BPPTARGS)
	$(QPFX)cd run && ../bin/calc_avg.sh $(addprefix ",$(addsuffix ",$(notdir $^)))

run/%.bppdiff: run/%.png

updatexc: runxc | xc_data
	$(QPFX)echo "Updating xc_data files."
	$(QPFX)cp run/*xc.out xc_data
	$(QPFX)git -C "$(XC_ROOT)" log -1 --pretty=format:%H > xc_data/commit_id
	$(QPFX)echo "Done."

clean:
	$(QPFX)echo "Cleaning up."
	$(QPFX)make -C daala_tools clean
	$(QPFX)rm -rf run run2
	$(QPFX)echo "Done."
