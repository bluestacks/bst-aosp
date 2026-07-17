#!/bin/bash
# g1_build_pack.sh — G1 Phase 1 权威 build+pack+deploy+verify 编排器（对齐 buildscripts）。
# 单一入口：远程 build/pack（markxu@172.16.6.191）→ win deploy/verify。
# 流程见 patches/android-16/checkpoints/G1-RESTORE.md + docs/build-commands.md G1 节。
#
# 用法（Git Bash on win host）：
#   bash scripts/g1_build_pack.sh                # 全流程（build+pack+deploy+verify）
#   bash scripts/g1_build_pack.sh --no-build     # 跳过 m droid（调试提速，用现有 OUT）
#   bash scripts/g1_build_pack.sh --no-verify    # 跳过 boot_verify（只 pack+deploy）
#   bash scripts/g1_build_pack.sh --pack-only    # 只 stage+copy_apks+pack（不 build/deploy/verify）
#
# 调试约束：禁 m clean（g1_build.sh 用 installclean）+ 禁 apk 重编（g1_copy_bst_apks 用 prebuilt）。
set -uo pipefail
HOST=markxu@172.16.6.191
ARC=~/bst-aosp
ENG='C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64'

DO_BUILD=1; DO_VERIFY=1; DO_DEPLOY=1; DO_PACK=1
for a in "$@"; do
  case "$a" in
    --no-build)  DO_BUILD=0 ;;
    --no-verify) DO_VERIFY=0 ;;
    --no-deploy) DO_DEPLOY=0 ;;
    --pack-only) DO_BUILD=0; DO_DEPLOY=0; DO_VERIFY=0 ;;
    *) echo "unknown flag: $a"; exit 2 ;;
  esac
done

step(){ echo; echo "====[$(date +%H:%M:%S)] $* ===="; }

# --- 远程：build + pack ---
step "remote: g1_build.sh (m droid, Layer1)"
if [ "$DO_BUILD" = 1 ]; then
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_build.sh' || { echo "BUILD FAILED"; exit 1; }
else
  echo "  (skipped --no-build; 用现有 OUT)"
fi

step "remote: g1_build_libs.sh (hd guest + goldfish mmm)"
if [ "$DO_BUILD" = 1 ]; then
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_build_libs.sh' || { echo "BUILD_LIBS FAILED"; exit 1; }
else
  echo "  (skipped --no-build)"
fi

if [ "$DO_PACK" = 1 ]; then
  step "remote: g1_stage_system.sh (OUT dir fold)"
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_stage_system.sh' || { echo "STAGE FAILED"; exit 1; }

  step "remote: g1_copy_bst_apks.sh (gralloc/egl props + BST apk 预装 priv-app)"
  ssh "$HOST" 'bash ~/bst-aosp/scripts/g1_copy_bst_apks.sh' || { echo "COPY_APKS FAILED"; exit 1; }

  step "remote: r228-pack-root.sh (= buildscripts create_vdi pack)"
  ssh "$HOST" 'bash ~/r228-pack-root.sh' || { echo "PACK FAILED"; exit 1; }
  ssh "$HOST" 'md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd'
fi

# --- win：deploy + verify ---
if [ "$DO_DEPLOY" = 1 ]; then
  step "win: g1_win_deploy.ps1 (scp Root.vhd + md5 校验 + 备份替换)"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ARC/scripts/g1_win_deploy.ps1" || { echo "DEPLOY FAILED"; exit 1; }
  # 干净首启：Data_orig → Data.vhdx（勿删！VBox 需文件存在）
  step "win: fresh data (Data_orig.vhdx -> Data.vhdx)"
  powershell.exe -NoProfile -Command "Get-Process -Name 'HD-Player','BstkSVC','BstkVMMgr' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep 2; Copy-Item '$ENG\Data_orig.vhdx' '$ENG\Data.vhdx' -Force; Write-Host 'fresh Data.vhdx'" || true
fi

if [ "$DO_VERIFY" = 1 ]; then
  step "win: g1_boot_verify.ps1 (Layer2 boot oracle, [Ready] tag)"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ARC/scripts/g1_boot_verify.ps1" -TimeoutSec 600 || echo "VERIFY non-zero (查 log)"
fi

step "DONE. boot oracle 结果见上；详见 G1-RESTORE.md §6 + porting-log。"
