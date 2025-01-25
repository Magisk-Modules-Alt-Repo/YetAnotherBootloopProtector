# Yet Another Bootloop Protector.
- This module try to protect your device from bootloops and system ui failures caused by Magisk/KernelSU/APatch Modules.
-  Generally , This Module can fix these type of bootloops if their cause is Magisk Modules.
  1)  The device repeatedly restarts but may show the boot animation  before crashing and restarting again.
  2)  The device gets stuck at the boot animation and never progresses to the lock screen.
  3)  device boots successfully, but SystemUI fails to start, causing a black or unresponsive screen."

## Installation

- Flash it in `Magisk`,`KSU` or `Apatch`
- if you flash it in `custom recovery` , it will disable all the magisk/KSU/APatch modules for no reason. Flash it in `TWRP` only when necessary.


 ### Bootloop

- If a bootloop is detected, , it will automatically disable every Magisk/KSU/APatch module and set the permissions of all general scripts (scripts placed in `/data/adb/service.d` , `/data/adb/post-fs-data.d` `/data/adb/post-mount.d` and `/data/adb/boot-completed.d`) to 644

- You can manually enable each module, or you can use the action button. Using the action button will also set executable permissions `chmod +x` for all general scripts


##  Recovery
- Flashing this module in `TWRP` or `custom recoveries` will automatically disable all Magisk/KSU/APatch modules and general scripts. Your data partition should be accessible otherwise, it won't work.

- It may not work with all recoveries.



## How does it work?
• Each time the device fails to complete the boot, the module creates a "marker"
- No marker files: it creates the first marker (marker1).
- One marker file: it creates a second marker (marker2).
- Two marker files: it creates a third marker (marker3).
- When three markers are present, the module considers the device to be in a boot loop , and  it disables all Magisk modules by creating a disable file in each module's folder. This action prevents those modules from loading during the next boot, which may help the device boot correctly.
- The module waits for the boot to complete, checking every 5 seconds.
If the boot does not complete within a set timeout period (2 minutes by default), the module assumes there is a boot problem, disables all Magisk modules and general scrips, and reboots the device.
- The module also monitors the state of `zygote` during booting and disables all modules if unusual behavior is detected.

- 
## SystemUI Monitor (optional)

- some modules, especially `customization modules`, may sometimes cause SystemUI to crash. Enabling this could help in tracking and resolving such issues.
- You will be prompted to disable or enable system ui monitor while installing the module.
- if enabled , then The Module checks the status of the SystemUI process every 5 seconds.
- If SystemUI is not running, the module starts tracking it and if SystemUI remains inactive for more than 25  seconds , or if it crashes too often the module assumes a failure of the device and it `disables` all the magisk modules and general scripts and triggers a `reboot`

- To  `disable` the systemUi Monitor , you can create a file named `systemui.monitor.disable` in `/data/adb` or you can just run
```
su -c touch /data/adb/systemui.monitor.disable
```
to `enable` the systemui monitor , you can just remove that file, or you can run , (changes will take place after the next boot)
```
su -c rm -f /data/adb/systemui.monitor.disable
```

- Logs of this module will be found at `/data/local/tmp/service.log`
- you can run `rm -f /data/local/tmp/service.log` to clear the logs.


### Limitations 

- If the cause of the bootloop is not related to Magisk/KSU/APatch modules, this module won't help.
- If any modules directly modify system files, this module won't help.
- In cases where a module uses an incompatible `system.prop` or causes a bootloop during the early boot stages (post-fs-data), this module may not be able to disable it in time.

> In these cases , you can always flash it in TWRP to disable Modules 


---



[![Telegram](https://img.shields.io/badge/Telegram-Channel-blue?logo=telegram)](https://rhythmcache.t.me)


[![Download](https://img.shields.io/github/downloads/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector/total?label=Total%20Downloads&color=blue)](https://github.com/Magisk-Modules-Alt-Repo/YetAnotherBootloopProtector/releases)
