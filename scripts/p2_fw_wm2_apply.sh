#!/bin/bash
set +u
python3 - <<'PY'
from pathlib import Path
p = Path.home()/'aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java'
t = p.read_text()
if 'A16DBG:P2:FW-WM-2 sendOrientation' in t:
    print('already patched')
else:
    old = '''        mWmService.mRotationWatcherController.dispatchDisplayRotationChange(mDisplayId, rotation);
    }

    void setFixedTransformHint(Transaction t, SurfaceControl sc, int rotation) {
'''
    new = '''        mWmService.mRotationWatcherController.dispatchDisplayRotationChange(mDisplayId, rotation);
        // A16DBG:P2:FW-WM-2 sendOrientation — a13 DisplayContent rotation → host
        try {
            mWmService.sendOrientationToHostAsync(mWmService.getDefaultDisplayRotation());
        } catch (RuntimeException e) {
            android.util.Slog.w(TAG, "A16DBG:P2:FW-WM-2 sendOrientation: " + e);
        }
    }

    void setFixedTransformHint(Transaction t, SurfaceControl sc, int rotation) {
'''
    if old not in t:
        raise SystemExit('anchor missing')
    p.write_text(t.replace(old, new, 1))
    print('DisplayContent patched')

# verify
for i,l in enumerate(p.read_text().splitlines(),1):
    if 'A16DBG:P2:FW-WM-2' in l or 'sendOrientationToHostAsync' in l:
        print(f'{i}:{l[:110]}')
PY
