#!/bin/bash

if [ ! -d "subset1-y4m" ]; then
    wget -O "subset1-y4m.tar.gz" "https://people.xiph.org/~tterribe/daala/subset1-y4m.tar.gz"
    # make sure the file we got is OK
    echo "e72beed364ffbc3599f31971a21a749f9f3705ff36f2e3e96c4474f08dac9e39  subset1-y4m.tar.gz" | sha256sum -c -
    if [[ "$?" == "0" ]]; then
        tar xf subset1-y4m.tar.gz
        rm subset1-y4m.tar.gz
    else
        exit 1
    fi
fi

#if [ ! -f "ducks_take_off_short.y4m" ]; then
#    wget "https://people.xiph.org/~tdaede/sets/video-1-short/ducks_take_off_short.y4m"
#fi
