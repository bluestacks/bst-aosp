# Security Review

## P0: Archived Signing Keystore

The current tree previously tracked:

`patches/android-16/untracked-src/aosp16__device_generic_common/apksigner/bluestacks-market.keystore`

Recorded identity before removal:

- Size: 2341 bytes
- SHA-256:
  `7d4d2b8f3b19478689dc8a456a29681f1212fad7f32f84c46ad86c3a8efadd7d`
- Original file timestamp: 2025-08-20 14:13:58 local time

The keystore is removed from the current working tree and its exact path is
ignored. Build or release signing must inject an approved credential outside
Git. Because the bytes remain in existing Git history, the owning team must
treat the credential as exposed and rotate it; deleting the current file is not
credential revocation.

The adjacent `apksigner` launcher and JAR may remain as historical payloads, but
they must not imply that release signing material belongs in source control.

## Pattern Scan

The repository inventory scans text for private-key markers, common token
formats, and secret-like assignments. Filename matches in diagnostic scripts
such as keystore wipe or bypass experiments are review hints, not credentials.
Only actual key/container material receives P0 treatment.
