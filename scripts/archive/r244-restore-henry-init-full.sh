#!/bin/bash
# R244: Restore Henry/stock init control flow (no bringup skips).
# Removes: R174 odsign wait skips, vdc exec skip, R173 coldboot wait skip,
#          BS reboot_on_failure skips.
# Then rebuilds init_second_stage and stages into releases/Baklava64.
set -euo pipefail
AOSP=~/aosp16
OUT=${OUT_DIR:-$AOSP/out_nxt_Baklava64}
OD=~/releases/Baklava64
LOG=~/r244-henry-init-restore.log
exec > >(tee "$LOG") 2>&1
echo "=== R244 Henry init full restore $(date) ==="

BP=$AOSP/system/core/init/builtins.cpp
IP=$AOSP/system/core/init/init.cpp
SP=$AOSP/system/core/init/service.cpp
TS=$(date +%H%M%S)
cp -a "$BP" "$BP.bak-r244full-$TS"
cp -a "$IP" "$IP.bak-r244full-$TS"
cp -a "$SP" "$SP.bak-r244full-$TS"

python3 - <<'PY'
from pathlib import Path
import re

# --- builtins.cpp ---
bp = Path.home() / "aosp16/system/core/init/builtins.cpp"
text = bp.read_text()

# Remove vdc skip one-liner at start of do_exec
text2, n_vdc = re.subn(
    r'(static Result<void> do_exec\(const BuiltinArguments& args\) \{\n)'
    r'    for \(const auto& a : args\.args\) \{ if \(a\.find\("/vdc"\).*?return \{\}; \}\n',
    r'\1',
    text,
    count=1,
    flags=re.S,
)
print(f"removed vdc skip n={n_vdc}")
if n_vdc != 1:
    # fallback: any line with skip exec (vdc)
    lines = text2.splitlines(True)
    out = []
    removed = 0
    for ln in lines:
        if 'skip exec' in ln and 'vdc' in ln:
            removed += 1
            continue
        if 'find("/vdc")' in ln and 'return {}' in ln:
            removed += 1
            continue
        out.append(ln)
    text2 = ''.join(out)
    print(f"vdc line-filter removed={removed}")

# Ensure odsign wait skips gone
lines = text2.splitlines(True)
out = []
for ln in lines:
    if 'strcmp(name, "odsign.verification.done")' in ln and 'return {}' in ln:
        continue
    if 'strcmp(name, "odsign.key.done")' in ln and 'return {}' in ln:
        continue
    if 'R174 skip odsign' in ln:
        continue
    out.append(ln)
text2 = ''.join(out)

# Ensure do_init_user0 is stock
pat_user0 = re.compile(
    r'static Result<void> do_init_user0\(const BuiltinArguments& args\) \{\n.*?\n\}',
    re.S,
)
stock_user0 = (
    'static Result<void> do_init_user0(const BuiltinArguments& args) {\n'
    '    return ExecVdcRebootOnFailure("init_user0");\n'
    '}'
)
m = pat_user0.search(text2)
if not m:
    raise SystemExit('do_init_user0 not found')
if 'ExecVdcRebootOnFailure("init_user0")' not in m.group(0):
    text2 = pat_user0.sub(stock_user0, text2, count=1)
    print('restored do_init_user0')
else:
    print('do_init_user0 already stock')

bp.write_text(text2)
assert 'find("/vdc")' not in bp.read_text() or 'do_exec' not in bp.read_text().split('find("/vdc")')[0][-200:]
# stronger: do_exec body must not contain vdc skip
exec_m = re.search(r'static Result<void> do_exec\(const BuiltinArguments& args\) \{(.*?)\n\}', bp.read_text(), re.S)
assert exec_m and 'vdc' not in exec_m.group(1), 'do_exec still mentions vdc'
print('builtins.cpp VERIFY_OK')

# --- init.cpp: restore wait_for_coldboot_done ---
ip = Path.home() / "aosp16/system/core/init/init.cpp"
it = ip.read_text()
stock_cold = '''static Result<void> wait_for_coldboot_done_action(const BuiltinArguments& args) {
    if (!prop_waiter_state.StartWaiting(kColdBootDoneProp, "true")) {
        LOG(FATAL) << "Could not wait for '" << kColdBootDoneProp << "'";
    }

    return {};
}'''
pat_cold = re.compile(
    r'static Result<void> wait_for_coldboot_done_action\(const BuiltinArguments& args\) \{.*?\n\}',
    re.S,
)
if not pat_cold.search(it):
    raise SystemExit('wait_for_coldboot_done_action not found')
it2 = pat_cold.sub(stock_cold, it, count=1)
if 'R173 skip wait_for_coldboot_done' in it2:
    raise SystemExit('coldboot skip string still present')
ip.write_text(it2)
print('init.cpp coldboot VERIFY_OK')

# --- service.cpp: restore trigger_shutdown ---
sp = Path.home() / "aosp16/system/core/init/service.cpp"
st = sp.read_text()
# Reap path
st2, n1 = re.subn(
    r'(has \'reboot_on_failure\' option and failed, shutting down system\.";)\n'
    r'        // BS bringup: skip shutdown for failed services\n'
    r'        LOG\(WARNING\) << "BS bringup: skipping reboot_on_failure for " << name_;\n',
    r'\1\n        trigger_shutdown(*on_failure_reboot_target_);\n',
    st,
    count=1,
)
print(f'service reap restore n={n1}')
# ExecStart / Start scope_guard bodies
st3, n2 = re.subn(
    r'(auto reboot_on_failure = make_scope_guard\(\[this\] \{\n'
    r'        if \(on_failure_reboot_target_\) \{\n)'
    r'            // BS bringup: skip shutdown for failed services\n'
    r'        LOG\(WARNING\) << "BS bringup: skipping reboot_on_failure for " << name_;\n'
    r'        \}\n'
    r'    \}\);)',
    r'\1            trigger_shutdown(*on_failure_reboot_target_);\n        }\n    });',
    st2,
)
print(f'service scope_guard restore n={n2}')
if n2 < 2:
    # try alternate indentation
    st3, n2b = re.subn(
        r'// BS bringup: skip shutdown for failed services\n'
        r'\s*LOG\(WARNING\) << "BS bringup: skipping reboot_on_failure for " << name_;',
        'trigger_shutdown(*on_failure_reboot_target_);',
        st2,
    )
    print(f'service alt restore n={n2b}')
    n2 = n2b
if 'BS bringup: skipping reboot_on_failure' in st3:
    raise SystemExit('still have BS reboot skips')
sp.write_text(st3)
print('service.cpp VERIFY_OK')
print('ALL_SOURCE_OK')
PY

echo "=== verify source markers ==="
rg -n "R174 skip|R173 skip|skip exec \(vdc\)|BS bringup: skipping" \
  "$BP" "$IP" "$SP" && { echo "FAIL: skips remain"; exit 1; } || echo "SOURCE_MARKERS_CLEAN"

echo "=== build init_second_stage via lunch+m ==="
cd "$AOSP"
# Kill any stale hung ssh wrappers from earlier attempts (best-effort)
pkill -f 'r244-m-init' 2>/dev/null || true

nohup bash -lc '
set -e
cd ~/aosp16
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
export OUT_DIR=out_nxt_Baklava64
touch system/core/init/builtins.cpp system/core/init/init.cpp system/core/init/service.cpp
# Prefer module name used by soong
m init -j$(nproc) || m init_second_stage -j$(nproc)
echo INIT_BUILD_EXIT=$?
INIT_OUT=out_nxt_Baklava64/soong/.intermediates/system/core/init/init_second_stage/android_x86_64/init
PROD=out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init
ls -la "$INIT_OUT" "$PROD" 2>/dev/null || true
# Prefer product path if present, else intermediate
SRC="$PROD"
[ -f "$SRC" ] || SRC="$INIT_OUT"
md5sum "$SRC"
echo "=== strings check ==="
strings "$SRC" | rg "R174 skip odsign|R174 skip init_user0|R173 skip wait_for_coldboot|skip exec \(vdc\)|BS bringup: skipping reboot" \
  && echo STRINGS_FAIL || echo STRINGS_OK_HENRY_PATH
# Stage into releases
install -m 0755 "$SRC" ~/releases/Baklava64/system/bin/init
md5sum ~/releases/Baklava64/system/bin/init
echo STAGE_DONE
' > ~/r244-m-init.log 2>&1 &
echo "BUILD_PID=$!"
echo "log: ~/r244-m-init.log"
echo "restore log: $LOG"
