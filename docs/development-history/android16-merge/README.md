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
- [`timeline.md`](timeline.md): generated cont.103-cont.106 chronology.
- [`patch-traceability.md`](patch-traceability.md): every archived patch mapped
  to registry and timeline evidence where available.
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
- Current reviewed pull request:
  [bluestacks/android-16#2](https://github.com/bluestacks/android-16/pull/2),
  root `298403a`, ready to merge with no base conflict.

The promotion gate requires every submodule initialized, no detached projects,
the root gitlink matching the reviewed component SHA, and every referenced SHA
available from its expected remote.
