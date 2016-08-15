#!/bin/bash
# given filename, runs make commands to generate pngs for all framenumbers, then creates gif out of them.
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail	

FILE="$1"
if [ -z "$FILE" ]; then
    echo "Error: require filename.  Should be run from enc_tests root.  Usage: bin/graph_all_frames.sh [filename]"
    exit 1
fi
FRAMENUMBER=$((10#$(find vp8_data -name "$FILE*" | rev | cut -d - -f 1 | rev | cut -d . -f 1 | sort -n | tail -n1)))
if [ "$FRAMENUMBER" = "Total" ]; then
	TYPE="still"
else
	TYPE=inter$(($FRAMENUMBER+1))
fi
echo TESTTYPE:"$TESTTYPE"
for i in $(seq 0 $(($FRAMENUMBER-1))); do
	make TESTTYPE="$TYPE" FRAMENUMBER="$i"
done

convert -delay 100 -size 640x480 -loop 0 $(for i in run/"$FILE"*.png; do echo "-page +0+0 $i"; done | tr '\n' ' ') "$FILE".gif
mv "$FILE".gif run