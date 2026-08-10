# Trusted BlueStacks package visibility promotion

## Identity

- Stage: `android16-promotion`
- A13 authority: `frameworks/base`, branch `bst-v5.22.210`, commit
  `c8f869b13707dfbf71d9e961a5ff60b42065a4fd`
- Original A16 port: `8221d29acc036e034493bc09d58a5316fac4005f`
- Corrected A16 component: `172d2f4cbce76a7018dda6bbe3171c400c19317b`
- Corrected Android root: `e52ab6a672f4d7aa4bd22308c7aefb29669c9bd8`
- Result: current, clean-Data runtime validated

## Symptom And Root Cause

The guest booted and Launcher ran, but shell package queries and activity
resolution could not see any `com.bluestacks.*` system package. Resolver
tables still contained their activities and services. Android 16 therefore
logged repeated stale resolve-result removal and BlueStacks Settings could not
be launched.

The original A16 port centralized caller classification in
`isBstCallerPrivileged()`. For UIDs below `Process.FIRST_APPLICATION_UID`, it
passed an empty package name to `BstUtils.bstIsCallingAppPrivileged()`. A13
passes `null` for these non-application callers. `BstUtils` treats `null`,
system_server, Android, Google, uncube, and BlueStacks callers as trusted, but
does not treat an empty string as trusted.

This changed UID 0 and shell/system internal lookups from trusted to
untrusted. In particular, Android's post-resolution filter requests package
state with `getPackageStateInternal(packageName, 0)`. The bad classification
returned `null`, making valid resolver entries appear stale.

## Adaptation

The fix changes only the non-application caller sentinel from `""` to `null`.
It restores A13 semantics without changing package prefixes, the
`BST_SHOW_APPS` override, activity-info policy, or classification of any
application UID.

## Code Review

The change is necessary. Dropping the stale-result guard would only hide the
symptom and could restore the earlier null dereference. Removing BlueStacks
package hiding would expose product packages to third-party apps. Passing
`null` for a caller that has no application package is the narrow A13-matching
correction and preserves Android 16's centralized helper.

There is no measurable performance cost: one existing branch returns the same
boolean A13 returned. Security policy remains closed for untrusted application
UIDs. Trusted platform/root/shell paths regain package state required for
system resolution and diagnostics.

## Validation

- A13 and A16 `BstUtils` privilege rules: identical
- A13 non-application caller value: `null`
- A16 faulty value: empty string
- `git diff --check`: pass
- Incremental `m -j8 services`: pass in 3 minutes 57 seconds
- Installed output: `out_nxt_Baklava64/target/product/x86_64/system/framework/services.jar`
- Incremental image/package build: pass; root
  `e52ab6a672f4d7aa4bd22308c7aefb29669c9bd8`
- Root SHA-256:
  `870eef957ffbb92242b5d88cec046839317d41d6d921d7c07037623cb501b940`
- system.img SHA-256:
  `0d94171ff4015542943000817da0c1493650ed30d818bb2674e56385825f99fb`
- system.sfs SHA-256:
  `fda1c373cb0954f00dfdaf917f12a53cbdd6c1beb7d271240b99c2bbe426a328`
- fastboot.vdi SHA-256:
  `b93571ec361c5d05d3bfdc300d6794dde52deedc02e96fedeca8e1b20e5a400a`
- Clean-Data boot oracle: 7/7 pass in 289 seconds, including 95 seconds of
  stability observation
- `pm path com.bluestacks.settings`: pass, system privileged APK returned
- BlueStacks Settings cold start: pass in 414 ms; return to uncube HOME: pass
- Runtime logcat: no stale BlueStacks resolver or package-state failure

The extended regression exposed separate A13 promotion gaps in product feature
declarations and `bst.*` property lookup. Those do not invalidate this package
visibility fix and are tracked in
[`a13-runtime-gaps-2026-08-07.md`](a13-runtime-gaps-2026-08-07.md).

Rollback parent is `971523b961b1e197dbb04f642ab916ee01374920` in
`frameworks/base`, with Android root parent
`3d62b6f641a4006987e760156e12193775eaa15f`.
