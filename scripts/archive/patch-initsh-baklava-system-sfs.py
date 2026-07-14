#!/usr/bin/env python3
"""init.sh: henry system.sfs path + mount runtime/i18n from /system/apex after /system is up."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

# Strip baklava bind/loop else-only hacks; keep generic else for legacy directory images.
old_else_start = """else
\tlog_echo "Mounting system directory"
    mkdir -p system

\tif [ "$bstandroid" == "baklava64" ]; then
\t\t/boot/bin/busybox mount -o bind,ro /boot/android/android/system /system
\t\techo "<0>A16DBG: system bind mount; init_size=$(/boot/bin/busybox stat -c %s /system/bin/init 2>&1)" > /dev/kmsg
\telse
\t\tmount -o loop /boot/android/android/system system
\tfi
\tdie_if_error "Cannot mount system directory"

  if [ "$bstandroid" == "rvc64" ] || [ "$bstandroid" == "tiramisu64" ]; then
      ln -s /boot/android/android/system/apex/com.android.runtime /apex/com.android.runtime
  fi

  # A16(baklava64): apex 不再是 flatten 目录, 而是 .apex 文件(payload=erofs, STORED, 偏移4096).
  # /system/bin/{sh,linkerconfig,...} 的解释器 /system/bin/linker64 指向 /apex/com.android.runtime,
  # 所以必须在使用任何 /system 动态二进制前, 把核心 apex 零拷贝 loop 挂载到 /apex/<name>.
  # 其余(尤其 .capex 压缩包)留给 Android init 阶段的 apexd 处理。
  if [ "$bstandroid" == "baklava64" ]; then
      APEX_SRC=/boot/android/android/system/apex"""

new_else_start = """else
\tlog_echo "Mounting system directory"
\tmkdir -p system
\tmount -o loop /boot/android/android/system system
\tdie_if_error "Cannot mount system directory"

  if [ "$bstandroid" == "rvc64" ] || [ "$bstandroid" == "tiramisu64" ]; then
      ln -s /boot/android/android/system/apex/com.android.runtime /apex/com.android.runtime
  fi

\tif [ "$bstandroid" == "tiramisu64" ]; then
\t\tmkdir /linkerconfig
\t\t/apex/com.android.runtime/bin/linkerconfig --target /linkerconfig
\tfi
fi

# A16(baklava64): pre-mount bootstrap apex from /system/apex after system.sfs or legacy mount.
if [ "$bstandroid" == "baklava64" ]; then
      APEX_SRC=/system/apex"""

if "APEX_SRC=/system/apex" in t and "make-baklava-system-sfs" not in t:
    print("init.sh apex-on-system already patched")
elif old_else_start not in t:
    raise SystemExit("init.sh else/apex block not found — manual merge needed")
else:
    t = t.replace(old_else_start, new_else_start, 1)
    # Remove duplicate tiramisu linkerconfig + baklava stub still inside old closing fi
    t = t.replace(
        """\tif [ "$bstandroid" == "tiramisu64" ]; then
\t\tmkdir /linkerconfig
\t\t/apex/com.android.runtime/bin/linkerconfig --target /linkerconfig
\tfi

\tif [ "$bstandroid" == "baklava64" ]; then
\t\tmkdir -p /linkerconfig/bootstrap /linkerconfig/default
\t\techo "#" > /linkerconfig/bootstrap/ld.config.txt
\t\techo "#" > /linkerconfig/default/ld.config.txt
\t\techo "<0>A16DBG: linkerconfig stub for baklava64" > /dev/kmsg
\tfi
fi""",
        """\tmkdir -p /linkerconfig/bootstrap /linkerconfig/default
\t\techo "#" > /linkerconfig/bootstrap/ld.config.txt
\t\techo "#" > /linkerconfig/default/ld.config.txt
\t\techo "<0>A16DBG: linkerconfig stub for baklava64" > /dev/kmsg
fi""",
        1,
    )
    # Debug line: use wc -c (busybox 1.19 has no stat -c)
    t = t.replace(
        'sysinit=$(ls -l /system/bin/init 2>&1)',
        'sysinit=$(ls -l /system/bin/init 2>&1); init_bytes=$(wc -c < /system/bin/init 2>&1)',
        1,
    )
    p.write_text(t)
    print("init.sh: system.sfs apex path + init_bytes probe")
