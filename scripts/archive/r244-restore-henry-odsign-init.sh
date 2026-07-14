#!/bin/bash
# R244: Henry 7R — restore stock odsign wait_for_prop + init_user0 in init
# (remove R174 skips that prevented odsign→odrefresh→boot.art)
set -euo pipefail
AOSP=~/aosp16
OUT=${OUT_DIR:-$AOSP/out_nxt_Baklava64}
LOG=~/r244-init-restore.log
exec > >(tee "$LOG") 2>&1
echo "=== R244 Henry 7R init restore $(date) ==="

BP=$AOSP/system/core/init/builtins.cpp
cp -a "$BP" "$BP.bak-r244-$(date +%H%M%S)"

python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/builtins.cpp"
text = p.read_text()
# Remove R174 odsign wait skips (two obfuscated one-liners)
import re
text2, n1 = re.subn(
    r'\n    if \(strcmp\(name, "odsign\.verification\.done"\) == 0\) \{[^;]+; \}\n'
    r'    if \(strcmp\(name, "odsign\.key\.done"\) == 0\) \{[^;]+; \}\n',
    '\n',
    text,
    count=1,
)
if n1 != 1:
    # try line-by-line removal
    lines = text.splitlines(True)
    out = []
    removed = 0
    for ln in lines:
        if 'odsign.verification.done' in ln and 'R174' in ln.encode('unicode_escape').decode() or (
            'strcmp(name, "odsign.verification.done")' in ln and 'return {}' in ln
        ):
            removed += 1
            continue
        if 'strcmp(name, "odsign.key.done")' in ln and 'return {}' in ln:
            removed += 1
            continue
        out.append(ln)
    text2 = ''.join(out)
    n1 = removed
    print(f"line-filter removed={removed}")
else:
    print(f"regex removed odsign skips n={n1}")

# Restore do_init_user0 to Henry/AOSP stock
old_user0 = None
# match the R174 skip body
pat_user0 = re.compile(
    r'static Result<void> do_init_user0\(const BuiltinArguments& args\) \{\n'
    r'.*?\n\}',
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
if 'ExecVdcRebootOnFailure("init_user0")' in m.group(0):
    print('do_init_user0 already stock')
else:
    text2 = pat_user0.sub(stock_user0, text2, count=1)
    print('restored do_init_user0 to stock')

p.write_text(text2)
# verify
v = p.read_text()
assert 'odsign.verification.done' not in v or 'wait_for_prop' in v
# the skip lines must be gone
assert 'R174 skip odsign' not in v.replace('\\', '')
# check obfuscated form gone: look for strcmp odsign in do_wait_for_prop returning early
import subprocess
r = subprocess.check_output(['rg','-n','odsign\\.(key|verification)\\.done', str(p)], text=True)
print('remaining odsign prop refs:\n', r)
if 'return {}' in r and 'strcmp' in r:
    # still have skip?
    for line in r.splitlines():
        if 'strcmp' in line and 'return {}' in line:
            raise SystemExit(f'still have skip: {line}')
print('VERIFY_OK')
PY

# Show the restored functions
rg -n "do_wait_for_prop|do_init_user0|odsign" "$BP" | head -30
sed -n '1100,1135p' "$BP"
sed -n '1168,1180p' "$BP"

echo "=== build init (ninja, avoid full soong if possible) ==="
cd "$AOSP"
# Prefer existing ninja target
NINJA=$OUT/soong/build.ninja
if [ ! -f "$NINJA" ]; then
  echo "missing $NINJA" >&2
  exit 1
fi
# Find init module path
INIT_TARGET=$(rg -l 'out_nxt_Baklava64/target/product/x86_64/system/bin/init' "$OUT" --glob '*.ninja' 2>/dev/null | head -1 || true)
echo "ninja file sample: $NINJA"
# Use m with limited modules via ninja directly
set +e
# Common soong output path for init
INIT_OUT="$OUT/target/product/x86_64/system/bin/init"
# Try ninja -C out_nxt with the init stamp
nohup bash -lc "
  cd $AOSP
  source build/envsetup.sh
  lunch android_x86_64-trunk_staging-eng
  export OUT_DIR=out_nxt_Baklava64
  # Build only init + deps
  m init -j\$(nproc)
  echo INIT_BUILD_EXIT=\$?
  ls -la \$OUT_DIR/target/product/x86_64/system/bin/init
  md5sum \$OUT_DIR/target/product/x86_64/system/bin/init
  strings \$OUT_DIR/target/product/x86_64/system/bin/init | rg 'R174 skip odsign|R174 skip init_user0' || echo 'STRINGS_OK: no R174 odsign/user0 skip'
" > ~/r244-m-init.log 2>&1 &
echo "BUILD_PID=$!"
echo "log: ~/r244-m-init.log"
