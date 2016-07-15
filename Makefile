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

# DISPATCH:
#   decide what to do based on TESTTYPE variable
#
#   the user MUST supply this value unless the clean goal is chosen
#
ifeq ($(strip $(MAKECMDGOALS)),clean)
# do nothing
TESTDIRS :=
FRAMENUMBER :=
else ifeq ($(strip $(TESTTYPE)),still)
TESTDIRS := . subset1-y4m
FRAMENUMBER := Total
else ifeq ($(strip $(TESTTYPE)),inter2)
TESTDIRS := xc_encoder_test_vectors_video/2frames
FRAMENUMBER := 1
else
$(error "You must run make TESTTYPE=<type>. Valid <type>s are: still, inter2")
endif

# Frame number should be "Total" or an 8-digit number
# NOTE: frames are numbered from 0!
# This override sets FRAMENUMBER to a zero-padded 8-digit number or "Total".
override FRAMENUMBER != export FRM=$(if $(FRAMENUMBER),$(FRAMENUMBER),Total);\
                        printf "%8.8d" $$FRM >/dev/null 2>/dev/null;\
                        if [ "$$?" = "0" ]; then\
                            printf "%8.8d" $$FRM;\
                        else\
                            echo Total;\
                        fi

TESTVECS := $(notdir $(wildcard $(addprefix test_vectors/,$(addsuffix /*.y4m,$(TESTDIRS)))))
VP8TARGS := $(addprefix vp8_data/,$(addsuffix -vp8-$(FRAMENUMBER).out,$(TESTVECS)))
XCTARGS := $(addprefix run/,$(addsuffix -xc-$(FRAMENUMBER).out,$(TESTVECS)))
PLTTARGS := $(addprefix run/,$(addsuffix -$(FRAMENUMBER).png,$(TESTVECS)))
BPPTARGS := $(addprefix run/,$(addsuffix -$(FRAMENUMBER).bppdiff,$(TESTVECS)))

.PHONY: all submodules getvecs build_tools runvp8 runxc plotxc updatexc clean
all: plotxc

# each test vector can be in test_vectors/ or in test_vectors/subset1-y4m or maybe other directories,
# so we define separate rules that match depending on where the input file lives.
# Using $(eval $(call )) this way is convenient because we can add more subdirs just by changing
# the $(TESTDIRS) variable definition, above
define VP8RULE
vp8_data/%-vp8-$(FRAMENUMBER).out: test_vectors/$(1)/% | getvecs build_tools run2 vp8_data
	$(QPFX)echo "Generating vp8 test data for $$<"
	$(QPFX)cd run2 && FRAMENUMBER="$(FRAMENUMBER)" XC_ROOT="$$(XC_ROOT)" TESTS_ROOT=.. ../bin/run_tests.sh -R ../"$$<"
	$(QPFX)mv run2/"$$(notdir $$@)" vp8_data
endef
# the following line actually defines the vp8_data/%-vp8.out targets based on VP8RULE and $(TESTDIRS)
$(foreach tdir,$(TESTDIRS),$(eval $(call VP8RULE,$(tdir))))

# as above, we make separate rules for each subdir in test_vectors where a vector might live
define XCRULE
run/%-xc-$(FRAMENUMBER).out: test_vectors/$(1)/% $$(XC_ROOT)/src/frontend/xc-enc | getvecs build_tools run
	$(QPFX)echo "Generating xc test data for $$<"
	$(QPFX)cd run && FRAMENUMBER="$(FRAMENUMBER)" XC_ROOT="$$(XC_ROOT)" TESTS_ROOT=.. ../bin/run_tests.sh ../"$$<"
endef
$(foreach tdir,$(TESTDIRS),$(eval $(call XCRULE,$(tdir))))

# to make the png, we need the xc out and the vp8 out
run/%-$(FRAMENUMBER).png: run/%-xc-$(FRAMENUMBER).out vp8_data/%-vp8-$(FRAMENUMBER).out
	$(QPFX)echo "Generating $@"
	$(QPFX)cd run && FRAMENUMBER="$(FRAMENUMBER)" ../bin/ssim_vs_bpp.sh "$(notdir $<)"

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

plotxc: run/bppdiff-$(FRAMENUMBER).txt run/runxc_out-$(FRAMENUMBER).gif
	$(QPFX)echo "Average %BPP difference: $$(cat "$<")"

run/runxc_out-$(FRAMENUMBER).gif: $(PLTTARGS)
	$(QPFX)echo "Converting plots to animated GIF."
	$(QPFX)convert -delay 100 -size 640x480 -loop 0 $$(for i in run/*-$(FRAMENUMBER).png; do echo "-page +0+0 $$i"; done | tr '\n' ' ') run/runxc_out-$(FRAMENUMBER).gif
	$(QPFX)echo "Done."

run/%-$(FRAMENUMBER).bppdiff: run/%-$(FRAMENUMBER).png ;

run/bppdiff-$(FRAMENUMBER).txt: $(BPPTARGS)
	$(QPFX)cd run && ../bin/calc_avg.sh $(addprefix ",$(addsuffix ",$(notdir $^))) > $(notdir $@)

updatexc: runxc | xc_data
	$(QPFX)echo "Updating xc_data files."
	$(QPFX)cp run/*xc-$(FRAMENUMBER).out xc_data
	$(QPFX)git -C "$(XC_ROOT)" log -1 --pretty=format:%H > xc_data/commit_id
	$(QPFX)echo "Done."

clean:
	$(QPFX)echo "Cleaning up."
	$(QPFX)make -C daala_tools clean
	$(QPFX)rm -rf run run2
	$(QPFX)echo "Done."
