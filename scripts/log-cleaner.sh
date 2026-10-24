#!/usr/bin/env bash
# Usage: log-cleaner.sh <log_dir> <days> [--dry-run]
#
# Compresses *.log files older than <days> days with gzip. With --dry-run it
# only lists the files that would be compressed.
set -euo pipefail

LOG_DIR="${1:-}"
DAYS="${2:-}"
MODE="${3:-}"

if [[ -z "$LOG_DIR" || -z "$DAYS" ]]; then
    echo "Usage: $0 <log_dir> <days> [--dry-run]" >&2
    exit 1
fi

if [[ ! -d "$LOG_DIR" ]]; then
    echo "Error: '$LOG_DIR' is not a directory" >&2
    exit 1
fi

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: days must be a non-negative integer, got '$DAYS'" >&2
    exit 1
fi

if [[ -n "$MODE" && "$MODE" != "--dry-run" ]]; then
    echo "Error: unknown option '$MODE'" >&2
    exit 1
fi

mapfile -d '' FILES < <(find "$LOG_DIR" -type f -name '*.log' -mtime +"$DAYS" -print0)

if ((${#FILES[@]} == 0)); then
    echo "No .log files older than $DAYS days in $LOG_DIR"
    exit 0
fi

if [[ "$MODE" == "--dry-run" ]]; then
    printf '%s\n' "${FILES[@]}"
    echo "Dry run: ${#FILES[@]} file(s) would be compressed"
    exit 0
fi

gzip -- "${FILES[@]}"
echo "Compressed ${#FILES[@]} log file(s) older than $DAYS days in $LOG_DIR"
