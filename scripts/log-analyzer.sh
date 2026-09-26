#!/bin/bash
LOGFILE=$1

echo "Top 5 most frequent lines in $LOGFILE:"
sort "$LOGFILE" |uniq -c|sort -nr|head -5
# TODO: add filtering options
# TODO: add date range support
# TODO: add export to CSV
# Notes complete
