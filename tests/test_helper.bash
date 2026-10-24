# Shared setup for every .bats file: put the fake aws/df/free first on PATH,
# give each test its own scratch directory, and expose the scripts directory.

common_setup() {
    SCRIPTS="$BATS_TEST_DIRNAME/../scripts"
    chmod +x "$BATS_TEST_DIRNAME"/stubs/* "$SCRIPTS"/*.sh
    export PATH="$BATS_TEST_DIRNAME/stubs:$PATH"

    export FAKE_S3_DIR="$BATS_TEST_TMPDIR/s3"
    export FAKE_AWS_LOG="$BATS_TEST_TMPDIR/aws.log"
    mkdir -p "$FAKE_S3_DIR"
    : >"$FAKE_AWS_LOG"

    SRC="$BATS_TEST_TMPDIR/src"
    DEST="$BATS_TEST_TMPDIR/backups"
    mkdir -p "$SRC"
    echo hello >"$SRC/file.txt"

    unset BUCKET_NAME NOTIFY_TOPIC_ARN KEEP FAKE_AWS_FAIL
}
