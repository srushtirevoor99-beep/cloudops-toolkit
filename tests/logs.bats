#!/usr/bin/env bats

load test_helper

setup() {
    common_setup
    LOGS="$BATS_TEST_TMPDIR/logs"
    mkdir -p "$LOGS"
}

# --- log-analyzer ---------------------------------------------------------

make_log() {
    printf '%s\n' ERROR disk ERROR ERROR WARN WARN info >"$LOGS/app.txt"
}

@test "log-analyzer: shows the most frequent line first" {
    make_log
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/app.txt"
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" == *"3 ERROR"* ]]
    [[ "${lines[2]}" == *"2 WARN"* ]]
}

@test "log-analyzer: top_n limits the output" {
    make_log
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/app.txt" 1
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "log-analyzer: a pattern filters the lines that are counted" {
    make_log
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/app.txt" 5 'WARN|disk'
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARN"* ]]
    [[ "$output" == *"disk"* ]]
    [[ "$output" != *"ERROR"* ]]
}

@test "log-analyzer: a pattern with no matches still succeeds" {
    make_log
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/app.txt" 5 'nomatch'
    [ "$status" -eq 0 ]
}

@test "log-analyzer: an invalid pattern is an error" {
    make_log
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/app.txt" 5 '[unclosed'
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a valid"* ]]
}

@test "log-analyzer: fails on a missing file or no arguments" {
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/missing.txt"
    [ "$status" -eq 1 ]
    run "$SCRIPTS/log-analyzer.sh"
    [ "$status" -eq 1 ]
}

@test "log-analyzer: rejects a bad top_n" {
    make_log
    run "$SCRIPTS/log-analyzer.sh" "$LOGS/app.txt" abc
    [ "$status" -eq 1 ]
}

# --- log-cleaner ----------------------------------------------------------

@test "log-cleaner: compresses only logs older than the cutoff" {
    echo old >"$LOGS/old.log"
    echo new >"$LOGS/new.log"
    touch -d '10 days ago' "$LOGS/old.log"
    run "$SCRIPTS/log-cleaner.sh" "$LOGS" 7
    [ "$status" -eq 0 ]
    [[ "$output" == *"Compressed 1 log file(s)"* ]]
    [ -f "$LOGS/old.log.gz" ]
    [ ! -e "$LOGS/old.log" ]
    [ -f "$LOGS/new.log" ]
}

@test "log-cleaner: --dry-run lists files and changes nothing" {
    echo old >"$LOGS/old.log"
    touch -d '10 days ago' "$LOGS/old.log"
    run "$SCRIPTS/log-cleaner.sh" "$LOGS" 7 --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"old.log"* ]]
    [[ "$output" == *"Dry run"* ]]
    [ -f "$LOGS/old.log" ]
    [ ! -e "$LOGS/old.log.gz" ]
}

@test "log-cleaner: handles file names with spaces" {
    echo old >"$LOGS/my app.log"
    touch -d '10 days ago' "$LOGS/my app.log"
    run "$SCRIPTS/log-cleaner.sh" "$LOGS" 7
    [ "$status" -eq 0 ]
    [ -f "$LOGS/my app.log.gz" ]
}

@test "log-cleaner: nothing to do exits 0" {
    echo new >"$LOGS/new.log"
    run "$SCRIPTS/log-cleaner.sh" "$LOGS" 7
    [ "$status" -eq 0 ]
    [[ "$output" == *"No .log files older"* ]]
}

@test "log-cleaner: rejects bad input" {
    run "$SCRIPTS/log-cleaner.sh"
    [ "$status" -eq 1 ]
    run "$SCRIPTS/log-cleaner.sh" "$LOGS/missing" 7
    [ "$status" -eq 1 ]
    run "$SCRIPTS/log-cleaner.sh" "$LOGS" abc
    [ "$status" -eq 1 ]
    run "$SCRIPTS/log-cleaner.sh" "$LOGS" 7 --bogus
    [ "$status" -eq 1 ]
}
