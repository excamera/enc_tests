#!/bin/bash
# run quality tests
# This code is based on rd_collect.sh and rd_collect_libvpx.sh from
# the Daala project, https://github.com/xiph/daala
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail

### frame number
if [ -z "$FRAMENUMBER" ]; then
    export FRAMENUMBER="Total"
fi

### min ssim, should be passed by Makefile
if [ -z "$QUALITY" ]; then
    echo "Please specify QUALITY, either vpx quantizer or xc min_ssim."
    exit 1
fi

### make sure TESTS_ROOT and XC_ROOT are initialized
if [ -z "$TESTS_ROOT" ]; then
    echo "Please specify TESTS_ROOT, path to your checkout of the enc_tests repo."
    exit 1
else
    # also, canonicalize it
    # (the following line is pretty meaningless unless you have GNU readlink, I think)
    export TESTS_ROOT=$(readlink -f "$TESTS_ROOT")
fi

if [ -z "$XC_ROOT" ]; then
    echo "Please specify XC_ROOT, path to checkout of alfalfa@dumbtrip."
    exit 1
else
    # canonicalize
    export XC_ROOT=$(readlink -f "$XC_ROOT")
fi

### vpxenc / vpxdec
if [ -z "$VPXENC" ]; then export VPXENC=$(which vpxenc); fi
if [ -z "$VPXDEC" ]; then export VPXDEC=$(which vpxdec); fi

if [ ! -x "$VPXENC" ] || [ ! -x "$VPXDEC" ]; then
    echo "Couldn't find vpxenc or vpxdec."
    echo "Do you have the vpx-tools package installed?"
    exit 1
fi

### dumbencode
export XCENC="$XC_ROOT"/src/frontend/xc-enc
export XCSIZE="$XC_ROOT"/src/frontend/xc-framesize
if [ ! -x "$XCENC" ] || [ ! -x "$XCSIZE" ]; then
    echo "Couldn't find xc-enc or xc-framesize"
    echo "Perhaps you need to build alfalfa."
    exit 1
fi

### plane
if [ -z "$PLANE" ]; then
  export PLANE=0
fi

if [ $PLANE != 0 ] && [ $PLANE != 1 ] && \
   [ $PLANE != 2 ] && [ $PLANE != -1 ]; then
    echo "Invalid plane $PLANE. Must be 0, 1, 2, or -1 (all planes)."
    exit 1
fi

### dump executables
export DUMP_PSNR=$TESTS_ROOT/daala_tools/dump_psnr
export DUMP_PSNRHVS=$TESTS_ROOT/daala_tools/dump_psnrhvs
export DUMP_SSIM=$TESTS_ROOT/daala_tools/dump_ssim
export DUMP_FASTSSIM=$TESTS_ROOT/daala_tools/dump_fastssim

if [ ! -x "$DUMP_PSNR" ] || [ ! -x "$DUMP_PSNRHVS" ] || \
   [ ! -x "$DUMP_SSIM" ] || [ ! -x "$DUMP_FASTSSIM" ]; then
    echo "Couldn't find one or more of the daala tools."
    echo "Perhaps you need to \`make -C $TESTS_ROOT/daala_tools\`."
    exit 1
fi

### are we being asked to run vp8?
if [ "$1" = "-R" ]; then
    # regen mode on
    export REGEN=1
    shift
fi

QSTR="--min-q=\$QUALITY --max-q=\$QUALITY"
run_one_test () {

    #
    # NOTE: since we only care about SSIM for now, we can skip running these and just put out dummy numbers
    #
    #PSNR=$($DUMP_PSNR $FILE $BASENAME.y4m 2> /dev/null | grep "$FRAMENUMBER" | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
    #PSNRHVS=$($DUMP_PSNRHVS $FILE $BASENAME.y4m 2> /dev/null | grep "$FRAMENUMBER" | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
    #FASTSSIM=$($DUMP_FASTSSIM -c $FILE $BASENAME.y4m 2> /dev/null | grep "$FRAMENUMBER" | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
    #

    x=$1
    BASENOFRAME=$2
    BASENAME="$BASENOFRAME"-"$FRAMENUMBER"

    "$VPXDEC" --codec=vp8 -o "$BASENAME"-$x.y4m "$BASENAME"-$x.ivf

    # output files on two lines below contain size and ssim values for all frames
    # used in the for loop below to create .out for all frame numbers
    "$XCSIZE" "$BASENAME"-$x.ivf > "$BASENOFRAME"-$x-size.out
    "$DUMP_SSIM" "$FILE" "$BASENAME"-$x.y4m > "$BASENOFRAME"-"$x"-ssim.out 2> /dev/null

    FRAMES=$(cat "$BASENOFRAME"-"$x"-ssim.out | grep ^0 | wc -l)
    PIXELS=$(($WIDTH*$HEIGHT))
    if [ "$FRAMENUMBER" == "Total" ]; then
        PIXELS=$(($WIDTH*$HEIGHT*$FRAMES))
    fi
    SIZE=$(cat "$BASENOFRAME"-$x-size.out | grep "$FRAMENUMBER" | tr -s ' ' | cut -d\  -f 2)
    PSNR=0
    PSNRHVS=0
    SSIM=$(cat "$BASENOFRAME"-"$x"-ssim.out | grep "$FRAMENUMBER" | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
    FASTSSIM=0
    echo $x $PIXELS $SIZE $PSNR $PSNRHVS $SSIM $FASTSSIM > "$BASENAME"-"$x".out

    # If framenumber isn't total, generate .out files for all framenumbers below the current one
    # If the user doesn't specify a FRAMENUMBER, then inter6/inter2 generates .out for all frames
    # Otherwise, higher frame number's .out files aren't generated.
    if [ "$FRAMENUMBER" != "Total" ]; then
        for i in $(seq -f "%08g" 0 $((10#$FRAMENUMBER-1))); do
            SIZE=$(cat "$BASENOFRAME"-$x-size.out | grep "$i" | tr -s ' ' | cut -d\  -f 2)
            SSIM=$(cat "$BASENOFRAME"-"$x"-ssim.out | grep "$i" | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
            echo $x $PIXELS $SIZE $PSNR $PSNRHVS $SSIM $FASTSSIM > "$BASENOFRAME"-"$i"-"$x".out
        done
    fi
    rm -f "$BASENAME"-$x.ivf "$BASENAME"-$x.y4m "$BASENAME"-$x-enc.out "$BASENOFRAME"-$x-ssim.out "$BASENOFRAME"-$x-size.out
}

### Now, run the tests
for FILE in "$@"; do
    WIDTH=$(head -1 "$FILE" | cut -d\  -f 2 | tr -d 'W')
    HEIGHT=$(head -1 "$FILE" | cut -d\  -f 3 | tr -d 'H')

    if [ "$REGEN" = "1" ]; then
        BASENAME=$(basename "$FILE")-vp8-"$FRAMENUMBER"
        BASENOFRAME=$(basename "$FILE")-vp8

        echo $BASENAME\($QUALITY\)
        $VPXENC -y --codec=vp8 --good --cpu-used=0 --ivf $(echo $QSTR | sed 's/\$QUALITY/'$QUALITY'/g') -o $BASENAME-$QUALITY.ivf "$FILE" 2> $BASENAME-$QUALITY-enc.out
        run_one_test "$QUALITY" "$BASENOFRAME"
    else
        BASENAME=$(basename "$FILE")-xc-"$FRAMENUMBER"
        BASENOFRAME=$(basename "$FILE")-xc

        echo $BASENAME\($QUALITY\)
        "$XCENC" --two-pass -i y4m -o "$BASENAME"-$QUALITY.ivf --y-ac-qi $QUALITY "$FILE" 2> $BASENAME-$QUALITY-enc.out
        run_one_test "$QUALITY" "$BASENOFRAME"
    fi
done
