# AOSP16 to Android-16 Promotion

This stage promotes the validated AOSP16 development line into the
`android-16` mainline integration repository. It is analogous to merging a
tested development branch into a newer mainline, not re-porting isolated
features from scratch.

## Record Map

- [`promotion-record.md`](promotion-record.md): frozen source, merge decisions,
  validation, and publication identity.
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
- Root pull request:
  [bluestacks/android-16#1](https://github.com/bluestacks/android-16/pull/1).

The promotion gate requires every submodule initialized, no detached projects,
the root gitlink matching the reviewed component SHA, and every referenced SHA
available from its expected remote.
