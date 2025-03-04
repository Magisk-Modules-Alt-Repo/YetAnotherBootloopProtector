let isEnvironmentSupported = false;    
        function getUniqueCallbackName(prefix) {
            return `${prefix}_${Math.random().toString(36).substr(2, 9)}`;
        }
        async function exec(command) {
            return new Promise((resolve, reject) => {
                const callbackName = getUniqueCallbackName('exec');
                window[callbackName] = (errno, stdout, stderr) => {
                    resolve({ errno, stdout: stdout.trim(), stderr });
                    delete window[callbackName];
                };
                try {
                    ksu.exec(command, '{}', callbackName);
                } catch (error) {
                    reject(error);
                    delete window[callbackName];
                }
            });
        }
        function showConfirmDialog(title, message, onConfirm) {
            const dialog = document.getElementById('confirmDialog');
            document.getElementById('confirmTitle').textContent = title;
            document.getElementById('confirmMessage').textContent = message;
            
            document.getElementById('confirmYes').onclick = () => {
                onConfirm();
                dialog.style.display = 'none';
            };
            
            document.getElementById('confirmNo').onclick = () => {
                dialog.style.display = 'none';
            };
            
            dialog.style.display = 'flex';
        }
        async function toggleMonitor() {
    const monitorFile = "/data/adb/systemui.monitor.disable";
    const monitorStatus = document.getElementById('monitorStatus');

    const { stdout: exists } = await exec(`[ -f "${monitorFile}" ] && echo "yes" || echo "no"`);
    
    if (exists === "yes") {
        await exec(`rm "${monitorFile}"`);
        monitorStatus.textContent = "ENABLED";
        monitorStatus.className = "btn btn-success";
    } else {
        await exec(`touch "${monitorFile}"`);
        monitorStatus.textContent = "DISABLED";
        monitorStatus.className = "btn btn-danger";
    }
    alert("Change will take effect after reboot.");
}
        async function restartSystemUI() {
            showConfirmDialog(
                "Restart SystemUI",
                "Are you sure you want to restart SystemUI?",
                async () => {
                    try {
                        await exec('kill $(pidof com.android.systemui)');
                        alert("SystemUI restarted");
                        setTimeout(updateStatus, 2000);
                    } catch (error) {
                        alert("Failed to restart SystemUI");
                    }
                }
            );
        }
async function openAllowedModulesDialog() {
    await exec('mkdir -p /data/adb/YABP && [ ! -f /data/adb/YABP/allowed-modules.txt ] && touch /data/adb/YABP/allowed-modules.txt');
    const { stdout: modules } = await exec('ls /data/adb/modules 2>/dev/null || echo ""');
    const { stdout: allowed } = await exec('cat /data/adb/YABP/allowed-modules.txt || echo ""');
    const allowedModules = allowed.split("\n");

    let html = "";
    modules.split("\n").forEach(module => {
        if (!module.trim()) return;
        const checked = allowedModules.includes(module) ? "checked" : "";
        html += `<label><input type="checkbox" value="${module}" ${checked}> ${module}</label><br>`;
    });

    document.getElementById("allowedModulesList").innerHTML = html;
    document.getElementById("allowedModulesDialog").style.display = "flex";
}
async function openAllowedScriptsDialog() {
    const scriptDirs = [
        "/data/adb/service.d",
        "/data/adb/post-fs-data.d",
        "/data/adb/post-mount.d",
        "/data/adb/boot-completed.d"
    ];
    await exec('mkdir -p /data/adb/YABP && [ ! -f /data/adb/YABP/allowed-scripts.txt ] && touch /data/adb/YABP/allowed-scripts.txt');

    const { stdout: allowed } = await exec('cat /data/adb/YABP/allowed-scripts.txt || echo ""');
    const allowedScripts = allowed.split("\n");

    let html = "";
    for (const dir of scriptDirs) {
        const { stdout: scripts } = await exec(`[ -d "${dir}" ] && ls -A "${dir}" 2>/dev/null || echo ""`);
        if (!scripts.trim()) continue;

        html += `<h3>${dir.replace("/data/adb/", "").toUpperCase()}</h3>`;
        scripts.split("\n").forEach(script => {
            if (!script.trim() || script === ".status.sh") return;
            const checked = allowedScripts.includes(script) ? "checked" : "";
            html += `<label><input type="checkbox" value="${script}" ${checked}> ${script}</label><br>`;
        });
    }

    document.getElementById("allowedScriptsList").innerHTML = html;
    document.getElementById("allowedScriptsDialog").style.display = "flex";
}

async function saveAllowedScripts() {
    const { stdout: existingContent } = await exec('cat /data/adb/YABP/allowed-scripts.txt 2>/dev/null || echo ""');
    const commentLines = existingContent
        .split("\n")
        .filter(line => line.trim().startsWith('#'));
    const selectedScripts = Array.from(document.querySelectorAll("#allowedScriptsList input:checked"))
        .map(input => input.value);
    const finalContent = [...commentLines, ...selectedScripts].join("\n");

    await exec('mkdir -p /data/adb/YABP && touch /data/adb/YABP/allowed-scripts.txt');
    await exec(`echo "${finalContent}" > /data/adb/YABP/allowed-scripts.txt`);
    document.getElementById("allowedScriptsDialog").style.display = "none";
}


async function saveAllowedModules() {
    const { stdout: existingContent } = await exec('cat /data/adb/YABP/allowed-modules.txt 2>/dev/null || echo ""');
    const commentLines = existingContent
        .split("\n")
        .filter(line => line.trim().startsWith('#'));
    const selectedModules = Array.from(document.querySelectorAll("#allowedModulesList input:checked"))
        .map(input => input.value);
    const finalContent = [...commentLines, ...selectedModules].join("\n");
    
    await exec('mkdir -p /data/adb/YABP && touch /data/adb/YABP/allowed-modules.txt');
    await exec(`echo "${finalContent}" > /data/adb/YABP/allowed-modules.txt`);
    document.getElementById("allowedModulesDialog").style.display = "none";
}



function closeAllowedModulesDialog() {
    document.getElementById("allowedModulesDialog").style.display = "none";
}

function closeAllowedScriptsDialog() {
    document.getElementById("allowedScriptsDialog").style.display = "none";
}
        async function disableAllModules() {
            showConfirmDialog(
                "Disable All Modules",
                "Are you sure you want to disable all modules?",
                async () => {
                    try {
                        await exec(`
                            for module in /data/adb/modules/*; do
                                if [ -d "$module" ]; then
                                    touch "$module/disable"
                                fi
                            done
                        `);
                        alert("All modules disabled");
                    } catch (error) {
                        alert("Failed to disable modules");
                    }
                }
            );
        }
        async function getRootMethod() {
    try {
        const { stdout: ksudOut } = await exec("su -c 'ksud debug version | sed s/Kernel\\ Version://g'");
        const { stdout: apdOut } = await exec("su -c apd --version");
        const { stdout: magiskOut } = await exec("magisk -V");
        let methods = [];
        if (ksudOut.trim()) {
            methods.push(`KernelSU (${ksudOut.trim()})`);
        }
        if (apdOut.includes('apd')) {
            methods.push(`APatch (${apdOut.replace('apd', '').trim()})`);
        }
        if (magiskOut.trim()) {
            methods.push(`Magisk (${magiskOut.trim()})`);
        }
        const rootMethod = methods.length ? methods.join(', ') : 'Error Detecting';
        document.getElementById('rootMethod').textContent = rootMethod;
    } catch (error) {
        console.error('Error detecting root method:', error);
        document.getElementById('rootMethod').textContent = 'Error Detecting';
    }
}
        async function getSystemInfo() {
    try {
        const { stdout: abi } = await exec('getprop ro.product.cpu.abi');
        const deviceAbi = abi.trim();
        document.getElementById('deviceAbi').textContent = deviceAbi;
        const { stdout: androidVer } = await exec('getprop ro.build.version.release');
        const { stdout: sdkVer } = await exec('getprop ro.build.version.sdk');
        document.getElementById('androidVersion').textContent = `${androidVer.trim()} (API ${sdkVer.trim()})`;
        const { stdout: kernel } = await exec('uname -r');
        document.getElementById('kernelVersion').textContent = kernel.trim();
        if (deviceAbi.includes('64')) {
            document.getElementById('zygote32Pid').style.display = 'inline';
            document.getElementById('zygote64Pid').style.display = 'inline';
        } else {
            document.getElementById('zygote32Pid').style.display = 'inline';
            document.getElementById('zygote64Pid').style.display = 'none';
        }
    } catch (error) {
        console.error('Error getting system info:', error);
    }
}
async function enableAllModules() {
    showConfirmDialog(
        "Enable All Modules",
        "Are you sure you want to enable all modules?",
        async () => {
            try {
                await exec(`
                    for module in /data/adb/modules/*; do
                        if [ -d "$module" ]; then
                            rm -f "$module/disable"
                        fi
                    done

                    for dir in /data/adb/post-fs-data.d /data/adb/service.d /data/adb/post-mount.d /data/adb/boot-completed.d; do
                        if [ -d "$dir" ]; then
                            find "$dir" -type f -exec chmod +x {} \\;
                        fi
                    done
                `);
                alert("All modules enabled. All scripts made executable.");
            } catch (error) {
                alert("Failed to enable modules.");
            }
        }
    );
}
        async function initializeEnvironment() {
    try {
        if (typeof ksu === 'undefined' && typeof mmrl === 'undefined' && typeof $YetAnotherBootloopProtector === 'undefined') {
            isEnvironmentSupported = false;
            alert("Unsupported environment");
            return;
        }

        if (typeof ksu === 'undefined' || !ksu.exec) {
            isEnvironmentSupported = false;

            if (typeof mmrl !== 'undefined' && typeof $YetAnotherBootloopProtector !== 'undefined') {
                const ksuDialog = document.getElementById('ksuDialog');
                ksuDialog.style.display = 'flex';

                const requestKsuApiButton = document.getElementById('requestKsuApiButton');
                requestKsuApiButton.onclick = async () => {
                    try {
                        await $YetAnotherBootloopProtector.requestAdvancedKernelSUAPI();
                        alert("KernelSU API access granted!");
                        ksuDialog.style.display = 'none';
                        document.body.style.display = "block"; 
                        
                        setTimeout(() => {
                            initializeEnvironment();
                        }, 1000);
                    } catch (error) {
                        console.error("Error requesting KernelSU API:", error);
                        alert("Failed to request KernelSU API access.");
                    }
                };
            }
            return;
        }

        const { errno } = await exec('id');
        isEnvironmentSupported = errno === 0;

        if (isEnvironmentSupported) {
            updateStatus();
            setInterval(updateStatus, 5000);
        }
    } catch (error) {
        console.error("Error initializing environment:", error);
        isEnvironmentSupported = false;
    }
}
        async function updateStatus() {
            if (!isEnvironmentSupported) return;
            try {
                await getSystemInfo();
                await getRootMethod();
                const { stdout: installedCount } = await exec(`
                    find /data/adb/modules -mindepth 1 -maxdepth 1 -type d -exec sh -c 'test -f "$1/module.prop" && echo "$1"' _ {} \\; | wc -l
                `);
                document.getElementById('installedModules').textContent = installedCount.trim();
                const { stdout: disabledCount } = await exec(`
                    find /data/adb/modules -mindepth 1 -maxdepth 1 -type d -exec sh -c 'test -f "$1/disable" && echo "$1"' _ {} \\; | wc -l
                `);
                document.getElementById('disabledModules').textContent = disabledCount.trim();
                const { stdout: version } = await exec('grep version= /data/adb/modules/YetAnotherBootloopProtector/module.prop');
                document.getElementById('moduleVersion').textContent = version ? version.replace('version=', 'v') : 'Unknown';
                const { stdout: systemuiPid } = await exec('pidof com.android.systemui');
                document.getElementById('systemuiPid').textContent = systemuiPid || 'Not running';
                const { stdout: monitorExists } = await exec('[ -f "/data/adb/systemui.monitor.disable" ] && echo "disabled" || echo "enabled"');
                const monitorStatus = document.getElementById('monitorStatus');
                monitorStatus.textContent = monitorExists.toUpperCase();
                monitorStatus.className = `btn btn-small ${monitorExists === 'enabled' ? 'btn-success' : 'btn-danger'}`;
                const { stdout: abi } = await exec('getprop ro.product.cpu.abi');
                const is64Bit = abi.includes('64');
                const { stdout: zygote32Pid } = await exec('pidof zygote');
                const { stdout: zygote64Pid } = await exec('pidof zygote64');
                document.getElementById('zygote32Pid').textContent = zygote32Pid || 'Not running';
                if (is64Bit) {
                    document.getElementById('zygote64Pid').textContent = zygote64Pid || 'Not running';
                    document.getElementById('zygote64Row').style.display = 'flex';
                } else {
                    document.getElementById('zygote64Row').style.display = 'none';
                }
                const { stdout: logSize } = await exec('du -h /data/local/tmp/service.log | cut -f1');
                document.getElementById('logSize').textContent = logSize.trim() || '0B';
            } catch (error) {
                console.error('Error updating status:', error);
                alert("Error fetching system status.");
            }
        }
async function viewLogs() {
    try {
        const { stdout: logs } = await exec('cat /data/local/tmp/service.log');

        if (!logs.trim()) {
            document.getElementById('logContent').innerHTML = 'No logs found';
        } else {
            const formattedLogs = logs
                .split('\n')
                .map(line => `<div class="log-line">${line}</div>`)
                .join('');

            document.getElementById('logContent').innerHTML = formattedLogs;
        }
        document.getElementById('logDialog').style.display = 'flex';
    } catch (error) {
        alert('Error reading logs');
    }
}
        async function clearLogs() {
            showConfirmDialog(
                "Clear Logs",
                "Are you sure you want to clear all logs?",
                async () => {
                    try {
                        await exec('echo "" > /data/local/tmp/service.log');
                        alert('Logs cleared successfully');
                        updateStatus();
                    } catch (error) {
                        alert('Error clearing logs');
                    }
                }
            );
        }
        function closeLogDialog() {
            document.getElementById('logDialog').style.display = 'none';
        }
        document.addEventListener('click', (event) => {
            const dialogs = document.querySelectorAll('.dialog, .confirm-dialog');
            dialogs.forEach(dialog => {
                if (event.target === dialog) {
                    dialog.style.display = 'none';
                }
            });
        });
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                const dialogs = document.querySelectorAll('.dialog, .confirm-dialog');
                dialogs.forEach(dialog => {
                    dialog.style.display = 'none';
                });
            }
        });
        function alert(message) {
            if (typeof ksu !== 'undefined' && ksu.toast) {
                ksu.toast(message);
            } else {
                console.log(`Toast: ${message}`);
            }
        }
        function openLink(url) {
            if (typeof ksu !== 'undefined' && ksu.exec) {
                ksu.exec(`am start -a android.intent.action.VIEW -d "${url}"`, '{}', 'openLink_callback');
            } else {
                window.open(url, '_blank');
            }
        }
        initializeEnvironment();
