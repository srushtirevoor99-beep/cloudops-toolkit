#!/usr/bin/env bats

load test_helper

setup() {
    common_setup
    export BUCKET_NAME=test-bucket
}

# Create an archive the same way backup.sh does and put it in the fake bucket.
put_backup() {
    local name="$1" content="$2"
    local work="$BATS_TEST_TMPDIR/work-$name"
    mkdir -p "$work/data" "$FAKE_S3_DIR/$BUCKET_NAME/backups"
    echo "$content" >"$work/data/file.txt"
    tar -czf "$FAKE_S3_DIR/$BUCKET_NAME/backups/$name" -C "$work" data
}

@test "fails without a destination" {
    run "$SCRIPTS/restore.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "fails when BUCKET_NAME is not set" {
    unset BUCKET_NAME
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BUCKET_NAME"* ]]
}

@test "restores the newest backup by default" {
    put_backup backup-2026-01-01.tar.gz old
    put_backup backup-2026-03-15.tar.gz newest
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out"
    [ "$status" -eq 0 ]
    [[ "$output" == *"backup-2026-03-15.tar.gz"* ]]
    [ "$(cat "$BATS_TEST_TMPDIR/out/data/file.txt")" = "newest" ]
}

@test "restores a named backup" {
    put_backup backup-2026-01-01.tar.gz old
    put_backup backup-2026-03-15.tar.gz newest
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out" backup-2026-01-01.tar.gz
    [ "$status" -eq 0 ]
    [ "$(cat "$BATS_TEST_TMPDIR/out/data/file.txt")" = "old" ]
}

@test "round trip: a backup made by backup.sh can be restored" {
    run "$SCRIPTS/backup.sh" "$SRC" "$DEST"
    [ "$status" -eq 0 ]
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out"
    [ "$status" -eq 0 ]
    [ "$(cat "$BATS_TEST_TMPDIR/out/src/file.txt")" = "hello" ]
}

@test "fails when the bucket has no backups" {
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no backups found"* ]]
}

@test "rejects file names that are not backup archives" {
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out" "../../etc/passwd"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a valid backup file name"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/out" ]
}

@test "refuses to restore a corrupt archive" {
    mkdir -p "$FAKE_S3_DIR/$BUCKET_NAME/backups"
    echo "not a tarball" >"$FAKE_S3_DIR/$BUCKET_NAME/backups/backup-2026-02-02.tar.gz"
    run "$SCRIPTS/restore.sh" "$BATS_TEST_TMPDIR/out" backup-2026-02-02.tar.gz
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a readable archive"* ]]
    [ ! -e "$BATS_TEST_TMPDIR/out" ]
}
