#!/bin/bash
# Phase2 P0 cont.10b: fix hidl.manager version 1.0 -> 1.2 (matches V1_2::IServiceManager::descriptor)
set -eo pipefail
LOG=$HOME/p2_mgr_ver12_$(date +%Y%m%d-%H%M%S).log
exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2: manager@1.2 fix start $(date -Is) log=$LOG"

# 1) Framework source manifest MUST stay at 1.0.
# Stock A16 already declares manager@1.2 in system/hwservicemanager/hwservicemanager.xml
# (assembled into system_ext). Bumping framework to 1.2 duplicates FqInstance and fails vintffm.
FW=~/aosp16/system/libhidl/vintfdata/manifest.xml
python3 - <<'PY'
from pathlib import Path
import re
p = Path.home()/"aosp16/system/libhidl/vintfdata/manifest.xml"
t = p.read_text()
t2, n = re.subn(
    r'(<name>android\.hidl\.manager</name>\s*<transport>hwbinder</transport>\s*)<version>1\.2</version>',
    r'\1<version>1.0</version>',
    t,
    count=1,
)
if n:
    p.write_text(t2)
    print('framework manifest: reverted manager 1.2 -> 1.0 (avoid system_ext duplicate)')
else:
    print('framework manager already 1.0 (correct)')
m = re.search(r'<name>android\.hidl\.manager</name>.*?</hal>', p.read_text(), re.S)
print(m.group(0) if m else 'NOT FOUND')
PY

# 2) Device source manifest
DEV=~/aosp16/device/generic/common/manifest.xml
python3 - <<'PY'
from pathlib import Path
import re
p = Path.home()/"aosp16/device/generic/common/manifest.xml"
t = p.read_text()
t2 = t.replace(
    '''        <name>android.hidl.manager</name>
        <transport>hwbinder</transport>
        <version>1.0</version>''',
    '''        <name>android.hidl.manager</name>
        <transport>hwbinder</transport>
        <version>1.2</version>''',
    1,
)
if t2 == t:
    if 'android.hidl.manager' in t and '<version>1.2</version>' in t:
        print('device already 1.2')
    else:
        raise SystemExit('device replace failed')
else:
    p.write_text(t2)
    print('device manifest: manager 1.0 -> 1.2')
print(p.read_text())
PY

# 3) Staged framework + vendor manifests
STAGE=~/releases/Baklava64/system
python3 - <<'PY'
from pathlib import Path
import re

def fix(path, label):
    p = Path(path)
    t = p.read_text()
    orig = t
    # fqname form
    t = t.replace('@1.0::IServiceManager/default', '@1.2::IServiceManager/default')
    # version form inside manager hal only — crude but ok if unique
    t2 = re.sub(
        r'(<name>android\.hidl\.manager</name>\s*<transport>hwbinder</transport>\s*)<version>1\.0</version>',
        r'\1<version>1.2</version>',
        t,
        count=1,
        flags=re.S,
    )
    if t2 == orig and '@1.2::IServiceManager' not in t2:
        # ensure manager exists with 1.2
        if 'android.hidl.manager' not in t2:
            raise SystemExit(f'{label}: no hidl.manager')
        raise SystemExit(f'{label}: failed to bump to 1.2')
    p.write_text(t2)
    print(f'{label}: updated')
    for line in t2.splitlines():
        if 'hidl.manager' in line or 'IServiceManager' in line or (line.strip().startswith('<version>') and 'manager' in t2):
            pass
    m = re.search(r'<name>android\.hidl\.manager</name>.*?(?:</hal>|<sepolicy>)', t2, re.S)
    print(m.group(0)[:300] if m else 'block missing')

fix(Path.home()/'releases/Baklava64/system/etc/vintf/manifest.xml', 'staged framework')
fix(Path.home()/'releases/Baklava64/system/vendor/etc/vintf/manifest.xml', 'staged vendor')
PY

# 4) service.cpp should already be no-DIAG (device-side path). Verify.
rg -n 'A16DBG:HWSM|if \(false\)|transport ==' ~/aosp16/system/hwservicemanager/service.cpp | head -8
# binary already no-DIAG from previous rebuild — confirm strings
strings ~/releases/Baklava64/system/bin/hwservicemanager | grep -E 'HWSM-EMPTY|DIAG bypass|device-side' | head -5

echo "A16DBG:P2: manager@1.2 prep DONE $(date -Is) — next pack"
echo "LOG=$LOG"
