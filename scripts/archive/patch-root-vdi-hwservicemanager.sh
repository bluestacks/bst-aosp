#!/bin/bash
set -euo pipefail
VDI="$HOME/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vdi"
VHD="$HOME/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd"
UUID="54e9ad31-a169-4d5b-a0e0-705d62e96e71"

cat > /tmp/hwservicemanager.rc <<'EOF'
service hwservicemanager /system/system_ext/bin/hwservicemanager
    user system
    disabled
    group system readproc
    critical
    onrestart setprop hwservicemanager.ready false
    onrestart class_restart --only-enabled main
    onrestart class_restart --only-enabled hal
    onrestart class_restart --only-enabled early_hal
    task_profiles ServiceCapacityLow HighPerformance
    class animation
    shutdown critical

on property:hwservicemanager.disabled=true
    stop hwservicemanager
EOF

sudo modprobe nbd max_part=8
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sudo qemu-nbd --connect=/dev/nbd0 "$VDI"
sleep 3

sudo debugfs -w -R "rm android/system/etc/init/hw/hwservicemanager.rc" /dev/nbd0p1 2>/dev/null || true
sudo debugfs -w -f /tmp/hwservicemanager.rc -R "write /tmp/hwservicemanager.rc android/system/etc/init/hw/hwservicemanager.rc" /dev/nbd0p1

sudo debugfs -R "cat android/system/etc/init/hw/init.rc" /dev/nbd0p1 > /tmp/init.rc.patched
if ! grep -q 'hwservicemanager.rc' /tmp/init.rc.patched; then
    sed -i '/import \/system\/etc\/init\/hw\/init\.\${ro.zygote}.rc/a import /system/etc/init/hw/hwservicemanager.rc' /tmp/init.rc.patched
fi
sudo debugfs -w -f /tmp/init.rc.patched -R "write /tmp/init.rc.patched android/system/etc/init/hw/init.rc" /dev/nbd0p1

sudo qemu-nbd -d /dev/nbd0

echo "Converting VDI -> VHD..."
qemu-img convert -f vdi -O vpc "$VDI" "${VHD}.new"
VBoxManage internalcommands sethduuid "${VHD}.new" "$UUID"
mv -f "${VHD}.new" "$VHD"
ls -la "$VHD"
echo "DONE patch hwservicemanager"
