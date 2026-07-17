#!/bin/bash
# G1 Layer1: build bst_x86_64 via `m droid` (FULL build, like M1 RESTORE §6.1).
# Why `m droid` not `m systemimage`: G1 systemimage systematically MISSED vendor + system_ext
# content that M1's m droid included — vndservicemanager (vendor:true), VINTF manifests,
# system_ext HIDL allocator/memory, etc. (165-file M1-vs-G1 diff, see checkpoints/G1-m1-diff-missing.txt).
# m droid builds the full device (system + vendor + system_ext folded into system.img for the
# generic/qvirt single-partition layout) so all of it lands in the staged system.img.
cd ~/aosp16
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:G1: build start (m droid) $(date -Is)"
m droid -j24
rc=$?
# M1 boot 依赖显式 goldfish mmm（EGL/gralloc/hwcomposer 即使 m droid 也不在默认闭包内，见 RESTORE §6.1）
if [ "$rc" -eq 0 ]; then
  echo "A16DBG:G1: mmm goldfish-opengl-pie (graphics chain)"
  mmm ../ggl/goldfish-opengl-pie BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true -j24 || rc=$?
fi
echo "A16DBG:G1: build exit rc=$rc $(date -Is)"
IMG=out_nxt_Baklava64/target/product/qvirt/system.img
INST=out_nxt_Baklava64/target/product/qvirt/installed-files.txt
ls -la "$IMG" "$INST" 2>&1
echo "A16DBG:G1: system.img md5 $(md5sum "$IMG" 2>/dev/null)"
echo "A16DBG:G1: verify vendor/system_ext folded into system.img:"
ls out_nxt_Baklava64/target/product/qvirt/system/vendor/bin/vndservicemanager 2>/dev/null && echo "  vndservicemanager IN system.img (folded)" || echo "  WARN: vndservicemanager NOT in system.img — vendor may be separate partition (need folding)"
echo "A16DBG:G1: DONE rc=$rc"
