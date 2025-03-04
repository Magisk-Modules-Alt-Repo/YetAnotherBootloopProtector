MODULE_DIR="/data/adb/modules/YetAnotherBootloopProtector"
SYSTEMUI_MONITOR_DISABLE="/data/adb/systemui.monitor.disable"
MODULE_PROP="$MODULE_DIR/module.prop"

REQUIRED_FILES="\
    $MODULE_DIR/action.sh \
    $MODULE_DIR/service.sh \
    $MODULE_DIR/post-fs-data.sh \
    $MODULE_DIR/uninstall.sh"

# Check if required module files exist, disable module if missing
for file in $REQUIRED_FILES; do
    if [ ! -f "$file" ]; then
        grep -v "^description=" "$MODULE_PROP" > "$MODULE_PROP.tmp"
        echo "description= ⚠️ Warning : Module is corrupted. Please reinstall." >> "$MODULE_PROP.tmp"
        mv "$MODULE_PROP.tmp" "$MODULE_PROP"
        touch "$MODULE_DIR/disable"
        exit 0
    fi
done

if [ -f "$MODULE_DIR/disable" ]; then
    grep -v "^description=" "$MODULE_PROP" > "$MODULE_PROP.tmp"
    echo "description= SystemUI Monitor ❌ | Bootloop Monitor ❌ | ⚠️ Module is Disabled " >> "$MODULE_PROP.tmp"
    mv "$MODULE_PROP.tmp" "$MODULE_PROP"
elif [ -f "$SYSTEMUI_MONITOR_DISABLE" ]; then
    grep -v "^description=" "$MODULE_PROP" > "$MODULE_PROP.tmp"
    echo "description= SystemUI Monitor ❌ | Bootloop Monitor ✅ | Module is Working ✨" >> "$MODULE_PROP.tmp"
    mv "$MODULE_PROP.tmp" "$MODULE_PROP"
else
    grep -v "^description=" "$MODULE_PROP" > "$MODULE_PROP.tmp"
    echo "description= SystemUI Monitor ✅ | Bootloop Monitor ✅ | Module is Working ✨" >> "$MODULE_PROP.tmp"
    mv "$MODULE_PROP.tmp" "$MODULE_PROP"
fi
