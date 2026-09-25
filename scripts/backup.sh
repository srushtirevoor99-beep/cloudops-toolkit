#!/bin/bash

SOURCE=$1
DEST=$2
DATE=$(date +%Y-%m-%d)

tar -czf "$DEST/backup-$DATE.tar.gz" "$SOURCE"

echo "Backup saved to $DEST/backup-$DATE.tar.gz"

