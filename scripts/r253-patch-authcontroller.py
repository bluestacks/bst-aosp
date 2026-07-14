#!/usr/bin/env python3
"""R253: AuthController null-safe setBiometricContextListener (SystemUI)."""
from pathlib import Path

PATH = (
    Path.home()
    / "aosp16/frameworks/base/packages/SystemUI/src/com/android/systemui/biometrics/AuthController.java"
)
MARK = "R253 / Henry: null-safe biometric context listener"

OLD = """    @Override
    public void setBiometricContextListener(IBiometricContextListener listener) {
        if (mBiometricContextListenerJob != null) {
            mBiometricContextListenerJob.cancel(null);
        }
        mBiometricContextListenerJob =
                mLogContextInteractor.get().addBiometricContextListener(listener);
    }"""

NEW = f"""    @Override
    public void setBiometricContextListener(IBiometricContextListener listener) {{
        // {MARK}
        if (listener == null) {{
            Log.w(TAG, "setBiometricContextListener: ignoring null listener");
            return;
        }}
        if (mBiometricContextListenerJob != null) {{
            mBiometricContextListenerJob.cancel(null);
        }}
        mBiometricContextListenerJob =
                mLogContextInteractor.get().addBiometricContextListener(listener);
    }}"""


def main() -> None:
    text = PATH.read_text()
    if MARK in text:
        print("already patched")
        return
    if OLD not in text:
        raise SystemExit("anchor not found")
    PATH.write_text(text.replace(OLD, NEW, 1))
    print(f"patched {PATH}")


if __name__ == "__main__":
    main()
