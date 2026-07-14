#!/usr/bin/env python3
"""Mount runtime/i18n apex after system.sfs OR legacy mount (baklava64 Henry path)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

if "APEX_SRC=/system/apex" in t and "system.sfs apex block" in t:
    print("init.sh sfs apex mount already patched")
    raise SystemExit(0)

# Remove baklava apex + linkerconfig from inside else-only branch.
old_inner = """  # A16(baklava64): apex 不再是 flatten 目录, 而是 .apex 文件(payload=erofs, STORED, 偏移4096).
  # /system/bin/{sh,linkerconfig,...} 的解释器 /system/bin/linker64 指向 /apex/com.android.runtime,
  # 所以必须在使用任何 /system 动态二进制前, 把核心 apex 零拷贝 loop 挂载到 /apex/<name>.
  # 其余(尤其 .capex 压缩包)留给 Android init 阶段的 apexd 处理。
  if [ "$bstandroid" == "baklava64" ]; then
      APEX_SRC=/boot/android/android/system/apex
      # 注意: busybox 1.19.4 的 `losetup -f` 在第二次调用时会段错误,
      # 所以自己遍历 /sys/block/loopN/loop 找空闲 loop 设备(无该子目录=未占用)。
      find_free_loop()
      {
          n=0
          while [ $n -lt 16 ]; do
              if [ ! -d /sys/block/loop$n/loop ]; then
                  echo /dev/loop$n
                  return 0
              fi
              n=`expr $n + 1`
          done
          return 1
      }
      for apexname in com.android.runtime com.android.i18n; do
          apexfile=$APEX_SRC/$apexname.apex
          if [ -f "$apexfile" ]; then
              mkdir -p /apex/$apexname
              loopdev=`find_free_loop`
              losetup -o 4096 $loopdev "$apexfile"
              die_if_error "Cannot losetup apex $apexname on $loopdev"
              mount -t erofs -o ro $loopdev /apex/$apexname
              die_if_error "Cannot mount apex $apexname"
              echo "<0>A16DBG: mounted apex $apexname on $loopdev" > /dev/kmsg
          else
              log_echo "apex $apexname.apex not found, skip"
          fi
      done
  fi

\tif [ "$bstandroid" == "tiramisu64" ]; then
\t\tmkdir /linkerconfig
\t\t/system/bin/linkerconfig --target /linkerconfig
\tfi

\tif [ "$bstandroid" == "baklava64" ]; then
\t\tmkdir /linkerconfig
\t\t/system/bin/linkerconfig --target /linkerconfig
\t\techo "<0>A16DBG: linkerconfig rc=$?; ld.config=$(ls -l /linkerconfig/ld.config.txt 2>&1)" > /dev/kmsg
\tfi
fi"""

new_inner = """\tif [ "$bstandroid" == "tiramisu64" ]; then
\t\tmkdir /linkerconfig
\t\t/system/bin/linkerconfig --target /linkerconfig
\tfi
fi

# system.sfs apex block: pre-mount bootstrap apex from /system/apex (Henry Baklava64).
if [ "$bstandroid" == "baklava64" ]; then
      APEX_SRC=/system/apex
      find_free_loop()
      {
          n=0
          while [ $n -lt 16 ]; do
              if [ ! -d /sys/block/loop$n/loop ]; then
                  echo /dev/loop$n
                  return 0
              fi
              n=`expr $n + 1`
          done
          return 1
      }
      for apexname in com.android.runtime com.android.i18n; do
          apexfile=$APEX_SRC/$apexname.apex
          if [ -f "$apexfile" ]; then
              mkdir -p /apex/$apexname
              loopdev=`find_free_loop`
              losetup -o 4096 $loopdev "$apexfile"
              die_if_error "Cannot losetup apex $apexname on $loopdev"
              mount -t erofs -o ro $loopdev /apex/$apexname
              die_if_error "Cannot mount apex $apexname"
              echo "<0>A16DBG: mounted apex $apexname on $loopdev" > /dev/kmsg
          else
              log_echo "apex $apexname.apex not found, skip"
          fi
      done
      mkdir -p /linkerconfig/bootstrap /linkerconfig/default
      if [ -x /system/bin/linkerconfig ]; then
          /system/bin/linkerconfig --target /linkerconfig
          echo "<0>A16DBG: linkerconfig rc=$?; ld.config=$(ls -l /linkerconfig/ld.config.txt 2>&1)" > /dev/kmsg
      else
          echo "#" > /linkerconfig/bootstrap/ld.config.txt
          echo "#" > /linkerconfig/default/ld.config.txt
          echo "<0>A16DBG: linkerconfig stub for baklava64" > /dev/kmsg
      fi
fi"""

if old_inner not in t:
    raise SystemExit("init.sh inner apex block not found")
t = t.replace(old_inner, new_inner, 1)
p.write_text(t)
print("init.sh: system.sfs apex mount patched")
