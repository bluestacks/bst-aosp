#!/bin/bash
set +u
python3 - <<'PY'
from pathlib import Path
p = Path.home()/'aosp16/frameworks/base/services/java/com/android/server/SystemServer.java'
t = p.read_text()
old = '''            t.traceBegin("StartHintManager");
            // R248 / Henry 7W-2: no power HAL on BS
            Log.i("A16DBG:FwBase-HALSkip", "power HAL skipped (BS bringup temp_debt)");
            // mSystemServiceManager.startService(HintManagerService.class);
            t.traceEnd();'''
new = '''            t.traceBegin("StartHintManager");
            // A16DBG:P2:cont22 — R248 temp_debt lifted: power AIDL example present; restore HintManager (performance_hint)
            mSystemServiceManager.startService(HintManagerService.class);
            t.traceEnd();'''
if old not in t:
    # show nearby for debug
    for i,l in enumerate(t.splitlines(),1):
        if 'StartHintManager' in l:
            for j in range(i-1, i+6):
                print(f'CTX {j}:{t.splitlines()[j-1]}')
    raise SystemExit('anchor missing')
p.write_text(t.replace(old, new, 1))
print('patched OK')
for i,l in enumerate(p.read_text().splitlines(),1):
    if 'StartHintManager' in l or 'HintManagerService.class' in l:
        print(f'{i}:{l}')
PY
