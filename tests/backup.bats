#!/usr/bin/env bats

load test_helper

setup() {
    common_setup
}

@test "creates a dated archive that contains the source files" {
    run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    archive="$DEST/backup-$(date +%Y-%m-%d).tar.gz"
    [ -f "$archive" ]
    tar -tzf "$archive" | grep -q 'src/file.txt'
}

@test "stores relative paths only" {
    run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    run bash -c "tar -tzf '$DEST'/backup-*.tar.gz | grep '^/'"
    [ "$status" -ne 0 ]
}

@test "fails without arguments" {
    run "$SCRIPTS/backup.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "fails when the source folder is missing and leaves no archive" {
    run "$SCRIPTS/backup.sh" "$BATS_TEST_TMPDIR/nonexistent" "$DEST"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
    run bash -c "ls '$DEST'/backup-*.tar.gz"
    [ "$status" -ne 0 ]
}

@test "fails when the source folder is empty and leaves no archive" {
    EMPTY="$BATS_TEST_TMPDIR/empty"
    mkdir -p "$EMPTY"
    run "$SCRIPTS/backup.sh" "$EMPTY" "$DEST"
    [ "$status" -eq 1 ]
    [[ "$output" == *"is empty"* ]]
    run bash -c "ls '$DEST'/backup-*.tar.gz"
    [ "$status" -ne 0 ]
}

@test "an empty source does not push older backups out through retention" {
    EMPTY="$BATS_TEST_TMPDIR/empty"
    mkdir -p "$EMPTY" "$DEST"
    for d in 01 02 03 04 05; do
        touch "$DEST/backup-2020-01-$d.tar.gz"
    done
    run "$SCRIPTS/backup.sh" "$EMPTY" "$DEST"
    [ "$status" -eq 1 ]
    [ "$(find "$DEST" -name 'backup-*.tar.gz' | wc -l)" -eq 5 ]
    [ -e "$DEST/backup-2020-01-01.tar.gz" ]
}

@test "keeps only the 5 newest local backups by default" {
    mkdir -p "$DEST"
    for d in 01 02 03 04 05 06 07; do
        touch "$DEST/backup-2020-01-$d.tar.gz"
    done
    run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    [ "$(find "$DEST" -name 'backup-*.tar.gz' | wc -l)" -eq 5 ]
    # the oldest ones are the ones removed
    [ ! -e "$DEST/backup-2020-01-01.tar.gz" ]
    [ -e "$DEST/backup-$(date +%Y-%m-%d).tar.gz" ]
}

@test "KEEP changes how many local backups are kept" {
    mkdir -p "$DEST"
    for d in 01 02 03 04; do
        touch "$DEST/backup-2020-01-$d.tar.gz"
    done
    KEEP=2 run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    [ "$(find "$DEST" -name 'backup-*.tar.gz' | wc -l)" -eq 2 ]
}

@test "rejects a non-numeric KEEP" {
    KEEP=abc run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 1 ]
    [[ "$output" == *"KEEP must be"* ]]
}

@test "does not call aws when BUCKET_NAME is not set" {
    run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    [ ! -s "$FAKE_AWS_LOG" ]
}

@test "uploads to S3 with server-side encryption when BUCKET_NAME is set" {
    BUCKET_NAME=test-bucket run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Uploaded to s3://test-bucket/backups/"* ]]
    [ -f "$FAKE_S3_DIR/test-bucket/backups/backup-$(date +%Y-%m-%d).tar.gz" ]
    grep -q -- '--sse AES256' "$FAKE_AWS_LOG"
}

@test "a failed upload exits non-zero and keeps the local copy" {
    BUCKET_NAME=test-bucket FAKE_AWS_FAIL=1 run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 1 ]
    [[ "$output" == *"S3 upload failed"* ]]
    [ -f "$DEST/backup-$(date +%Y-%m-%d).tar.gz" ]
}

@test "publishes an SNS message when the source is missing" {
    NOTIFY_TOPIC_ARN=arn:aws:sns:ap-south-1:123456789012:alerts \
        run "$SCRIPTS/backup.sh" "$BATS_TEST_TMPDIR/nonexistent" "$DEST"
    [ "$status" -eq 1 ]
    grep -q 'sns publish' "$FAKE_AWS_LOG"
    grep -q 'arn:aws:sns:ap-south-1:123456789012:alerts' "$FAKE_AWS_LOG"
}

@test "does not call SNS when the backup succeeds" {
    NOTIFY_TOPIC_ARN=arn:aws:sns:ap-south-1:123456789012:alerts \
        run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    run grep -q 'sns publish' "$FAKE_AWS_LOG"
    [ "$status" -ne 0 ]
}
