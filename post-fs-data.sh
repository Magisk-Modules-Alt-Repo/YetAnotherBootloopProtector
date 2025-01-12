DIR="${0%/*}"
description() {
    MODULE_PROP="$DIR/module.prop"
    if [ -f "$MODULE_PROP" ]; then
        sed -i '/^description=/d' "$MODULE_PROP"
        echo "description=Module Was Disabled Because a Bootloop was Detected." >> "$MODULE_PROP"
    fi
}
permissions() {
    for dir in /data/adb/post-fs-data.d /data/adb/service.d; do
        if [ -d "$dir" ]; then
            find "$dir" -type f -exec chmod 644 {} \;
        fi
    done
}
if [ -f "$DIR/s1" ] && [ -f "$DIR/s2" ] && [ -f "$DIR/s3" ]; then
    rm -f "$DIR/s1" "$DIR/s2" "$DIR/s3"
    for module_dir in /data/adb/modules/*/; do
        touch "$module_dir/disable"
    done
    permissions
    description
    reboot
elif [ -f "$DIR/s2" ]; then
    touch "$DIR/s3"
elif [ -f "$DIR/s1" ]; then
    touch "$DIR/s2"
else
    touch "$DIR/s1"
fi
