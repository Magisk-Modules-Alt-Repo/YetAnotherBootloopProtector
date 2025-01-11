# Yet Another Bootloop Protector.
- This module try to protect your device from bootloops and system ui failures caused by Magisk/KernelSU/APatch Modules


## How does it work?
• Each time the device fails to complete the boot, the module creates a "marker"

- No marker files: it creates the first marker (marker1).
- One marker file: it creates a second marker (marker2).
- Two marker files: it creates a third marker (marker3).
- When three markers are present, the module considers the device to be in a boot loop , and  it disables all Magisk modules by creating a disable file in each module's folder. This action prevents those modules from loading during the next boot, which may help the device boot correctly.

- The module waits for the boot to complete, checking every 5 seconds.
If the boot does not complete within a set timeout period (2 minutes by default), the module assumes there is a boot problem, disables all Magisk modules, and reboots the device.



# SystemUI Monitor (optional)
- You will be prompted to disable or enable system ui monitor while installing the module.

- if enabled , then The Module checks the status of the SystemUI process every 5 seconds.
- If SystemUI is not running, the module starts tracking it and if SystemUI remains inactive for more than 40 seconds, the module assumes a failure of the device and it `disables` all the magisk modules and triggers a `reboot`

- To  `disable` the systemUi Monitor , you can create a file named `systemui.monitor.disable` in `/data/adb` or you can just run
```
su -c touch /data/adb/systemui.monitor.disable
```

to `enable` the systemui monitor , you can just remove that file, or you can run , (changes will take place after the next boot)
```
su -c rm -f /data/adb/systemui.monitor.disable
```

- You can enable or disable all modules by clicking on action button in Magisk/KSU

### Logs
- Logs of this module will be found at `/data/local/tmp/service.log`
- you can run `rm -f /data/local/tmp/service.log` to clear the logs.

---
[![Download](https://img.shields.io/github/downloads/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector/total?label=Total%20Downloads&color=blue)](https://github.com/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector/releases)

