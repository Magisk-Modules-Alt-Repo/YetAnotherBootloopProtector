#!/system/bin/sh
# Yet Another Bootloop Protector
#github.com/rhythmcache
MODDIR=/data/adb/modules
echo "╔═══════════════════════════════════╗"
echo "║  Yet Another Bootloop Protector   ║"
echo "╚═══════════════════════════════════╝"
echo ""
sleep 2
echo "▼ Choose Action For Modules : "
echo ""
echo "┌──────────────────────────────────┐"
echo "│  [↑] VOLUME UP   => DISABLE ALL  │"
echo "│  [↓] VOLUME DOWN => ENABLE ALL   │"
echo "└──────────────────────────────────┘"

disable_modules() {
  echo ""
  echo "→ Disabling all modules..."
  echo "   ====================="
  for module in "$MODDIR"/*; do
    if [ -d "$module" ]; then
      if [ ! -f "$module/disable" ]; then
        touch "$module/disable"
        echo "   ✓ Module $(basename "$module") disabled"
      else
        echo "   ⓘ Module $(basename "$module") was already disabled"
      fi
    fi
  done
  echo ""
  echo "✓ Operation completed!"
}
enable_modules() {
  echo ""
  echo "→ Enabling all modules..."
  echo "   ===================="
  all_enabled=true
  for dir in /data/adb/post-fs-data.d /data/adb/service.d /data/adb/post-mount.d /data/adb/boot-completed.d; do
    if [ -d "$dir" ]; then
      find "$dir" -type f -exec chmod +x {} \;
      echo "   ✓ Made all files in $dir executable"
    fi
  done
  for module in "$MODDIR"/*; do
    if [ -d "$module" ]; then
      if [ -f "$module/disable" ]; then
        rm "$module/disable"
        echo "   ✓ Module $(basename "$module") enabled"
        all_enabled=false
      else
        echo "   ⓘ Module $(basename "$module") was already enabled"
      fi
    fi
  done

  echo ""
  if $all_enabled; then
    echo "ⓘ All modules are already enabled"
  else
    echo "✓ Previously disabled modules have been enabled"
  fi
}
echo ""
echo "Waiting for input..."
while true; do
  event=$(getevent -qlc 1 2>/dev/null)
  if echo "$event" | grep -q "KEY_VOLUMEUP"; then
    echo "→ VOLUME UP detected: Disabling all modules..."
    disable_modules
    break
  elif echo "$event" | grep -q "KEY_VOLUMEDOWN"; then
    echo "→ VOLUME DOWN detected: Enabling all modules..."
    enable_modules
    break
  fi
done
echo "⚠️ Some modules might not have been enabled/disabled. Please handle them manually if needed."
echo "Exiting in 5 seconds..."
sleep 5
