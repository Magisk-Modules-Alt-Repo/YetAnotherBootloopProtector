# YetAnotherBootLoopProtector by @rhythmcache
MARKER_DIR="${0%/*}"
LOGFILE="/data/local/tmp/service.log"
MAGISK_MODULES_DIR="/data/adb/modules"
BOOT_TIMEOUT=120
PACKAGE="com.android.systemui" #default: SystemUI
MONITOR_DISABLE_FILE="/data/adb/systemui.monitor.disable"

# Log events
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Check if boot is completed
is_boot_completed() {
    BOOT_COMPLETED=$(getprop sys.boot_completed)
    if [ "$BOOT_COMPLETED" = "1" ]; then
        return 0
    else
        return 1
    fi
}

# Disable all Magisk modules
disable_magisk_modules() {
    log_event "Disabling all Magisk modules..."
    for MODULE in "$MAGISK_MODULES_DIR"/*; do
        if [ -d "$MODULE" ]; then
            touch "$MODULE/disable"
            chown 0:0 "$MODULE/disable"
            chmod 644 "$MODULE/disable"
            log_event "Disabled module: $MODULE"
        fi
    done
}

# Check for marker files
check_marker_files() {
    MARKER1="$MARKER_DIR/marker1"
    MARKER2="$MARKER_DIR/marker2"
    MARKER3="$MARKER_DIR/marker3"

    if [ -f "$MARKER3" ]; then
        log_event "Bootloop detected (3 markers found). Disabling Magisk modules and rebooting..."
        disable_magisk_modules
        rm -f "$MARKER1" "$MARKER2" "$MARKER3"
        log_event "Deleted all marker files. Rebooting..."
        reboot
    elif [ -f "$MARKER2" ]; then
        log_event "Second failed boot detected, creating marker3"
        touch "$MARKER3"
    elif [ -f "$MARKER1" ]; then
        log_event "First failed boot detected, creating marker2"
        touch "$MARKER2"
    else
        log_event "No markers found, creating marker1"
        touch "$MARKER1"
    fi
}

# Check if a package is running
is_package_running() {
    if pidof "$PACKAGE" > /dev/null; then
        return 0  # Package is running
    else
        return 1  # Package is not running
    fi
}

# Monitor SystemUI
monitor_package() {
    if [ -f "$MONITOR_DISABLE_FILE" ]; then
        log_event "SystemUI monitoring is disabled. Exiting monitor."
        return
    fi

    log_event "Starting continuous monitor for package: $PACKAGE"
    local MONITOR_TIMEOUT=40  # Total timeout in seconds
    local CHECK_INTERVAL=5    # Check interval in seconds
    local FAILURE_TIME=0      # Time elapsed since package stopped running

    while true; do
        if is_package_running; then
            log_event "$PACKAGE is running. Resetting failure timer."
            FAILURE_TIME=0
        else
            log_event "$PACKAGE is not running. Failure timer: $FAILURE_TIME seconds."
            FAILURE_TIME=$((FAILURE_TIME + CHECK_INTERVAL))
            if [ $FAILURE_TIME -ge $MONITOR_TIMEOUT ]; then
                log_event "$PACKAGE has not been running for $MONITOR_TIMEOUT seconds. Disabling Magisk modules and rebooting..."
                disable_magisk_modules
                reboot
            fi
        fi
        sleep $CHECK_INTERVAL
    done
}
# post fs check
signature() {
    S1="$MARKER_DIR/s1"
    S2="$MARKER_DIR/s2"
    S3="$MARKER_DIR/s3"
    DETECTED=0

    # Check if any of the files exist
    if [ -f "$S1" ]; then
        DETECTED=1
        log_event "Found s1"
    fi
    if [ -f "$S2" ]; then
        DETECTED=1
        log_event "Found s2"
    fi
    if [ -f "$S3" ]; then
        DETECTED=1
        log_event "Found s3"
    fi

    if [ "$DETECTED" -eq 1 ]; then
        log_event "Post-fs signature detected..."
        rm -f "$S1" "$S2" "$S3"
    else
        log_event "Warning: Post-fs signature not found."
    fi
}

# Main logic
signature
log_event "Service started. Waiting for boot completion..."
check_marker_files

# Wait for boot to complete
SECONDS_PASSED=0
while [ $SECONDS_PASSED -lt $BOOT_TIMEOUT ]; do
    if is_boot_completed; then
        log_event "Boot completed successfully. Cleaning up marker files."
        rm -f "$MARKER_DIR/marker1" "$MARKER_DIR/marker2" "$MARKER_DIR/marker3"
        break
    fi
    sleep 5
    SECONDS_PASSED=$((SECONDS_PASSED + 5))
done

#reboot
if ! is_boot_completed; then
    log_event "Boot did not complete within $BOOT_TIMEOUT seconds. Disabling Magisk modules and rebooting..."
    disable_magisk_modules
    rm -f "$MARKER_DIR/marker1" "$MARKER_DIR/marker2" "$MARKER_DIR/marker3"
    log_event "Rebooting the device..."
    reboot
fi
#monitoring
monitor_package
