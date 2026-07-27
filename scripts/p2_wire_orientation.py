#!/usr/bin/env python3
from pathlib import Path
p = Path.home() / "aosp16/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
w = p.read_text()
if "sendOrientationToHostAsync(getDefaultDisplayRotation())" in w:
    print("call site already present")
else:
    old = """                if (layoutNeeded) {
                    Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER,
                            "updateRotation: performSurfacePlacement");
                    mWindowPlacerLocked.performSurfacePlacement();
                    Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
                }
            }
        } finally {
            Binder.restoreCallingIdentity(origId);
"""
    new = """                if (layoutNeeded) {
                    Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER,
                            "updateRotation: performSurfacePlacement");
                    mWindowPlacerLocked.performSurfacePlacement();
                    Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
                }
            }
            try {
                sendOrientationToHostAsync(getDefaultDisplayRotation());
            } catch (Exception e) {
                Slog.w(TAG, "P2 sendOrientationToHostAsync: " + e);
            }
        } finally {
            Binder.restoreCallingIdentity(origId);
"""
    if old not in w:
        raise SystemExit("anchor missing for orientation call site")
    p.write_text(w.replace(old, new, 1))
    print("inserted orientation call site in updateRotationUnchecked")
