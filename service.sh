# YetAnotherBootLoopProtector by @rhythmcache
MARKER_DIR="${0%/*}"
LOGFILE="/data/local/tmp/service.log"
MAGISK_MODULES_DIR="/data/adb/modules"
BOOT_TIMEOUT=100
PACKAGE="com.android.systemui" #default: SystemUI
MONITOR_DISABLE_FILE="/data/adb/systemui.monitor.disable"
lock_file="/data/adb/.tmp.lock"

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

# Disable All Magisk Modules
disable_magisk_modules() {
    log_event "Disabling all Magisk modules..."
    for MODULE in "$MAGISK_MODULES_DIR"/*; do
        if [ -d "$MODULE" ]; then
            touch "$MODULE/disable"
            log_event "Disabled module: $MODULE"
        fi
    done
    for DIR in /data/adb/service.d /data/adb/post-fs-data.d /data/adb/post-mount.d /data/adb/boot-completed.d; do
    if [ -d "$DIR" ]; then
        find "$DIR" -type f ! -name ".status.sh" -exec chmod 644 {} \;
        log_event "Changed permissions for files in $DIR"
    fi
done
MODULE_PROP="$MARKER_DIR/module.prop"
if [ -f "$MODULE_PROP" ]; then
    sed -i'' '/^description=/d' "$MODULE_PROP"
    echo "description=Module Was Disabled Because a Bootloop Was Detected." >> "$MODULE_PROP"
    log_event "Updated description in $MODULE_PROP"
fi
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

# monitor zygote
zygote_monitor() {
  dur=30   # Duration
  int=4    # Interval
  max=4    # Max PID changes
  changes=0
  last_pid=""
  start=$(date +%s)
  
  arch=$(getprop ro.product.cpu.abi)
  if [ "$arch" = "arm64-v8a" ] || [ "$arch" = "x86_64" ]; then
    check="zygote64"
  else
    check="zygote"
  fi
  
  log_event "Zygote monitor started."

  while :; do
    now=$(date +%s)
    if [ $((now - start)) -ge "$dur" ]; then
      break
    fi

    cur_pid=$(pidof "$check" 2>/dev/null || echo "")
    if [ -n "$cur_pid" ]; then
      overlap=0
      for pid in $(echo "$last_pid" | tr ' ' '\n'); do
        case " $cur_pid " in
          *" $pid "*)
            overlap=1
            break
            ;;
        esac
      done
      if [ "$overlap" -eq 0 ]; then
        changes=$((changes + 1))
        log_event "PID changed: $last_pid -> $cur_pid (Count: $changes)"
      fi
      last_pid="$cur_pid"
    fi

    if [ "$changes" -ge "$max" ]; then
      log_event "PID changed $changes times. Disabling modules."
      disable_magisk_modules
      reboot
      return
    fi

    sleep "$int"
  done

  log_event "Zygote is OK"
}
  
#SystemUI - PID

systemui_monitor() {
  local monitor_dur=30  # Monitor duration
  local check_int=3     # time between PID checks
  local max_chg=3       # Max PID changes 
  local pid_chg=0       # Counter for PID changes
  local last_pid=""     # 
  local curr_pid        # 
  local start_time=$(date +%s)  # Start time of monitoring
  local curr_time
 
  log_event "Checking systemui pid "
  touch "$lock_file"

  while true; do
    curr_time=$(date +%s)
    if [ $((curr_time - start_time)) -ge $monitor_dur ]; then
      break
    fi

    curr_pid=$(pidof "$PACKAGE")
    if [ -n "$curr_pid" ] && [ "$curr_pid" != "$last_pid" ]; then
      pid_chg=$((pid_chg + 1))
      log_event "SystemUI PID changed: $last_pid -> $curr_pid (Change count: $pid_chg)"
      last_pid="$curr_pid"
    fi

    if [ $pid_chg -ge $max_chg ]; then
      log_event "SystemUI pid changed $pid_chg times within 30s"
      disable_magisk_modules
      rm -f "$lock_file"
      reboot
      return
    fi

    sleep "$check_int"
  done

  log_event "pid check completed "
  rm -f "$lock_file"
}



# Monitor SystemUI
monitor_package() {
    if [ -f "$MONITOR_DISABLE_FILE" ]; then
        log_event "SystemUI monitoring is disabled. Exiting monitor."
        return
    fi

    log_event "Starting continuous monitor for package: $PACKAGE"
    local MONITOR_TIMEOUT=25  # Total timeout in seconds
    local CHECK_INTERVAL=5    # Check interval in seconds
    local FAILURE_TIME=0      # Time elapsed since package stopped running

    while true; do
        if is_package_running; then
            FAILURE_TIME=0
        else
            log_event "$PACKAGE is not running. Failure timer: $FAILURE_TIME seconds."
            FAILURE_TIME=$((FAILURE_TIME + CHECK_INTERVAL))
            if [ ! -f "$lock_file" ]; then
                systemui_monitor &  
            fi 
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
        log_event "Warning: Post-fs signature not found.."
    fi
}

# Main logic
signature
log_event "Service started. Waiting for boot completion..."
check_marker_files
sleep 3
zygote_monitor
rm -f "$lock_file"
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
