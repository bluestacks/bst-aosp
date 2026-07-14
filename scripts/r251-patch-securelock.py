#!/usr/bin/env python3
"""R251 / Henry: null-safe SecureLockDeviceService.hasStrongBiometricSensor (no BiometricService)."""
from pathlib import Path

PATH = (
    Path.home()
    / "aosp16/frameworks/base/services/core/java/com/android/server/security/authenticationpolicy/SecureLockDeviceService.java"
)
MARK = "R251 / Henry SecureLock null-safe"

OLD = """    private boolean hasStrongBiometricSensor() {
        for (SensorProperties sensorProps : mBiometricManager.getSensorProperties()) {
            if (sensorProps.getSensorStrength() == SensorProperties.STRENGTH_STRONG) {
                return true;
            }
        }
        return false;
    }"""

NEW = f"""    private boolean hasStrongBiometricSensor() {{
        // {MARK}: BiometricService may be disabled on BS (no GateKeeper HAL).
        try {{
            if (mBiometricManager == null) {{
                return false;
            }}
            for (SensorProperties sensorProps : mBiometricManager.getSensorProperties()) {{
                if (sensorProps.getSensorStrength() == SensorProperties.STRENGTH_STRONG) {{
                    return true;
                }}
            }}
        }} catch (Exception e) {{
            Slog.w(TAG, "hasStrongBiometricSensor: biometrics unavailable", e);
        }}
        return false;
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
