#!/bin/bash
# given filename, runs make commands to generate pngs for all framenumbers, then
# creates composite image out of them.
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail	
FILE=$(echo "$1" | rev | cut -d / -f 1 | rev)
if [ -z "$FILE" ]; then
    echo "Usage: bin/graph_all_frames.sh [file.y4m]"
    exit 1
fi
FRAMENUMBER=$((10#$(find vp8_data -name "$FILE*" | rev | cut -d - -f 1 | rev | cut -d . -f 1 | sort -n | tail -n1)))
if [ "$FRAMENUMBER" = "Total" ]; then
  TESTTYPE="still"
else
  TESTTYPE="inter$(($FRAMENUMBER+1))"
fi

# runs make command so png for all frame numbers exist
for i in $(seq 0 $(($FRAMENUMBER-1))); do
  make TESTTYPE="$TESTTYPE" FRAMENUMBER="$i" plotxc -j4
done

if [ "$TESTTYPE" = inter2 ]; then
  convert run/"$FILE"-00000000.png run/"$FILE"-00000001.png +append -resize 75% out.png
elif [ "$TESTTYPE" = inter3 ]; then
  convert run/"$FILE"-00000000.png run/"$FILE"-00000001.png +append out.png
  convert out.png run/"$FILE"-00000002.png -append -resize 75% out.png
elif [ "$TESTTYPE" = inter6 ]; then
  convert run/"$FILE"-00000000.png run/"$FILE"-00000001.png run/"$FILE"-00000002.png +append -resize 50% out.png
  convert run/"$FILE"-00000003.png run/"$FILE"-00000004.png run/"$FILE"-00000005.png +append -resize 50% out2.png
  convert out.png out2.png -append out.png
  rm -f out2.png
fi
display out.png

