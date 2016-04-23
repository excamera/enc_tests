#!/bin/bash
# run quality tests
# This code is based on rd_collect.sh and rd_collect_libvpx.sh from
# the Daala project, https://github.com/xiph/daala
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail

### make sure TESTS_ROOT is initialized
if [ -z "$TESTS_ROOT" ]; then
    echo "Please specify TESTS_ROOT, path to your checkout of the enc_tests repo."
    exit 1
else
    # also, canonicalize it
    # (the following line is pretty meaningless unless you have GNU readlink, I think)
    export TESTS_ROOT=$(readlink -f $TESTS_ROOT)
fi

### vpxenc / vpxdec
if [ -z "$VPXENC" ]; then export VPXENC=$(which vpxenc); fi
if [ -z "$VPXDEC" ]; then export VPXDEC=$(which vpxdec); fi

if [ ! -x "$VPXENC" ]; then
    echo "Executable not found VPXENC=$VPXENC"
    echo "Do you have the vpx-tools package installed?"
    exit 1
fi

if [ ! -x "$VPXDEC" ]; then
    echo "Executable not found VPXDEC=$VPXDEC"
    echo "Do you have the vpx-tools package installed?"
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
    echo "Perhaps you need to \`make -C $TESTS_ROOT/daala_tools\`?"
    exit 1
fi

### Now, run the tests
RANGE=$(seq 1 63)
QSTR="--min-q=\$x --max-q=\$x"
CODEC=vp8
for FILE in "$@"; do
    BASENAME=$(basename $FILE)-$CODEC
    rm $BASENAME.out 2> /dev/null || true
    echo -n $BASENAME

    WIDTH=$(head -1 $FILE | cut -d\  -f 2 | tr -d 'W')
    HEIGHT=$(head -1 $FILE | cut -d\  -f 3 | tr -d 'H')

    for x in $RANGE; do
        echo -n " "$x
        $VPXENC --codec=$CODEC --good --cpu-used=0 --ivf $(echo $QSTR | sed 's/\$x/'$x'/g') -o $BASENAME.ivf $FILE 2> $BASENAME-$x-enc.out
        $VPXDEC --codec=$CODEC -o $BASENAME.y4m $BASENAME.ivf
        SIZE=$(wc -c $BASENAME.ivf | awk '{ print $1 }')
        $DUMP_PSNR $FILE $BASENAME.y4m > $BASENAME-$x-psnr.out 2> /dev/null
        FRAMES=$(cat $BASENAME-$x-psnr.out | grep ^0 | wc -l)
        PIXELS=$(($WIDTH*$HEIGHT*$FRAMES))
        PSNR=$(cat $BASENAME-$x-psnr.out | grep Total | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
        PSNRHVS=$($DUMP_PSNRHVS $FILE $BASENAME.y4m 2> /dev/null | grep Total | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
        SSIM=$($DUMP_SSIM $FILE $BASENAME.y4m 2> /dev/null | grep Total | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
        FASTSSIM=$($DUMP_FASTSSIM -c $FILE $BASENAME.y4m 2> /dev/null | grep Total | tr -s ' ' | cut -d\  -f $((4+$PLANE*2)))
        rm $BASENAME.ivf $BASENAME.y4m $BASENAME-$x-enc.out $BASENAME-$x-psnr.out
        echo $x $PIXELS $SIZE $PSNR $PSNRHVS $SSIM $FASTSSIM >> $BASENAME.out
        #tail -1 $BASENAME.out
    done
    echo
done
