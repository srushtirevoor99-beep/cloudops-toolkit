#!/bin/bash
LOGFILE=$1

echo "Top 5 most frequent lines in $LOGFILE:"
sort "$LOGFILE" |uniq -c|sort -nr|head -5
