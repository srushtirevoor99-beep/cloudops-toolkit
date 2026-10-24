#!/usr/bin/env bash
# Usage: disk-alert.sh [threshold_percent] [mount_point]   (defaults: 80 and /)
#
# Exit codes: 0 = usage is at or below the threshold
#             1 = usage is above the threshold (lets cron or CI react)
#             2 = bad input or usage could not be read
set -euo pipefail

THRESHOLD="${1:-80}"
MOUNT="${2:-/}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || ((THRESHOLD > 100)); then
    echo "Usage: $0 [threshold_percent 0-100] [mount_point]" >&2
    exit 2
fi

if ! USAGE=$(df -P "$MOUNT" | awk 'NR==2{print $5}' | tr -d '%') || [[ -z "$USAGE" ]]; then
    echo "Error: could not read disk usage for '$MOUNT'" >&2
    exit 2
fi

if ((USAGE > THRESHOLD)); then
    echo "WARNING: Disk usage on $MOUNT is at ${USAGE}% (threshold ${THRESHOLD}%)"
    exit 1
fi
echo "Disk usage on $MOUNT is fine at ${USAGE}% (threshold ${THRESHOLD}%)"
