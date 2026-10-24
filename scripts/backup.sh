#!/usr/bin/env bash
# Author: Srushti
# Usage: backup.sh <source_dir> <dest_dir>
#
# Environment (all optional):
#   BUCKET_NAME       upload the archive to s3://$BUCKET_NAME/backups/
#   NOTIFY_TOPIC_ARN  SNS topic that receives a message when a backup fails
#   KEEP              number of local backups to keep (default 5)
set -euo pipefail

SOURCE="${1:-}"
DEST="${2:-}"
KEEP="${KEEP:-5}"
DATE=$(date +%Y-%m-%d)

if [[ -z "$SOURCE" || -z "$DEST" ]]; then
    echo "Usage: $0 <source_dir> <dest_dir>" >&2
    exit 1
fi

if ! [[ "$KEEP" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: KEEP must be a positive integer, got '$KEEP'" >&2
    exit 1
fi

# Print the message and, if an SNS topic is configured, publish it too.
notify_failure() {
    local message="$1"
    echo "$message" >&2
    if [[ -n "${NOTIFY_TOPIC_ARN:-}" ]]; then
        aws sns publish \
            --topic-arn "$NOTIFY_TOPIC_ARN" \
            --subject "Backup failed on $(hostname)" \
            --message "$message" >/dev/null ||
            echo "Warning: could not publish the failure notice to SNS" >&2
    fi
}

if [[ ! -d "$SOURCE" ]]; then
    notify_failure "Error: source '$SOURCE' does not exist"
    exit 1
fi

mkdir -p "$DEST"
ARCHIVE="$DEST/backup-$DATE.tar.gz"

# -C keeps paths inside the archive relative, so restores never write to absolute paths.
if ! tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"; then
    rm -f "$ARCHIVE"
    notify_failure "Error: tar failed for '$SOURCE', incomplete archive removed"
    exit 1
fi
echo "Backup saved to $ARCHIVE"

# Keep only the newest $KEEP local backups.
printf '%s\n' "$DEST"/backup-*.tar.gz | sort -r | tail -n +"$((KEEP + 1))" | xargs -r rm -f

# Upload to S3 if a bucket is configured.
if [[ -n "${BUCKET_NAME:-}" ]]; then
    if aws s3 cp "$ARCHIVE" "s3://$BUCKET_NAME/backups/" --sse AES256; then
        echo "Uploaded to s3://$BUCKET_NAME/backups/"
    else
        notify_failure "S3 upload failed. Local copy kept at $ARCHIVE"
        exit 1
    fi
fi
