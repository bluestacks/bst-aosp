#!/usr/bin/env python3
"""R252: disable AuthService + AuthenticationPolicyService (BiometricService already off)."""
from pathlib import Path

PATH = Path.home() / "aosp16/frameworks/base/services/java/com/android/server/SystemServer.java"
MARK = "// R252 / Henry: no biometric stack on BS"

PATCHES = [
    (
        """            t.traceBegin("StartAuthService");
            mSystemServiceManager.startService(AuthService.class);
            t.traceEnd();""",
        f"""            t.traceBegin("StartAuthService");
            {MARK}
            // mSystemServiceManager.startService(AuthService.class);
            t.traceEnd();""",
    ),
    (
        """                t.traceBegin("StartAuthenticationPolicyService");
                mSystemServiceManager.startService(AuthenticationPolicyService.class);
                t.traceEnd();""",
        f"""                t.traceBegin("StartAuthenticationPolicyService");
                {MARK}
                // mSystemServiceManager.startService(AuthenticationPolicyService.class);
                t.traceEnd();""",
    ),
]


def main() -> None:
    text = PATH.read_text()
    if MARK in text and "AuthService.class" not in text.split(MARK)[1][:200]:
        # check if AuthService already commented
        pass
    for old, new in PATCHES:
        if old not in text:
            if "// mSystemServiceManager.startService(AuthService.class)" in text and "AuthService" in old:
                print("AuthService already patched")
                continue
            if "// mSystemServiceManager.startService(AuthenticationPolicyService.class)" in text and "AuthenticationPolicy" in old:
                print("AuthenticationPolicyService already patched")
                continue
            raise SystemExit(f"anchor missing:\n{old[:80]}")
        text = text.replace(old, new, 1)
        print(f"patched one block")
    PATH.write_text(text)


if __name__ == "__main__":
    main()
