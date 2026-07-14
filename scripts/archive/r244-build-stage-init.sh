#!/bin/bash
# R244: build restored Henry-path init and stage to releases
set -eo pipefail
LOG=~/r244-m-init.log
cd ~/aosp16
exec > >(tee "$LOG") 2>&1
echo "=== R244 m init $(date) ==="
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
export OUT_DIR=out_nxt_Baklava64
touch system/core/init/builtins.cpp system/core/init/init.cpp system/core/init/service.cpp
set +e
m init -j"$(nproc)"
EC=$?
echo "m_init_exit=$EC"
if [ "$EC" -ne 0 ]; then
  echo "retry m init_second_stage"
  m init_second_stage -j"$(nproc)"
  EC=$?
  echo "m_init_second_stage_exit=$EC"
fi
set -e
INIT_OUT=out_nxt_Baklava64/soong/.intermediates/system/core/init/init_second_stage/android_x86_64/init
PROD=out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init
ls -la "$INIT_OUT" 2>/dev/null || true
ls -la "$PROD" 2>/dev/null || true
SRC="$PROD"
[ -f "$SRC" ] || SRC="$INIT_OUT"
[ -f "$SRC" ] || { echo "NO_INIT_BINARY"; exit 1; }
md5sum "$SRC"
echo "=== strings check ==="
if strings "$SRC" | grep -E 'R174 skip odsign|R174 skip init_user0|R173 skip wait_for_coldboot|skip exec \(vdc\)|BS bringup: skipping reboot|R173h skip critical'; then
  echo STRINGS_FAIL
  exit 2
fi
echo STRINGS_OK_HENRY_PATH
install -m 0755 "$SRC" ~/releases/Baklava64/system/bin/init
md5sum ~/releases/Baklava64/system/bin/init
echo STAGE_DONE
