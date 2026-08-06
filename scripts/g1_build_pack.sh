#!/bin/bash
# Android-16 mainline build+pack+deploy+verify orchestrator.
# 单一入口：远程 build/pack（markxu@172.16.6.191）→ win deploy/verify。
# 流程见 patches/android-16/checkpoints/G1-RESTORE.md + docs/build-commands.md G1 节。
#
# 用法（Git Bash on win host）：
#   bash scripts/g1_build_pack.sh                # 全流程（build+pack+deploy+verify）
#   bash scripts/g1_build_pack.sh --no-build     # 跳过 m droid（调试提速，用现有 OUT）
#   bash scripts/g1_build_pack.sh --no-verify    # 跳过 boot_verify（只 pack+deploy）
#   bash scripts/g1_build_pack.sh --pack-only    # 只 stage+copy_apks+pack（不 build/deploy/verify）
#
# 调试约束：禁 m clean + 禁 apk 重编（g1_copy_bst_apks 用 prebuilt）。
set -uo pipefail
HOST="${BST_REMOTE_HOST:-markxu@172.16.6.191}"
ARC=~/bst-aosp

DO_BUILD=1; DO_VERIFY=1; DO_DEPLOY=1; DO_PACK=1; CHECK_ONLY=0
for a in "$@"; do
  case "$a" in
    --no-build)  DO_BUILD=0 ;;
    --no-verify) DO_VERIFY=0 ;;
    --no-deploy) DO_DEPLOY=0 ;;
    --pack-only) DO_BUILD=0; DO_DEPLOY=0; DO_VERIFY=0 ;;
    --check) CHECK_ONLY=1 ;;
    *) echo "unknown flag: $a"; exit 2 ;;
  esac
done
[ "$DO_DEPLOY" -eq 1 ] || [ "$DO_VERIFY" -eq 0 ] || {
  echo "--no-deploy cannot be combined with verification; add --no-verify" >&2
  exit 2
}

step(){ echo; echo "====[$(date +%H:%M:%S)] $* ===="; }

if [ "$CHECK_ONLY" = 1 ]; then
  step "remote: Android-16 identity and dependency preflight"
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_build_android16.sh --check'
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_build_libs.sh --check'
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_pack_root.sh --check'
  step "CHECK OK; no build, pack, deploy, or boot was started"
  exit 0
fi

# --- 远程：build + pack ---
step "remote: g1_build_app_player.sh (canonical Android-16 build + package)"
if [ "$DO_BUILD" = 1 ]; then
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_build_app_player.sh' || { echo "BUILD/PACK FAILED"; exit 1; }
else
  echo "  (skipped --no-build; 用现有 OUT)"
fi

if [ "$DO_PACK" = 1 ] && [ "$DO_BUILD" = 0 ]; then
  step "remote: g1_pack_root.sh (stage + APK + overlays + HAL policy + pack)"
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_pack_root.sh' || { echo "PACK FAILED"; exit 1; }
fi
if [ "$DO_PACK" = 1 ]; then
  ssh "$HOST" 'cat ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd.identity' ||
    { echo "PACK IDENTITY READBACK FAILED"; exit 1; }
fi

# --- win：deploy + verify ---
if [ "$DO_DEPLOY" = 1 ]; then
  step "win: g1_win_deploy.ps1 (scp Root.vhd + md5 校验 + 备份替换)"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ARC/scripts/g1_win_deploy.ps1" || { echo "DEPLOY FAILED"; exit 1; }
  # cont.31 之后的权威干净盘；Data_orig 是已禁用的空盘基线。
  step "win: reset data to verified wipe snapshot"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ARC/scripts/g1_reset_data_wipe.ps1" ||
    { echo "FRESH DATA RESET FAILED"; exit 1; }
fi

if [ "$DO_VERIFY" = 1 ]; then
  step "win: g1_boot_verify.ps1 (Layer2 boot oracle, [Ready] tag)"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ARC/scripts/g1_boot_verify.ps1" -TimeoutSec 600 || { echo "VERIFY FAILED"; exit 1; }
fi

step "DONE. boot oracle 结果见上；详见 G1-RESTORE.md §6 + porting-log。"
