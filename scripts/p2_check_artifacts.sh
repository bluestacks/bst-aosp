#!/bin/bash
set +u
cd ~/aosp16
echo "=== enabled.c ==="
sed -n '1,40p' external/selinux/libselinux/src/enabled.c
echo "=== product services.jar mtime ==="
ls -la out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar 2>/dev/null
ls -la out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar.prof 2>/dev/null
echo "=== libselinux ==="
ls -la out_nxt_Baklava64/target/product/qvirt/system/lib64/libselinux.so 2>/dev/null
# strings check for is_selinux_enabled behavior hard; show file from intermediates
ls -la out_nxt_Baklava64/soong/.intermediates/external/selinux/libselinux/libselinux/android_x86_64_shared*/unstripped/libselinux.so 2>/dev/null | head -5
echo "=== DisplayRotation class in services? ==="
# unzip -l may be slow; try jar tf limited
if [ -f out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar ]; then
  jar tf out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar 2>/dev/null | rg 'DisplayRotation' | head -5
fi
echo "=== system/ dir vs img ==="
ls -la out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar out_nxt_Baklava64/target/product/qvirt/system.img 2>/dev/null
