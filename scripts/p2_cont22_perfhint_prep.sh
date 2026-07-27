#!/bin/bash
# Apply performance_hint HAL product package + optionally restore Shell Transitions.
# Usage: bash p2_cont22_perfhint.sh [--enable-transitions]
set +u
ENABLE_TRANS=0
[ "${1:-}" = "--enable-transitions" ] && ENABLE_TRANS=1
cd ~/aosp16

# Sync device mk from bst-aosp untracked (caller should scp first)
if [ -f ~/bst-aosp/patches/android-16/untracked-src/aosp16__device_bst_qvirt/bst_x86_64.mk ]; then
  cp -a ~/bst-aosp/patches/android-16/untracked-src/aosp16__device_bst_qvirt/bst_x86_64.mk device/bst/qvirt/
  cp -a ~/bst-aosp/patches/android-16/untracked-src/aosp16__device_bst_qvirt/bst_arm64.mk device/bst/qvirt/ 2>/dev/null || true
fi
grep -n 'power-service.example' device/bst/qvirt/bst_x86_64.mk || { echo MISSING_PKG; exit 1; }

TRANS=frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java
if [ "$ENABLE_TRANS" = "1" ]; then
  if grep -q 'ENABLE_SHELL_TRANSITIONS = false' "$TRANS"; then
    # restore true + keep BST note
    python3 - <<'PY'
from pathlib import Path
p = Path("frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java")
t = p.read_text()
old = """    // TEMP(R262) / BST bringup: disable shell transitions until BLAST commit fixed (stuck EXITING)
    public static final boolean ENABLE_SHELL_TRANSITIONS = false;"""
new = """    // A16DBG:P2:SHELL: re-enabled after android.hardware.power-service.example (performance_hint)
    public static final boolean ENABLE_SHELL_TRANSITIONS = true;"""
if old not in t:
    # fallback simpler replace
    t2 = t.replace(
        "public static final boolean ENABLE_SHELL_TRANSITIONS = false;",
        "public static final boolean ENABLE_SHELL_TRANSITIONS = true; // A16DBG:P2:SHELL perfhint",
        1,
    )
    if t2 == t:
        raise SystemExit("TRANS_PATCH_FAIL")
    p.write_text(t2)
else:
    p.write_text(t.replace(old, new, 1))
print("transitions_enabled")
PY
  else
    echo "transitions_already_true_or_unknown"
    grep -n 'ENABLE_SHELL_TRANSITIONS' "$TRANS" | head -5
  fi
fi

echo "A16DBG:P2: cont22 prepare done ENABLE_TRANS=$ENABLE_TRANS $(date -Is)"
