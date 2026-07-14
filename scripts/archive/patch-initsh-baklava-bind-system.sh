#!/bin/bash
# baklava64 Root.fs has android/system as directory tree, not loop image
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()
target = """\tif [ "$bstandroid" == "baklava64" ]; then
\t\t/boot/bin/busybox mount -o bind,ro /boot/android/android/system /system
\t\techo "<0>A16DBG: system bind mount; init_size=$(/boot/bin/busybox stat -c %s /system/bin/init 2>&1)" > /dev/kmsg
\telse
\t\tmount -o loop /boot/android/android/system system
\tfi
\tdie_if_error "Cannot mount system directory\""""
if "busybox mount -o bind,ro" in t:
    print("init.sh busybox bind mount already present")
else:
  t = t.replace("mount --bind /boot/android/android/system system",
                "/boot/bin/busybox mount -o bind,ro /boot/android/android/system /system")
  old = """\tmount -o loop /boot/android/android/system system
\tdie_if_error "Cannot mount system directory\""""
  if target.split("else")[0] not in t and old in t:
    t = t.replace(old, target, 1)
  elif "mount --bind" in t:
    t = t.replace(
      """\tif [ "$bstandroid" == "baklava64" ]; then
\t\tmount --bind /boot/android/android/system system
\telse
\t\tmount -o loop /boot/android/android/system system
\tfi
\tdie_if_error "Cannot mount system directory\"""",
      target, 1)
  if "busybox mount -o bind,ro" not in t:
    raise SystemExit("failed to patch init.sh bind mount")
  if "init_size=" not in t:
    t = t.replace(
      "\t\t/boot/bin/busybox mount -o bind,ro /boot/android/android/system /system",
      "\t\t/boot/bin/busybox mount -o bind,ro /boot/android/android/system /system\n"
      "\t\techo \"<0>A16DBG: system bind mount; init_size=$(/boot/bin/busybox stat -c %s /system/bin/init 2>&1)\" > /dev/kmsg",
      1)
  p.write_text(t)
  print("init.sh: busybox bind,ro mount + stat probe")
PY
