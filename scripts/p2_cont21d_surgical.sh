#!/bin/bash
# Surgical cont.21d: rebuild services + libselinux only, then pack_fast.
# Full m droid deferred while host load >> 50 (henry iso_img).
set +u
exec > >(tee -a ~/p2_cont21d_surgical.log) 2>&1
echo "surgical_start $(date -Is) load=$(cut -d' ' -f1-3 /proc/loadavg)"

# Wait for load1 < 40 (max ~2h)
for i in $(seq 1 120); do
  load1=$(cut -d' ' -f1 /proc/loadavg)
  # bash float compare via awk
  ok=$(awk -v l="$load1" 'BEGIN{print (l+0 < 40) ? 1 : 0}')
  echo "wait_load load1=$load1 ok=$ok $(date -Is)"
  if [ "$ok" = "1" ]; then break; fi
  sleep 60
done

cd ~/aosp16
export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG: surgical m services libselinux $(date -Is)"
m services libselinux -j24
rc=$?
echo "A16DBG: surgical m rc=$rc $(date -Is)"
if [ "$rc" -ne 0 ]; then
  echo surgical_fail
  exit $rc
fi
# Install into product system/ if needed — m services should update framework jar
ls -la out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar
ls -la out_nxt_Baklava64/target/product/qvirt/system/lib64/libselinux.so

echo "A16DBG: pack_fast $(date -Is)"
bash ~/bst-aosp/scripts/p2_cont21_pack_fast.sh
prc=$?
echo "A16DBG: pack rc=$prc $(date -Is)"
ls -la ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
# md5 in background file to avoid blocking
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd > ~/p2_cont21d_root.md5 &
echo "surgical_done rc=$prc $(date -Is)"
exit $prc
