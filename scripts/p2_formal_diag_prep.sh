#!/bin/bash
# Phase2 P0: formalize hwservicemanager DIAG removal
# Root cause (readback 2026-07-20): assemble_vintf forces target-level=LEGACY when
# PRODUCT_ENFORCE_VINTF_MANIFEST=false (AssembleVintf.cpp). Source has target-level=8.
# Proof: ENFORCE=true or VINTF_IGNORE=true => target-level=8 retained.
set -euo pipefail

AOSP=${AOSP:-$HOME/aosp16}
MK=$AOSP/device/bst/qvirt/bst_x86_64.mk
SVC=$AOSP/system/hwservicemanager/service.cpp
STAGE=${STAGE:-$HOME/releases/Baklava64/system}
LOG=$HOME/p2_diag_formal_$(date +%Y%m%d-%H%M%S).log

exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2: start formal DIAG fix log=$LOG"

# 1) Product override: claim VINTF enforce so assemble_vintf keeps target-level=8
#    (config.mk BST bringup forces false early; product assignment after inherit wins for soong)
if ! grep -q 'PRODUCT_ENFORCE_VINTF_MANIFEST := true' "$MK"; then
  # Replace misleading SHIPPING_API_LEVEL comment block with correct formal fix
  if grep -q 'PRODUCT_SHIPPING_API_LEVEL := 34' "$MK"; then
    sed -i 's/PRODUCT_SHIPPING_API_LEVEL := 34.*/PRODUCT_ENFORCE_VINTF_MANIFEST := true  # Phase2 formal: assemble_vintf keeps source target-level=8 (not legacy); enables hidl.manager max-level=8 at runtime -> hwsm survives w\/o DIAG/' "$MK"
  else
    cat >> "$MK" <<'EOF'

# Phase2 P0 formal (2026-07-20): keep device manifest target-level=8 through assemble_vintf.
# With ENFORCE=false, AssembleVintf.cpp forces Level::LEGACY (wipes source target-level=8).
# Proof: host assemble_vintf ENFORCE=true|IGNORE=true => target-level=8; ENFORCE=false => legacy.
PRODUCT_ENFORCE_VINTF_MANIFEST := true
EOF
  fi
fi
echo "A16DBG:P2: bst_x86_64.mk ENFORCE lines:"
grep -n 'PRODUCT_ENFORCE_VINTF_MANIFEST\|PRODUCT_SHIPPING_API_LEVEL\|PRODUCT_PROPERTY_OVERRIDES\|PRODUCT_PACKAGES' "$MK"

# 2) Restore service.cpp: remove DIAG if(false), restore transport==EMPTY check
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/hwservicemanager/service.cpp"
t = p.read_text()
old = '''    auto transport = android::hardware::getTransport(ServiceManager::descriptor, serviceName);
    ALOGI("A16DBG:HWSM transport=%d; DIAG bypass active (if(false) over EMPTY branch; VINTF hidl.manager max-level=8 INSUFFICIENT at runtime target-level=legacy -> keep DIAG temp_debt; Phase 2 formal fix = device manifest target-level)", (int)transport);
    if (false) /* BlueStacks DIAG temp_debt 2026-07-20: force HIDL supported. VINTF manifest(hidl.manager max-level=8) INSUFFICIENT at runtime — device manifest target-level=legacy filters it -> getTransport EMPTY -> hwservicemanager self-disables (verified 2026-07-20: disabled=true set + HAL SIGABRT 411). Phase 2 formal fix: change device manifest target-level OR device-side manifest, not framework max-level. */ {
        ALOGI("A16DBG:HWSM-DIAG-BYPASS active (transport==EMPTY bypassed; VINTF runtime insufficient at target-level=legacy)");
        ALOGI("HIDL is not supported on this device so hwservicemanager is not needed");'''
new = '''    auto transport = android::hardware::getTransport(ServiceManager::descriptor, serviceName);
    ALOGI("A16DBG:HWSM transport=%d (Phase2 formal: expect non-EMPTY when vendor manifest target-level=8)", (int)transport);
    if (transport == android::vintf::Transport::EMPTY) {
        ALOGI("A16DBG:HWSM-EMPTY transport==EMPTY -> disabling hwservicemanager (formal path; should not hit if target-level=8)");
        ALOGI("HIDL is not supported on this device so hwservicemanager is not needed");'''
if old not in t:
    if 'if (false)' in t and 'DIAG' in t:
        raise SystemExit('DIAG block present but pattern mismatch; abort')
    if 'transport == android::vintf::Transport::EMPTY' in t or 'transport == ::android::vintf::Transport::EMPTY' in t:
        print('service.cpp already formal (EMPTY check present)')
    else:
        # try upstream-ish pattern
        raise SystemExit('unexpected service.cpp state')
else:
    p.write_text(t.replace(old, new, 1))
    print('service.cpp DIAG removed; EMPTY check restored')
PY

# 3) Fast path verification WITHOUT full m droid:
#    - rebuild hwservicemanager only
#    - force staged vendor manifest target-level=8 (simulates ENFORCE=true assemble output)
#    - install new hwservicemanager into stage
echo "A16DBG:P2: mmm hwservicemanager"
cd "$AOSP"
# shellcheck disable=SC1091
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
mmm system/hwservicemanager -j$(nproc) | tee -a "$LOG"
echo "mmm_exit=${PIPESTATUS[0]}"

HWSM_OUT=$AOSP/out_nxt_Baklava64/target/product/qvirt/system/bin/hwservicemanager
if [ ! -f "$HWSM_OUT" ]; then
  # try system_ext or alternate
  HWSM_OUT=$(find "$AOSP/out_nxt_Baklava64/target/product/qvirt" -name hwservicemanager -type f 2>/dev/null | head -1)
fi
echo "HWSM_OUT=$HWSM_OUT"
ls -la "$HWSM_OUT"
md5sum "$HWSM_OUT"

# Stage updates
test -d "$STAGE"
cp -av "$HWSM_OUT" "$STAGE/bin/hwservicemanager"
# Also common path under system/
if [ -d "$STAGE/system/bin" ]; then
  cp -av "$HWSM_OUT" "$STAGE/system/bin/hwservicemanager"
fi

VMAN="$STAGE/vendor/etc/vintf/manifest.xml"
test -f "$VMAN"
cp -a "$VMAN" "$VMAN.bak.p2diag"
# Simulate assemble_vintf with ENFORCE=true
sed -i 's/target-level="legacy"/target-level="8"/' "$VMAN"
echo "A16DBG:P2: staged vendor manifest after sed:"
head -6 "$VMAN"
grep target-level "$VMAN" | head -1

echo "A16DBG:P2: formal prep DONE. Next: pack (r228) + deploy + boot verify"
echo "LOG=$LOG"
