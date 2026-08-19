# Camera, Recents, and GameCenter Regression Closure, 2026-08-18

Stage: Android-16 mainline maintenance

Status: historical local incremental build/package and clean-Data runtime
validation PASS. The superseding publication uses a direct goldfish component
PR only; app-player and Android root are not submitted. No app-player
`buildscripts` change is part of this fix.

Superseded on 2026-08-19: the package-level failure evidence remains valid, but
the broad four-policy `frameworks/native` package exclusion was not published
and has been removed. Single-variable A/B proved that Camera2 needs only
`TTCDisabled=false` and Launcher3 needs only `GLPB=false`; the replacement is a
16-line A16-guarded goldfish encoder correction documented in
[`graphics-platform-policy-minimal-2026-08-19.md`](graphics-platform-policy-minimal-2026-08-19.md).

## Scope and discipline

The investigation used only the markxu Android-16 and app-player workspaces and
the Windows `Tiramisu64` instance. It did not read or build AOSP16, modify or
wait for Henry's workspace or processes, run Android 13, clean Android OUT, or
submit directly to a BlueStacks target branch.

Source identities:

- Android root: `bst-v5.22.210-A16` / `2fd36fe849bca69fac6f82ecc5c2e5880e24f914`;
- `device/generic/common`: `c55b6bbddccd10329b4ec3acb48b5eaf0e27a227`;
- `frameworks/native`: `bc0b387827b35e0d6ef16490502fa40976436bf5`;
- app-player: `bst-v5.22.210-A16` / `1bdbf5b5f0e75cab32e2a4dee65f0bea7447ff7d`;
- goldfish-opengl: `87a539e25bbfe6f3b384118d66827b7d5c4f28b1`;
- HD / VBox: `bfbab1b0c210f7714dbdbd890187ec73d5b4a6e4` /
  `af3611cc932497d7756409437fc151586e61aa72`.

## Root causes

### Snapshot persistence was interrupted by the regression harness

The previous boot verifier force-stopped `HD-Player.exe`. TaskSnapshot writes
are asynchronous, so a forced stop could leave a missing snapshot or a zero
byte `.jpg`. A guest shutdown through
`bst.config.start_shutdown=1` caused queued snapshots to be written before the
player shell was stopped. The verifier now requests guest shutdown, waits up to
45 seconds for ADB to disconnect, and only then stops a remaining player shell.

This explains the Data-dependent white-card cases and why a clean Data image
could temporarily appear to fix the problem. It was not evidence of an old
graphics library in Root.

### Real Binder policy activated unsafe A13 game defaults for A16 platform apps

After the direct system-Binder client became functional, runtime logs showed
that `com.android.camera2` and `com.android.launcher3` received these legacy
default-on game policies even though `config.db` had no matching package rule:

- texture-target check disabled (`TTCDisabled=1`);
- GL program binary enabled (`GLPB=1`);
- host map-buffer-range enabled (`GLMBRH=1`);
- unmap-buffer performance path enabled (`GLUBPerf=1`).

The Java service intentionally defaults these legacy A13 methods to true. On
the retained A16 graphics stack, enabling them for Camera2 corrupted the live
SurfaceTexture path, and enabling them for Quickstep corrupted persisted task
textures after restart. The persisted PNG data was independently pulled and
rendered correctly, proving the second failure was texture import/rendering,
not file corruption.

GameCenter is different: it is an ordinary game-policy client and must retain
the real Binder result. A global no-op, global Binder-domain change, config
database wildcard, or removal of the NDK client would hide the platform issue
while regressing valid game policy and RTVbox behavior.

## Superseded source correction

`frameworks/native` commit `bc0b387827` added a target-only package check in the
vendor graphics policy transaction path. Camera2 and Quickstep return the
existing safe false/empty native fallbacks before loading or querying the NDK
Binder service. All other application UIDs, including GameCenter, continue to
query `bstfilterapps` through system Binder.

This commit was local only and was removed on 2026-08-19. Current
`frameworks/native` is clean at `626929d3cf`; the real Binder client remains,
and the two cardinality-one exceptions moved to goldfish commit `37901957`.

Review:

- necessity: required because the real service contract has unsafe default-on
  values for A16 platform renderers;
- performance: two package comparisons during graphics policy initialization,
  no per-frame work and no new polling or Binder transaction;
- security: no service exposure, SELinux, permission, AIDL, or Binder-domain
  change;
- compatibility: this historical implementation was confined to an
  Android-16 `frameworks/native` package check, but it was not published and is
  superseded by the A16-guarded goldfish implementation below;
- rejected alternatives: no-op manager, global `/dev/binder` switch, config DB
  wildcard, and empty service implementation remain rejected.

The existing `device/generic/common` commit `c55b6bbdd` disables reduced task
snapshots for this A16 product. New snapshots are 1600x900 with
`mIsLowResolution=false`; this also avoids the retained legacy gralloc's
problematic half-scale persisted path. It can increase snapshot storage and
cold-load bandwidth by up to four times per card relative to a 0.5 scale
snapshot, so storage and Recents latency remain performance follow-ups.

## Package stale-file audit

The canonical package wrapper now compares critical files in `system.img`
against the Android OUT input, including both vendor `libbinder.so` variants.
The final package readback matched OUT exactly:

- `/vendor/lib/libbinder.so`:
  `6b0082140affdb8840d637ecd63128eed5d1b20e2a9610479691cb40fd65c145`;
- `/vendor/lib64/libbinder.so`:
  `4bdad84ecd43f8845e6641612e5d15e63323c4ac73dfb6c7484f07d922946c93`.

Both packaged files contain the new platform-default log marker. Framework,
services, framework-res, SystemUI, WebView, SurfaceFlinger, and the camera
provider also passed OUT-to-image hash checks. Vendor RTVbox files were present
and stale system RTVbox paths were absent.

The first package attempt exposed a separate build-host hygiene issue: the
automatic loop-device selection raced another concurrent package and failed at
the Root VDI mount. No Henry process or device was changed. A canonical retry
allocated the device successfully. Final readback found no markxu release
mount, loop backing file, or qemu-nbd process. The one-off targeted build script
was removed; its build log was retained as evidence.

## Final artifact identity

- `Root.vhd`: `09e6a8c91002498db4cb5ee3146f73ee9662f210c8119c977926129e2146b130`;
- `system.img`: `b1b8e15fcd18c26e2d90d62c157407f9c2a7f9bc6e3e436af0516ec88141b269`;
- `system.sfs`: `c0a4d602cbe67f1976f285cfceb63a83d4129ed91a3d6315a81b47e196789e49`;
- `fastboot.vdi`: `a4000088b5f1aa5abf406122435aed124eb12ad4d696e325259216b34d19e617`;
- Root UUID: `54e9ad31-a169-4d5b-a0e0-705d62e96e71`;
- fastboot UUID: `91b80c95-aa7d-459d-93e4-c479f5babbb7`;
- generated: `2026-08-18T22:30:52+08:00`.

Data was restored from `Data.vhdx.wipe20260717-141744` and bound to the Root
SHA before boot. This excludes cross-Root Data reuse from the result.

## Runtime acceptance

Two cold boots passed all seven lifecycle gates, stabilization, and guest
framebuffer probes:

- boot 1: elapsed 169 seconds, non-black ratio `0.923407`;
- graceful-shutdown boot 2: elapsed 147 seconds, non-black ratio `0.978274`.

The standard runtime regression passed. Targeted results:

- Camera2 logged all four platform graphics policies as `0`, opened camera 0,
  produced an active 1280x720 output stream, and rendered a real live frame.
- Quickstep logged all four policies as `0`. Current and cold-reloaded Camera,
  Clock, Settings, and Store cards rendered correctly with no white card,
  black/red border, or wrong texture.
- New snapshot files were non-empty. The new task snapshots were full scale and
  no new `_reduced` file was created.
- GameCenter logged the direct system-Binder client and all four game policies
  as `1`, connected to `RTVBoxMM`, rendered normally, and remained foreground
  with the same PID for more than 95 seconds.
- No new GameCenter ANR, fatal exception, SIGABRT, Binder wait, RTVbox service
  timeout, header mismatch, or tombstone appeared.

Evidence screenshots are under
`.tmp-camera-recents-ab/final-validation/`, notably
`camera-live-accepted.png`, `recents-current.png`, `recents-cold.png`, and
`gamecenter-accepted.png`.

Screenshot SHA-256 identities:

- Camera live frame: `4cfcf97fd15d4e3ce2031c1ed30600bb65972410fef5a6a482d9c87185ae7fd0`;
- current Recents: `358541f64c08ddafb79f1c4a97a377434b8547090c2b8bdd56b48b9a05d48a8d`;
- cold-reloaded Recents: `c984bde1623c64951e2d682d8701fbb8283b7572a6ffada987156db27ff1491e`;
- stable GameCenter: `a17f0dcbc540f983ea4b40f858b95eadd86163f458296cecc2a0d5435732af20`.

## Publication state

No source was pushed in this historical validation. `bc0b387827` was removed
without publication. Its replacement, goldfish `37901957`, must be published
through a direct component PR. Per the current publication rule, app-player and
the Android root receive no gitlink commit or PR. The local workflow-script and
documentation changes are not app-player `buildscripts` changes and must not be
folded into a direct BlueStacks branch push.

## Replacement acceptance, 2026-08-19

The accepted replacement is goldfish commit
`37901957f219f2d5aac6760f97e8c1f19a2e6b33`, not the removed common-native
commit. Single-variable A/B reduced Camera2 to `TTCDisabled=false` only and
Launcher3 to `GLPB=false` only; the other six package-policy results retain the
A13 default `true`. The implementation is compiled only for A16 and leaves the
A13 encoder path unchanged.

The final incremental package kept the original `config.db`, passed first boot
and a 7/7 cold boot, rendered a live Camera frame, and rendered both current
and cold-reloaded Recents without white cards or black/red borders. GameCenter
continued through real Binder policy without a new fatal, ANR, RTVbox error or
service timeout. The final Root SHA-256 is
`44e0999c7803333d4e59125164c693352ff3f7eafd3fe3daa859deb2465ad1d0`.

The detailed package identities, exact runtime policy logs and evidence hashes
are recorded in
[`graphics-platform-policy-minimal-2026-08-19.md`](graphics-platform-policy-minimal-2026-08-19.md).
The Play Store 39.4.23 `VpaService` permission crash observed on the same cold
boot is an independent Android-16 compatibility issue and is not part of the
goldfish fix.
