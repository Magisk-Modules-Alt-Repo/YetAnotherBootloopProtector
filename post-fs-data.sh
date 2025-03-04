#!/bin/sh
DIR="${0%/*}"
file=/data/adb/YABP/allowed-modules.txt
file2=/data/adb/YABP/allowed-scripts.txt
allowed_modules=""
if [ -f "$file" ]; then
    while IFS= read -r line; do
        if [ "${line#\#}" != "$line" ] || [ -z "$line" ]; then
            continue
        else
            allowed_modules="$allowed_modules $line"
        fi
    done <"$file"
fi
allowed_scripts=""
if [ -f "$file2" ]; then
    while IFS= read -r line; do
        if [ "${line#\#}" != "$line" ] || [ -z "$line" ]; then
            continue
        else
            allowed_scripts="$allowed_scripts $line"
        fi
    done <"$file2"
fi
permissions() {
    for dir in /data/adb/post-fs-data.d /data/adb/service.d /data/adb/post-mount.d /data/adb/boot-completed.d; do
        if [ -d "$dir" ]; then
            # First process non-hidden files
            for script in "$dir"/*; do
                if [ -f "$script" ]; then
                    script_name=$(basename "$script")
                    if [ "$script_name" = ".status.sh" ]; then
                        continue
                    else
                        if [ -n "$(echo " $allowed_scripts " | grep " $script_name ")" ]; then
                            continue
                        else
                            chmod 644 "$script"
                        fi
                    fi
                fi
            done
            for script in "$dir"/.*; do
                if [ -f "$script" ] && [ "$(basename "$script")" != "." ] && [ "$(basename "$script")" != ".." ]; then
                    script_name=$(basename "$script")
                    if [ "$script_name" = ".status.sh" ]; then
                        continue
                    else
                        if [ -n "$(echo " $allowed_scripts " | grep " $script_name ")" ]; then
                            continue
                        else
                            chmod 644 "$script"
                        fi
                    fi
                fi
            done
        fi
    done
}
if [ -f "$DIR/s1" ] && [ -f "$DIR/s2" ] && [ -f "$DIR/s3" ]; then
    rm -f "$DIR/s1" "$DIR/s2" "$DIR/s3"
    for module_dir in /data/adb/modules/*/; do
        module_name=$(basename "$module_dir")
        if [ -n "$(echo " $allowed_modules " | grep " $module_name ")" ]; then
            continue
        else
            if [ -d "$module_dir" ]; then
                touch "$module_dir/disable"
            fi
        fi
    done
    permissions
    reboot
elif [ -f "$DIR/s2" ]; then
    touch "$DIR/s3"
elif [ -f "$DIR/s1" ]; then
    touch "$DIR/s2"
else
    touch "$DIR/s1"
fi    
