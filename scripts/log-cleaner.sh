#!/bin/bash
LODGIR=$1
DAYS=$2

find "$LODGIR" -name "*.log" -mtime +"$DAYS" -exec gzip {} \;

echo "Compressed logs older than $DAYS days in $LODGIR"
