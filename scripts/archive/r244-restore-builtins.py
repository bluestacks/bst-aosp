#!/usr/bin/env python3
"""R244: restore Henry/AOSP stock odsign wait_for_prop + init_user0 (remove R174 skips)."""
from pathlib import Path
import re
import sys

p = Path.home() / "aosp16/system/core/init/builtins.cpp"
text = p.read_text()
backup = Path(str(p) + ".bak-r244")
if not backup.exists():
    backup.write_text(text)
    print(f"backed up to {backup}")

lines = text.splitlines(True)
out = []
removed = 0
for ln in lines:
    if 'strcmp(name, "odsign.verification.done")' in ln and "return {}" in ln:
        removed += 1
        print("REMOVE:", ln[:80].rstrip())
        continue
    if 'strcmp(name, "odsign.key.done")' in ln and "return {}" in ln:
        removed += 1
        print("REMOVE:", ln[:80].rstrip())
        continue
    out.append(ln)
text2 = "".join(out)
print(f"removed_odsign_skips={removed}")
if removed != 2:
    print("WARN: expected 2 odsign skip lines", file=sys.stderr)

pat = re.compile(
    r"static Result<void> do_init_user0\(const BuiltinArguments& args\) \{.*?^\}",
    re.M | re.S,
)
stock = (
    'static Result<void> do_init_user0(const BuiltinArguments& args) {\n'
    '    return ExecVdcRebootOnFailure("init_user0");\n'
    "}"
)
m = pat.search(text2)
if not m:
    sys.exit("do_init_user0 not found")
print("old_user0:", repr(m.group(0)[:100]))
if 'ExecVdcRebootOnFailure("init_user0")' in m.group(0):
    print("user0 already stock")
else:
    text2 = pat.sub(lambda _m: stock, text2, count=1)
    print("user0 restored to stock")

p.write_text(text2)
v = p.read_text()
assert 'strcmp(name, "odsign.verification.done")' not in v, "verification skip still present"
assert 'strcmp(name, "odsign.key.done")' not in v, "key skip still present"
assert 'ExecVdcRebootOnFailure("init_user0")' in v, "user0 not stock"
print("SOURCE_VERIFY_OK")
