#!/bin/bash
# cont.22 fallback when full m droid ninja is stuck loading the graph:
# surgical m of power-service.example + WM Shell / SystemUI / services, then pack.
set +u
LOG=~/p2_cont22_surgical.log
exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2:cont22 surgical start $(date -Is)"

# Stop stuck full-tree ninja/soong from cont22 m droid (only markxu's aosp16 tree).
pkill -u markxu -f 'scripts/g1_build_stable.sh' 2>/dev/null || true
pkill -u markxu -f 'p2_cont22_await' 2>/dev/null || true
# soong_ui / ninja for OUT_DIR=out_nxt_Baklava64 only — do not touch henry's out_nxt
for p in $(pgrep -u markxu -f 'soong_ui.*out_nxt_Baklava64|ninja -d keepdepfile.*combined-bst_x86_64' 2>/dev/null); do
  echo "killing pid=$p $(ps -o args= -p $p | head -c 120)"
  kill "$p" 2>/dev/null || true
done
sleep 5
# force-kill leftovers
for p in $(pgrep -u markxu -f 'soong_ui.*out_nxt_Baklava64|ninja -d keepdepfile.*combined-bst_x86_64' 2>/dev/null); do
  echo "SIGKILL pid=$p"
  kill -9 "$p" 2>/dev/null || true
done
sleep 2

export OUT_DIR=out_nxt_Baklava64
export BUILD_EMULATOR_OPENGL=true
cd ~/aosp16 || exit 1
# envsetup needs unset -u
set +u
source build/envsetup.sh
lunch bst_x86_64-bp2a-userdebug

echo "A16DBG:P2: surgical m power HAL + shell stack $(date -Is)"
# power AIDL example (performance_hint sessions)
m android.hardware.power-service.example
echo "power_rc=$?"

# WM Shell (Transitions) + SystemUI + framework services (DisplayRotation rides)
m WindowManager-Shell SystemUI services
echo "shell_stack_rc=$?"

# Also ensure vendor image gets the HAL if product packages install to vendor
m vendorimage-nodeps 2>/dev/null || m vendorimage || echo "WARN: vendorimage skipped rc=$?"

echo "A16DBG:P2: cont22 surgical DONE rc_power+shell above $(date -Is)"

# Full pack path (stage → apks → make-sfs → pack_fast)
bash ~/bst-aosp/scripts/p2_cont22_pack.sh
echo "A16DBG:P2:cont22 surgical+pack finished $(date -Is)"
