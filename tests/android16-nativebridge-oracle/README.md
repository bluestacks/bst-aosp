# Android-16 Native-Bridge Oracle

This temporary APK proves translated ARM64 execution through the promoted
Android-16 guest. It is test scaffolding only; it is not a product module,
app-player payload or publication component, and the generated APK is never
committed.

The APK contains only an `arm64-v8a` JNI library. Its activity exercises
regular, `FastNative` and `CriticalNative` calls, then requires its own process
maps to contain both the test library and `libhoudini.so`. It also verifies the
translated process sees the supplied ARMv8 `/proc/cpuinfo` view. The Windows
runner independently checks PackageManager selected `arm64-v8a`, scans for
native or Java crashes, and uninstalls the APK in `finally`.

Build it only from Android-16 source prebuilts after the product build has
finished:

```bash
bash tests/android16-nativebridge-oracle/build.sh \
  --android-root "$HOME/android-16" \
  --output /tmp/a16-nativebridge-oracle.apk
```

The build rejects AOSP16 paths and outputs inside the Android source tree. The
identity sidecar binds the generated APK to the target root, branch, root SHA,
oracle source hash, AArch64 ELF hash and APK hash. The ELF is compiled without
platform libraries so the result tests translator entry and JNI trampoline
behavior without importing another native dependency surface.

Run it on the clean Android-16 instance:

```powershell
./scripts/g1_nativebridge_runtime_oracle.ps1 `
  -ApkPath C:\path\to\a16-nativebridge-oracle.apk
```

Passing this oracle does not by itself prove representative game performance,
all package-specific hotfixes, or standalone binfmt execution. Those remain
separate regression gates.
