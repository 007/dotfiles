#!/bin/bash
#DIFF3="/Users/ryan/bin/p4merge.app/Contents/MacOS/p4merge.real"
DIFF3="/Users/ryan/bin/p4merge.app/Contents/MacOS/p4merge"

echo param 1 $1
echo param 2 $2
echo param 3 $3
echo param 4 $4
echo param 5 $5
echo param 6 $6

LEFT=$1
RIGHT=$4
BASE=$3
MERGED=$5



BASE=$1
THEIRS=$2
MINE=$3
MERGED=$4
echo "command line is $0 $@"
echo source is $THEIRS base is $BASE mine is $MINE and dest is $MERGED
echo $DIFF3 -dw -C utf8 -merge $BASE $THEIRS $MINE $MERGED
#$DIFF3 -dw -C utf8 -merge $BASE $THEIRS $MINE $MERGED
$DIFF3 -dw -C utf8 $BASE $THEIRS $MINE $MERGED
RETVAL=$?
echo "return value was $RETVAL"

#exit 1

# After performing the merge, this script needs to print the contents
# of the merged file to stdout.  Do that in whatever way you see fit.
# Return an errorcode of 0 on successful merge, 1 if unresolved conflicts
# remain in the result.  Any other errorcode will be treated as fatal.

#exit 2


