#!/usr/bin/env bash
# Usage: log-analyzer.sh <logfile> [top_n] [pattern]
#
# Prints the top_n most frequent lines (default 5). When a pattern (extended
# regex) is given, only matching lines are counted.
# No pipefail here: head closing the pipe early would otherwise look like a failure.
set -eu

LOGFILE="${1:-}"
TOP="${2:-5}"
PATTERN="${3:-}"

if [[ -z "$LOGFILE" ]]; then
    echo "Usage: $0 <logfile> [top_n] [pattern]" >&2
    exit 1
fi

if [[ ! -f "$LOGFILE" ]]; then
    echo "Error: '$LOGFILE' is not a file" >&2
    exit 1
fi

if ! [[ "$TOP" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: top_n must be a positive integer, got '$TOP'" >&2
    exit 1
fi

if [[ -n "$PATTERN" ]]; then
    rc=0
    grep -E -- "$PATTERN" /dev/null 2>/dev/null || rc=$?
    if ((rc > 1)); then
        echo "Error: '$PATTERN' is not a valid extended regular expression" >&2
        exit 1
    fi
fi

# grep exits 1 when nothing matches, which is fine here; any other failure is an error.
select_lines() {
    if [[ -n "$PATTERN" ]]; then
        grep -E -- "$PATTERN" "$LOGFILE" || [[ $? -eq 1 ]]
    else
        cat -- "$LOGFILE"
    fi
}

if [[ -n "$PATTERN" ]]; then
    echo "Top $TOP most frequent lines matching '$PATTERN' in $LOGFILE:"
else
    echo "Top $TOP most frequent lines in $LOGFILE:"
fi
select_lines | sort | uniq -c | sort -nr | head -n "$TOP"
