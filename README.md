# Yet Another Bootloop Protector.
- This module try to protect your device from bootloops amd system ui failures caused by Magisk Modules

## Logic

• Each time the device fails to complete the boot, the script creates a "marker"
## If the script finds:
- No marker files: it creates the first marker (marker1).
- One marker file: it creates a second marker (marker2).
- Two marker files: it creates a third marker (marker3).
- When three markers are present, the script considers the device to be in a boot loop.

- When three markers are present, the script disables all Magisk modules by creating a disable file in each module's folder. This action prevents those modules from loading during the next boot, which may help the device boot correctly.
After disabling the modules, the script deletes all marker files and reboots the device.

- The script waits for the boot to complete, checking every 5 seconds.
If the boot does not complete within a set timeout period (2 minutes by default), the script assumes there is a boot problem, disables all Magisk modules, and reboots the device to attempt a clean boot.



# SystemUI Monitor (optional)
- You will be prompted to disable or enable system ui monitor while installing the module.

- if enabled , then The Module checks the status of the SystemUI process every 5 seconds.
- If SystemUI is not running, the module starts tracking it and if SystemUI remains inactive for more than 40 seconds, the module assumes a failure of the device and it `disables` all the magisk modules and triggers a `reboot`

- To  `disable` the systemUi Monitor , you can create a file named `systemui.monitor.disable` in `/data/adb` or you can just run
```
su -c touch /data/adb/systemui.monitor.disable
```

to `enable` the systemui monitor , you can just remove that file, or you can run
```
su -c rm -f /data/adb/systemui.monitor.disable
```

### Logs
- Logs of this module will be found at `/data/local/tmp/service.log`
