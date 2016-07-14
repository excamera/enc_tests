#!/bin/bash
# produce plots of ssim vs bpp
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail

if [ -z "$GNUPLOT" ]; then
    export GNUPLOT=$(which gnuplot)
fi
if [ ! -x "$GNUPLOT" ]; then
    echo "Error: can't find gnuplot."
    exit 1
fi

if [ -z "$PROCOUT" ]; then
    export PROCOUT=$(readlink -f ../bin/ssim_vs_bpp.pl)
fi
if [ ! -x "$PROCOUT" ]; then
    echo "Error: can't find ssim_vs_bpp.pl."
    exit 1
fi

if [ -z "$CALCDIFF" ]; then
    export CALCDIFF=$(readlink -f ../bin/calc_bpp_diff.pl)
fi
if [ ! -x "$CALCDIFF" ]; then
    echo "Error: can't find calc_bpp_diff.pl."
    exit 1
fi

for FILE in "$@"; do
    BASENAME=$(basename "$FILE" -xc.out)
    VP8DATA=../vp8_data/"$BASENAME"-vp8.out
    XCDATA=../xc_data/"$BASENAME"-xc.out
    BASENAME2=$(tr -d "'" <<< ${BASENAME})
    if [ ! -f "$VP8DATA" ]; then
        echo "Could not find VP8 data $VP8DATA."
        exit 1
    fi
    TMPFILE=$(mktemp ssim_vs_bpp.XXXXXXXX)
    TMPFILE2=$(mktemp ssim_vs_bpp.XXXXXXXX)
    TMPFILE3=$(mktemp ssim_vs_bpp.XXXXXXXX)
    TMPFILE4=$(mktemp ssim_vs_bpp.XXXXXXXX.png)
    "$PROCOUT" "$VP8DATA" > "$TMPFILE"
    "$PROCOUT" "$XCDATA" > "$TMPFILE2"
    "$PROCOUT" "$FILE" > "$TMPFILE3"
    BPPDIFF=$("$CALCDIFF" "$TMPFILE" "$TMPFILE3")
    "$GNUPLOT" -e "ofile='${TMPFILE4}';otitle='${BASENAME2}, SSIM vs bpp';bppdiff='bits per pixel, %diff=${BPPDIFF}';rfile='${TMPFILE2}';ifile='${TMPFILE}';file='${TMPFILE3}';" ../plt/ssim_vs_bpp.plt
    mv "$TMPFILE4" "$BASENAME".png
    rm -f "$TMPFILE" "$TMPFILE2" "$TMPFILE3"
done
