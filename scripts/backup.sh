#!/bin/bash
# Author: Srushti
# Usage: backup.sh <source_dir> <dest_dir>
# Optional: export BUCKET_NAME=my-bucket to also upload to S3

SOURCE=$1
DEST=$2
DATE=$(date +%Y-%m-%d)
ARCHIVE="$DEST/backup-$DATE.tar.gz"

if [[ -z "$SOURCE" || -z "$DEST" ]]; then
    echo "Usage: $0 <source_dir> <dest_dir>" >&2
    exit 1
fi

if [[ ! -d "$SOURCE" ]]; then
    echo "Error: source '$SOURCE' does not exist" >&2
    exit 1
fi

mkdir -p "$DEST"

if ! tar -czf "$ARCHIVE" "$SOURCE"; then
    echo "Error: tar failed, removing incomplete archive" >&2
    rm -f "$ARCHIVE"
    exit 1
fi
echo "Backup saved to $ARCHIVE"

# Keep only the 5 most recent local backups
printf '%s\n' "$DEST"/backup-*.tar.gz | sort -r | tail -n +6 | xargs -r rm -f

# Upload to S3 if a bucket is configured
if [[ -n "$BUCKET_NAME" ]]; then
    if aws s3 cp "$ARCHIVE" "s3://$BUCKET_NAME/backups/"; then
        echo "Uploaded to s3://$BUCKET_NAME/backups/"
    else
        echo "S3 upload failed. Local copy kept at $ARCHIVE" >&2
        exit 1
    fi
fi
