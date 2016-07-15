#!/bin/bash
# calculates the average of the numbers in the arguments
#
# (C) 2016 William Zheng <wizeng@stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail

cat "$@" | awk '{ total += $1; count++ } END { print total/count }'
