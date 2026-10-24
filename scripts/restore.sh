#!/usr/bin/env bash
# Usage: restore.sh <dest_dir> [backup_file_name]
#
# Downloads a backup from s3://$BUCKET_NAME/backups/, checks that the archive
# is readable, and extracts it into <dest_dir>. Without a file name, the newest
# backup is used.
#
# Environment:
#   BUCKET_NAME   required, the bucket that holds the backups
set -euo pipefail

DEST="${1:-}"
NAME="${2:-}"

if [[ -z "$DEST" ]]; then
    echo "Usage: $0 <dest_dir> [backup_file_name]" >&2
    exit 1
fi

if [[ -z "${BUCKET_NAME:-}" ]]; then
    echo "Error: set BUCKET_NAME to the bucket that holds the backups" >&2
    exit 1
fi

if [[ -z "$NAME" ]]; then
    # File names contain the date, so the last one in sorted order is the newest.
    NAME=$(aws s3 ls "s3://$BUCKET_NAME/backups/" | awk '{print $4}' |
        grep -E '^backup-[0-9]{4}-[0-9]{2}-[0-9]{2}\.tar\.gz$' | sort | tail -n 1 || true)
    if [[ -z "$NAME" ]]; then
        echo "Error: no backups found in s3://$BUCKET_NAME/backups/" >&2
        exit 1
    fi
fi

# Only accept the file names backup.sh creates, so a name can never contain a path.
if ! [[ "$NAME" =~ ^backup-[0-9]{4}-[0-9]{2}-[0-9]{2}\.tar\.gz$ ]]; then
    echo "Error: '$NAME' is not a valid backup file name (backup-YYYY-MM-DD.tar.gz)" >&2
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading s3://$BUCKET_NAME/backups/$NAME"
aws s3 cp "s3://$BUCKET_NAME/backups/$NAME" "$TMP/$NAME"

if ! tar -tzf "$TMP/$NAME" >/dev/null; then
    echo "Error: '$NAME' is not a readable archive, nothing was restored" >&2
    exit 1
fi

mkdir -p "$DEST"
tar -xzf "$TMP/$NAME" -C "$DEST"
echo "Restored $NAME to $DEST"
