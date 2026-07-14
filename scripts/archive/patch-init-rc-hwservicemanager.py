#!/usr/bin/env python3
import subprocess
from pathlib import Path

vdi = Path.home() / "releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vdi"
import_line = "import /system/etc/init/hw/hwservicemanager.rc"

subprocess.run(["sudo", "modprobe", "nbd", "max_part=8"], check=False)
subprocess.run(["sudo", "qemu-nbd", "-d", "/dev/nbd0"], check=False)
subprocess.run(["sudo", "qemu-nbd", "--connect=/dev/nbd0", str(vdi)], check=True)
import time
time.sleep(3)

subprocess.run(
    ["sudo", "debugfs", "-R", "cat android/system/etc/init/hw/init.rc", "/dev/nbd0p1"],
    check=True,
    stdout=open("/tmp/init.rc.patched", "w"),
)
t = Path("/tmp/init.rc.patched").read_text()
needle = "import /system/etc/init/hw/init.${ro.zygote}.rc\n"
if import_line not in t:
    if needle not in t:
        raise SystemExit("needle not found in init.rc")
    t = t.replace(needle, needle + import_line + "\n")
    Path("/tmp/init.rc.patched").write_text(t)

subprocess.run(["sudo", "debugfs", "-w", "-R", "rm android/system/etc/init/hw/init.rc", "/dev/nbd0p1"], check=True)
subprocess.run(
    ["sudo", "debugfs", "-w", "-f", "/tmp/init.rc.patched", "-R",
     "write /tmp/init.rc.patched android/system/etc/init/hw/init.rc", "/dev/nbd0p1"],
    check=True,
)
subprocess.run(["sudo", "qemu-nbd", "-d", "/dev/nbd0"], check=True)
print("init.rc patched OK")
print(Path("/tmp/init.rc.patched").read_text().splitlines()[6:14])
