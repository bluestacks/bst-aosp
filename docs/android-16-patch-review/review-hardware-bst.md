# Hardware/BST HAL Promotion Review

## Scope and Provenance

The Android-16 product inherits all five HAL implementations through
`device/generic/common`: `audio/alsa.mk` installs `audio.primary.bst` and its
policy files, while `packages.mk` installs `camera.bst`, `lights.bst`,
`memtrack.bst` and `power.bst`. They were present in the AOSP16 green working
tree but absent from the first Android-16 root repository.

Only the AOSP16 working-tree deltas are promoted. Audio, lights, memtrack and
power remain submodules at their reviewed heads. Camera is now inline in the
updated Android-16 base; the previously published camera fork is retained only
as review history. Unrelated Android 13 hardware projects are not imported.

## Patch Review

### `hardware/bst/audio`

- **Source/target:** `f4c2a5b` -> `ac13f7b`.
- **Change:** add `hardware/libhardware/include` to `LOCAL_C_INCLUDES`.
- **Purpose:** compile the legacy `audio_hw_device` implementation with the
  Android 16 header layout. `alsa.mk` also supplies the product audio policy.
- **Necessity:** required. Omitting the repository silently drops the product
  inheritance because it uses `inherit-product-if-exists`.
- **Performance:** no code-generation or runtime behavior change. Existing
  48 kHz/1024-frame buffering and resampling behavior is retained.
- **Security/quality:** legacy C HAL and XML mixer parser remain trusted vendor
  code. Card discovery caching and parser error handling are historical debt;
  audio playback/capture, standby and device-switch tests are required.

### `hardware/bst/camera`

- **Source/target:** `a87e8be` -> reviewed fork `16e8482` -> final inline root
  commits `ccb6e51` and `33cdca5`.
- **Files:** `3.0/CameraMetadata.cpp`, `3.0/ImageProcess.h`.
- **Change:** replace removed `String8::string()` calls with `c_str()` and drop
  the removed, unused `cutils/threads.h` include.
- **Purpose:** retain the HAL3 metadata and image-processing implementation on
  Android 16 without altering its data path.
- **Necessity:** required when `USE_CAMERA_HAL3=true`; `camera.bst` is in the
  product package list.
- **Performance:** equivalent pointer access; no allocation, copy or frame-path
  work is added.
- **Security/quality:** the repository is a large legacy HAL with direct
  buffer, V4L2 and JPEG handling. This patch does not widen that surface, but
  compile success is not sufficient: provider enumeration, preview, capture,
  rotation and teardown need runtime validation.
- **Mainline decision:** use the current base's inline implementation instead
  of a duplicate submodule. It contains the same Android 16 API adaptation and
  changes `MessageQueue::arg0` from `int32_t` to `uintptr_t`, preventing 64-bit
  pointer truncation. `camera.bst` was built for both vendor lib variants and
  included in the 7/7 boot-tested image.

### `hardware/bst/lights`

- **Source/target:** `31b9fb5` -> `d7fb147`.
- **Change:** add the Android 16 vendor libhardware include directory.
- **Purpose/necessity:** build and install `lights.bst`, preserving backlight
  control selected by the `bst` hardware identity.
- **Performance:** no runtime change; brightness writes remain one sysfs open,
  write and close under a mutex.
- **Security/quality:** the inherited code copies a discovered `PATH_MAX` path
  into a `PROPERTY_VALUE_MAX` buffer and does not check `malloc`. These are
  pre-existing robustness risks. They are documented rather than mixed into
  the compatibility commit; exercise property-supplied and auto-discovered
  backlight paths during boot validation.

### `hardware/bst/memtrack`

- **Source/target:** `b2aa1fc` -> `d3596f3`.
- **Change:** add libhardware and libsystem include directories.
- **Purpose/necessity:** provide the `memtrack.bst` module named by the product.
- **Performance:** no runtime change.
- **Security/quality:** this is intentionally a dummy module: it validates its
  module pointer and exposes no accounting implementation. It has negligible
  cost but also no useful GPU/process memory reporting. Keep only for the
  established compatibility contract and verify framework fallback behavior.

### `hardware/bst/power`

- **Source/target:** `ff0cda4` -> `2b2e3e1`.
- **Change:** add libhardware and libsystem include directories.
- **Purpose/necessity:** retain the legacy `power.bst` module. The AIDL example
  power service remains separately required for Android 16 hint sessions.
- **Performance:** no change in the patch. The inherited implementation only
  walks non-boot CPU sysfs nodes when interactive state changes; ordinary
  power hints are no-ops.
- **Security/quality:** CPU numbering is assumed contiguous and sysfs write
  results are ignored. That is acceptable only as a compatibility fallback;
  suspend/resume and multi-vCPU online-state readback are required.

## Validation Gates

1. Build all five module names under `android_x86_64` with `OUT_DIR=out`.
2. Confirm product copy/install entries for the HALs and audio policy files.
3. Boot with no HAL loader fallback or repeated service crash.
4. Exercise audio playback/capture, camera preview/capture, brightness changes,
   memtrack service startup and CPU online state across suspend/resume.
5. Record any future implementation hardening in separate `[A16]` commits so
   compatibility deltas remain reviewable.
