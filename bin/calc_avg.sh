#!/bin/bash
# pcalculates the average of the numbers in the arguments
#
# (C) 2016 Riad S. Wahby <rsw@cs.stanford.edu>
#          and the alfalfa project (https://github.com/alfalfa/)

set -e
set -o pipefail

paste -d "\n" "$@" | awk '{ total += $1; count++ } END { print total/count }' > bppdiff.txt