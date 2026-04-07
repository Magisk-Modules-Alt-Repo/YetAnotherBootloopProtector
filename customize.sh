#!/bin/sh
timeout=10 #change value to change timeout

ui_print "- Yet Another Bootloop Protector"
ui_print ""
ui_print "- Choose SystemUI Monitor Mode"
ui_print "- Press VOLUME UP   => ENABLE"
ui_print "- Press VOLUME DOWN => DISABLE"
ui_print "- Waiting for your choice ( ${timeout}s timeout )..."
ui_print ""

#ref "https://github.com/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector/issues/2#issue-3012688788"

while true; do
	event=$(timeout ${timeout} getevent -qlc 1 2>/dev/null)
	exitcode=$?
	if [ "$exitcode" -eq 124 ] || [ "$exitcode" -eq 143 ]; then
		# Magisk BusyBox `timeout` returned 143 (SIGTERM), Android toybox ( /system/bin/timeout ) returned 124.
		ui_print "- No key pressed. Defaulting to DISABLED."
		touch /data/adb/systemui.monitor.disable
		break
	fi
	if echo "$event" | grep -q "KEY_VOLUMEUP"; then
		ui_print "- SystemUI Monitor enabled."
		rm -f /data/adb/systemui.monitor.disable 2>/dev/null
		break
	elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
		ui_print "- SystemUI Monitor disabled."
		touch /data/adb/systemui.monitor.disable
		break
	fi
done

ui_print ""
source "$MODPATH/verify.sh"
ui_print ""

mkdir -p "/data/adb/service.d"
mv "$MODPATH/.status.sh" "/data/adb/service.d"
chmod +x "/data/adb/service.d/.status.sh"
yabp=/data/adb/YABP
mkdir -p "$yabp"
cp -n "$MODPATH/allowed-modules.txt" "$yabp/"
cp -n "$MODPATH/allowed-scripts.txt" "$yabp/"
set_perm_recursive "$MODPATH" 0 0 0755 0644
ui_print ""
ui_print "- Installation complete!"