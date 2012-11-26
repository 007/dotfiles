#!/bin/bash

#echo "diffing $6 and $7"

DIFF="/Users/ryan/bin/p4merge.app/Contents/MacOS/p4merge"

# SVN provides the paths as the 9th, 10th, 11th params - wtf?!
THEIRS="${6}"
YOURS="${7}"

#echo running "$DIFF -dw -C utf8 \"$THEIRS\" \"$YOURS\""
$DIFF -dw -C utf8 "$THEIRS" "$YOURS"


