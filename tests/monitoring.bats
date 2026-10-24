#!/usr/bin/env bats

load test_helper

setup() {
    common_setup
}

@test "disk-alert: below the threshold exits 0" {
    FAKE_DISK_PCT=50 run "$SCRIPTS/disk-alert.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fine at 50%"* ]]
}

@test "disk-alert: above the default threshold of 80 exits 1" {
    FAKE_DISK_PCT=85 run "$SCRIPTS/disk-alert.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"WARNING"* ]]
    [[ "$output" == *"85%"* ]]
}

@test "disk-alert: exactly at the threshold is not a warning" {
    FAKE_DISK_PCT=80 run "$SCRIPTS/disk-alert.sh"
    [ "$status" -eq 0 ]
}

@test "disk-alert: a custom threshold is honoured" {
    FAKE_DISK_PCT=60 run "$SCRIPTS/disk-alert.sh" 50
    [ "$status" -eq 1 ]
    FAKE_DISK_PCT=60 run "$SCRIPTS/disk-alert.sh" 70
    [ "$status" -eq 0 ]
}

@test "disk-alert: rejects a bad threshold with exit 2" {
    run "$SCRIPTS/disk-alert.sh" abc
    [ "$status" -eq 2 ]
    run "$SCRIPTS/disk-alert.sh" 150
    [ "$status" -eq 2 ]
}

@test "memory-alert: below the threshold exits 0" {
    FAKE_MEM_PCT=40 run "$SCRIPTS/memory-alert.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fine at 40%"* ]]
}

@test "memory-alert: above the default threshold of 80 exits 1" {
    FAKE_MEM_PCT=90 run "$SCRIPTS/memory-alert.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"WARNING"* ]]
}

@test "memory-alert: a custom threshold is honoured" {
    FAKE_MEM_PCT=60 run "$SCRIPTS/memory-alert.sh" 50
    [ "$status" -eq 1 ]
}

@test "memory-alert: rejects a bad threshold with exit 2" {
    run "$SCRIPTS/memory-alert.sh" -5
    [ "$status" -eq 2 ]
}

@test "sysinfo: prints the expected sections" {
    run "$SCRIPTS/sysinfo.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"System Information"* ]]
    [[ "$output" == *"Hostname"* ]]
    [[ "$output" == *"Kernel"* ]]
}
