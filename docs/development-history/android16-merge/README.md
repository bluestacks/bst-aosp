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
- [`a13-runtime-oracle-matrix.md`](a13-runtime-oracle-matrix.md): all 32
  runtime-pending A13 patch entries mapped source-commit by source-commit to
  executable and host/manual acceptance gates.
- [`runtime-regression-2026-08-06.md`](runtime-regression-2026-08-06.md): current
  launcher/property/HAL findings, active build identity and regression record.
- [`runtime-regression-2026-08-11.md`](runtime-regression-2026-08-11.md):
  runtime-validated explicit property fix, 6.12 AHCI/APIC and ashmem resolution,
  narrow incremental build and package identity, and the remaining host/guest
  shared-folder and IME contract gaps.
- [`promotion-status-2026-08-10.md`](promotion-status-2026-08-10.md): current
  candidate, target-branch ancestry, final artifact/boot evidence and open
  publication blockers.
- [`component-target-merge-2026-08-10.md`](component-target-merge-2026-08-10.md):
  final 51-component target publication, divergent-merge decisions, kernel
  6.12 handling, remote readback, root gitlinks and validation boundary.
- [`a13-hal-vintf-review.md`](a13-hal-vintf-review.md): six prepared corrections
  for retained x86_64 HIDL service declarations.
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
- Formal component owner: `bluestacks`; personal forks are historical evidence
  only and are forbidden in the current root metadata and publication flow.
- Integration target: `bluestacks/android-16:bst-v5.22.210-A16`.
- Withdrawn root pull request:
  [bluestacks/android-16#1](https://github.com/bluestacks/android-16/pull/1).
- Superseded pull request:
  [bluestacks/android-16#2](https://github.com/bluestacks/android-16/pull/2),
  closed after the target changed from `aosp16-bst`.
- Superseded publication pull request:
  [bluestacks/android-16#3](https://github.com/bluestacks/android-16/pull/3),
  whose personal-fork source is retained only as historical evidence.
- Current Draft pull request:
  [bluestacks/android-16#4](https://github.com/bluestacks/android-16/pull/4),
  from `bluestacks:aosp16-bst-merge` to
  `bluestacks:bst-v5.22.210-A16`.
- Current published review root: `abf041cae9dfe1c32a150d8d2b97898b8c63529b`.
  All 51 promoted components were published to and read back from both their
  source merge branch and the BlueStacks `bst-v5.22.210-A16` target branch.
  Fourteen root gitlinks advanced after divergent component merges. The final
  ownership commit `90f87eed8d0bbd1bed49f077f775309bd9f2d843`
  removes all personal-fork URLs and makes every explicit
  branch track `bst-v5.22.210-A16`. The build, package, and boot evidence
  remains bound to `2be2bd594015046288f67420c72ac3d964595d14` and is historical
  for the new root; a new incremental build and boot regression are required.
  That historical runtime acceptance was blocked by exact `bst.*` lookup and
  shared folders. The 2026-08-11 follow-up resolves and validates exact `bst.*`
  reads, 6.12 interrupt delivery, and memfd-backed legacy gralloc. Those
  component and root commits are published in Draft PR #4. The current
  diagnostic Root/fastboot pair passes 7/7 boot and property checks but is not
  a final unified package, and the Hyper-V shared-folder and IME listener
  contracts remain blocked.
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
