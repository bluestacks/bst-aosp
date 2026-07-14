#!/usr/bin/env python3
"""R261: Restore AuthService (+ AuthenticationPolicyService) like Henry.

Root cause: R252 commented AuthService to skip biometrics. Settings uses
Context.AUTH_SERVICE → ServiceManager.getServiceOrThrow("auth") and is
force-finished when missing → blank Settings UI.

Henry still starts AuthService; only BiometricService is skipped (no gatekeeper).
"""
from pathlib import Path

SS = Path.home() / "aosp16/frameworks/base/services/java/com/android/server/SystemServer.java"


def main() -> int:
    text = SS.read_text()
    bak = SS.with_suffix(SS.suffix + ".bak-r261")
    if not bak.exists():
        bak.write_text(text)
        print(f"backup {bak}")

    changed = False

    auth_old = (
        "            t.traceBegin(\"StartAuthService\");\n"
        "            // R252 / Henry: no biometric stack on BS\n"
        "            // mSystemServiceManager.startService(AuthService.class);\n"
        "            t.traceEnd();\n"
    )
    auth_new = (
        "            t.traceBegin(\"StartAuthService\");\n"
        "            // R261 / Henry: keep AuthService (publishes \"auth\" for Settings)\n"
        "            mSystemServiceManager.startService(AuthService.class);\n"
        "            t.traceEnd();\n"
    )
    if "R261 / Henry: keep AuthService" in text:
        print("AuthService: already patched")
    elif auth_old in text:
        text = text.replace(auth_old, auth_new, 1)
        changed = True
        print("AuthService: enabled")
    else:
        print("AuthService: unexpected shape")
        return 1

    pol_old = (
        "                t.traceBegin(\"StartAuthenticationPolicyService\");\n"
        "                // R252 / Henry: no biometric stack on BS\n"
        "                // mSystemServiceManager.startService(AuthenticationPolicyService.class);\n"
        "                t.traceEnd();\n"
    )
    pol_new = (
        "                t.traceBegin(\"StartAuthenticationPolicyService\");\n"
        "                // R261 / Henry: restore AuthenticationPolicyService\n"
        "                mSystemServiceManager.startService(AuthenticationPolicyService.class);\n"
        "                t.traceEnd();\n"
    )
    if "R261 / Henry: restore AuthenticationPolicyService" in text:
        print("AuthenticationPolicyService: already patched")
    elif pol_old in text:
        text = text.replace(pol_old, pol_new, 1)
        changed = True
        print("AuthenticationPolicyService: enabled")
    else:
        print("AuthenticationPolicyService: unexpected shape (ok if already stock)")

    if changed:
        SS.write_text(text)
    print("R261_PATCH_OK")
    for i, line in enumerate(SS.read_text().splitlines(), 1):
        if "AuthService.class" in line or "AuthenticationPolicyService.class" in line or "R261" in line:
            print(f"{i}: {line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
