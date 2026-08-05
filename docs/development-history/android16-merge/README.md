# AOSP16 to Android-16 Promotion

This stage promotes the validated AOSP16 development line into the
`android-16` mainline integration repository. It is analogous to merging a
tested development branch into a newer mainline, not re-porting isolated
features from scratch.

## Record Map

- [`promotion-record.md`](promotion-record.md): frozen source, merge decisions,
  first-candidate validation and withdrawn publication identity.
- [`rework-audit.md`](rework-audit.md): active omission review, structural
  corrections and new validation gates.
- [`a13-authority-completion.md`](a13-authority-completion.md): current
  code-level A13 authority review, newly restored patch groups and validation
  debt after the previous PR was withdrawn.
- [`timeline.md`](timeline.md): generated cont.103-cont.106 chronology.
- [`patch-traceability.md`](patch-traceability.md): every archived patch mapped
  to registry and timeline evidence where available.
- [`houdini16-integration.md`](houdini16-integration.md): restricted payload
  identity, A13 native-bridge mapping, Android 16 decisions and validation gates.
- [`../../android-16-patch-review/README.md`](../../android-16-patch-review/README.md):
  detailed code, necessity, performance, and risk review.

## Branch Contract

- Unchanged projects: `aosp16-bst`.
- Projects carrying promoted or mainline-resolution changes:
  `aosp16-bst-merge`.
- Development fork: `mark-bst`.
- Integration target: `bluestacks/android-16:aosp16-bst`.
- Withdrawn root pull request:
  [bluestacks/android-16#1](https://github.com/bluestacks/android-16/pull/1).
- Current replacement pull request:
  [bluestacks/android-16#2](https://github.com/bluestacks/android-16/pull/2),
  from `mark-bst:aosp16-bst-merge` to `bluestacks:aosp16-bst`.
- Current published review root: `5c8f8eb90d60afbb6cb4b21566552b6a8f3bd1e8`.
  Target-only `m droid`, supplemental guest libraries, `systemimage`, package,
  Windows deployment and Layer 2 boot validation pass; boot reached 7/7 at
  168 seconds. The final remote audit covers 1026 repositories with 975 base
  and 50 merge projects, zero remote mismatches and zero structural errors.
- [`evidence/2026-08-05-layer2-selinux-apex-fix.json`](evidence/2026-08-05-layer2-selinux-apex-fix.json):
  rejected A13 SELinux mechanism, Android 16 adaptation, build/package hashes
  and current 7/7 boot evidence.
- [`evidence/2026-08-05-runtime-followup.json`](evidence/2026-08-05-runtime-followup.json):
  SELinux runtime pass, Widevine/audio partial results, ADB limitation and the
  remaining feature-oracle boundary.
- [`evidence/2026-08-05-publication-closure.json`](evidence/2026-08-05-publication-closure.json):
  fork creation, exact base/merge tips, final remote audit, publication-order
  deviation and PR readback.

The promotion gate requires every submodule initialized, no detached projects,
the root gitlink matching the reviewed component SHA, and every referenced SHA
available from its expected remote.
