#!/usr/bin/env bash
# Usage: memory-alert.sh [threshold_percent]   (default: 80)
#
# Exit codes: 0 = usage is at or below the threshold
#             1 = usage is above the threshold (lets cron or CI react)
#             2 = bad input or usage could not be read
set -euo pipefail

THRESHOLD="${1:-80}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || ((THRESHOLD > 100)); then
    echo "Usage: $0 [threshold_percent 0-100]" >&2
    exit 2
fi

if ! USAGE=$(free | awk '/Mem:/{printf "%.0f", $3/$2*100}') || [[ -z "$USAGE" ]]; then
    echo "Error: could not read memory usage" >&2
    exit 2
fi

if ((USAGE > THRESHOLD)); then
    echo "WARNING: Memory usage is at ${USAGE}% (threshold ${THRESHOLD}%)"
    exit 1
fi
echo "Memory usage is fine at ${USAGE}% (threshold ${THRESHOLD}%)"
