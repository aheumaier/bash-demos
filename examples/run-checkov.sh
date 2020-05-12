#!/bin/bash
# Runs the Checkov static analysis tool on all subdirectories of the target given as argument 1.

# The target directory for scanning.
TARGET_DIR=$1
SUBDIRS=$(find $TARGET_DIR -type d)
let RETURN=0
for i in $SUBDIRS; do
    if [ -f $i/main.tf ]; then
      echo "Testing directory: ${i}"
      docker run -t -v $i:/tf bridgecrew/checkov:release-1.0.235 -d /tf
      let RETURN=$RETURN+$?
    fi
done
exit $RETURN