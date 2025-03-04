- Whitelist ; The files `/data/adb/YABL/allowed-modules.txt` and `/data/adb/YABP/allowed-scripts.txt` can be used to customize the module disable behavior.

If a bootloop is detected, the modules listed in `allowed-modules.txt` will not be disabled, and the permissions of the scripts listed in `allowed-scripts.txt` will remain unchanged.

You can customize these files manually or use `webUI`
