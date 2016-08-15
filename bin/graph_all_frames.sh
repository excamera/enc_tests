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
echo "$FILE"
FRAMENUMBER=$((10#$(find vp8_data -name "$FILE*" | rev | cut -d - -f 1 | rev | cut -d . -f 1 | sort -n | tail -n1)))
echo $FRAMENUMBER
for i in $(seq 0 $FRAMENUMBER-1); do
	make TESTTYPE="$FRAMENUMBER" FRAMENUMBER="$i"
done

convert -delay 100 -size 640x480 -loop 0 $(for i in run/"$FILE"*.png; do echo "-page +0+0 $i"; done | tr '\n' ' ') "$FILE".gif
mv "$FILE".gif run


# echo FRAMENUMBER:"$FRAMENUMBER"
# ORIGBASE=run/"$FILE".y4m-xc-"$FRAMENUMBER"
# echo ORIGBASE:"$ORIGBASE"
# RUN2ORIGBASE=run2/"$FILE".y4m-vp8-"$FRAMENUMBER"
# echo RUN2ORIGBASE:"$RUN2ORIGBASE"
# ORIGPNG=run/"$FILE".y4m-"$FRAMENUMBER".png
# echo ORIGPNG:$ORIGPNG

# for i in $(seq -f "%08g" 0 $((10#$FRAMENUMBER-1)))
# do
	# #xc
	# BASENAME=run/"$FILE".y4m-xc-$i
	# echo BASENAME:"$BASENAME"
	# RANGE=$(seq 0.69 0.05 0.99)
	# for x in $RANGE; do
	# 	TEMPBASE=run/"$FILE".y4m-xc-$x
	# 	SIZE=$(cat "$TEMPBASE"-size.out | grep "$i" | tr -s ' ' | cut -d\  -f 2)
	# 	SSIM=$(cat "$TEMPBASE"-ssim.out | grep "$i" | tr -s ' ' | cut -d\  -f 4)
	# 	echo $SIZE >> "$BASENAME".size
	# 	echo $SSIM >> "$BASENAME".ssim
	# done
	# paste "$ORIGBASE".out "$BASENAME".size "$BASENAME".ssim | awk '{$3=$8;$6=$9;$9="";$8=""}1' > "$BASENAME".out
	# rm "$BASENAME".ssim
	# rm "$BASENAME".size

	# #vp8
	# RUN2BASENAME=run2/"$FILE".y4m-vp8-$i
	# echo RUN2BASENAME:"$RUN2BASENAME"
	# RANGE=$(seq 1 63)
	# for x in $RANGE; do
	# 	VP8TEMPBASE=run2/"$FILE".y4m-vp8-$x
	# 	SIZE=$(cat "$VP8TEMPBASE"-size.out | grep "$i" | tr -s ' ' | cut -d\  -f 2)
	# 	SSIM=$(cat "$VP8TEMPBASE"-ssim.out | grep "$i" | tr -s ' ' | cut -d\  -f 4)
	# 	echo $SIZE >> "$RUN2BASENAME".size
	# 	echo $SSIM >> "$RUN2BASENAME".ssim
	# done
	# paste "$RUN2ORIGBASE".out "$RUN2BASENAME".size "$RUN2BASENAME".ssim | awk '{$3=$8;$6=$9;$9="";$8=""}1' > "$RUN2BASENAME".out
	# rm "$RUN2BASENAME".ssim
	# rm "$RUN2BASENAME".size
	# cp "$RUN2BASENAME".out vp8_data

	# VP8BASENAME=vp8_data/"$FILE".y4m-vp8-$i
	# VP8ORIGBASE=vp8_data/"$FILE".y4m-vp8-"$FRAMENUMBER"

	# # cp "$ORIGBASE".out "$ORIGBASE".out.tmp
	# # cp "$BASENAME".out "$ORIGBASE".out
	# # cp "$ORIGPNG" "$ORIGPNG".tmp
	# # cp "$VP8ORIGBASE".out "$VP8ORIGBASE".out.tmp
	# # cp "$VP8BASENAME".out "$VP8ORIGBASE".out
	# cd run
	# # FRAMENUMBER=$i
	# # export FRAMENUMBER
	# ../bin/ssim_vs_bpp.sh "$FILE".y4m-xc-$i.out
	# cd ..
	# # mv "$ORIGBASE".out "$BASENAME".out
	# # mv "$ORIGBASE".out.tmp "$ORIGBASE".out
	# # mv "$VP8ORIGBASE".out "$VP8BASENAME".out
	# # mv "$VP8ORIGBASE".out.tmp "$VP8ORIGBASE".out
	# # mv "$ORIGPNG" run/"$FILE".y4m-$i.png
	# # mv "$ORIGPNG".tmp "$ORIGPNG"
# done