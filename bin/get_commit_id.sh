#!/bin/bash

set -e
set -o pipefail

if [ -z $GITROOT ]; then
    echo "$0: Please set GITROOT env variable to point to your checkout."
    exit 1
fi

set +e
git -C "$GITROOT" status &>/dev/null
if [ $? != 0 ]; then
    echo "$0: GITROOT does not seem to point to a git repo."
    exit 1
fi
set -e

date -d "$(git -C "$GITROOT" log -1 --pretty=format:%cD)" "+%Y%m%d%H%M-$(git -C "$GITROOT" log -1 --pretty=format:%H)"
