# BlueStacks package scan order promotion

## Identity

- Stage: `android16-promotion`
- Source tree: `~/app-player/android-13`, branch `bst-v5.22.210`
- Source `frameworks/base` commit: `c8f869b13707dfbf71d9e961a5ff60b42065a4fd`
- Target tree: `~/android-16`, branch `aosp16-bst-merge`
- Target component commit: `971523b961b1e197dbb04f642ab916ee01374920`
- Target root commit: `3d62b6f641a4006987e760156e12193775eaa15f`
- Result: current A13 alignment; superseded as the Settings root-cause fix

## Problem

The Android-16 guest contained
`/system/priv-app/com.bluestacks.settings/com.bluestacks.settings.apk`, but
PackageManager did not publish package state for `com.bluestacks.settings`.
Resolver tables still contained its activities and repeatedly logged stale
resolve-result removal. `pm path com.bluestacks.settings` failed, so the
BlueStacks Settings regression could not run.

Android 13 scans the normal system partitions first, then scans
`/data/priv-downloads` and `/data/downloads` as two separate operations. The
initial Android-16 promotion instead appended both data directories to the
same cross-directory parallel scan batch as the system partitions.

## Adaptation

`InitAppsHelper.scanSystemDirs()` keeps Android 16's standard partition scan
parallel. After that batch completes, it invokes `scanDirTracedLI()` once for
each BlueStacks data directory, preserving the A13 boundary and flags:

- `/data/priv-downloads`: `SCAN_AS_PRIVILEGED`
- `/data/downloads`: `SCAN_AS_SYSTEM`

No package paths, parse flags, package priority, or duplicate-package policy
were changed. The adaptation is smaller than restoring A13's fully sequential
system-partition loop.

## Code Review

The Android-16 parallel implementation submits parse work for every directory
and consumes the returned futures in directory order. The defect therefore
must not be described as proven arbitrary result ordering. The material
behavioral difference is that the promoted code allowed the two mutable data
directories to be parsed in the same cross-directory batch as immutable
system packages, while A13 completed each custom directory independently.

The change restores the source branch's scan boundary without changing
unrelated A16 PackageManager behavior. It was tested as a candidate fix for
the package-state inconsistency. Clean-Data runtime evidence later disproved
that hypothesis: the same packages were parsed and the same resolver entries
were filtered. The actual cause was the trusted-caller adaptation documented
in [`package-visibility-2026-08-07.md`](package-visibility-2026-08-07.md).

The broader runtime acceptance still requires all of the following:

- `pm path com.bluestacks.settings` returns the system APK;
- HOME resolves to and resumes `com.uncube.launcher3`;
- no stale resolve-result or PackageManager package-state fatal appears;
- BlueStacks Settings launches and returns to Launcher;
- `system_server` and Launcher remain stable for the bounded regression window.

## Performance And Security

Standard system partitions retain Android 16's parallel scan. Only the small
BlueStacks data payload loses cross-directory parse overlap, once during boot.
The expected cost is bounded startup latency; there is no steady-state or
per-frame cost. Runtime timing should be compared with the prior boot oracle.

The change does not widen trust or permissions. It retains the existing
privileged/system flags, SELinux labels, signature checks, and duplicate
handling. Restoring deterministic trust-boundary sequencing reduces the risk
of publishing resolver data without matching package state.

## Validation

- `git diff --check`: pass
- Incremental target build: `m -j8 services`, pass
- Installed output: `out_nxt_Baklava64/target/product/x86_64/system/framework/services.jar`
- Build mode: incremental, no clean, existing `out_nxt_Baklava64` preserved
- Image/package build: pass; root `3d62b6f641a4006987e760156e12193775eaa15f`
- Clean-Data boot: 7/7 pass in 264 seconds, including 95-second stability
- Runtime result: Settings remained hidden and stale-result logging remained;
  scan order was not the root-cause fix

Rollback is the component parent
`5acece03e566c739235304c30a81afb7e7a3256c` plus root parent
`cdd6dac760126b41b3a287bcb54354c7f1d38575`. Rollback is allowed only if the
runtime evidence disproves the sequencing fix or shows an unacceptable boot
regression; the underlying Settings package-state failure must still receive
a replacement fix.
