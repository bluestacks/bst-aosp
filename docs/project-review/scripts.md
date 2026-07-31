# Script Review

## Scope and Method

Every `.sh`, `.py`, and `.ps1` file is represented in
[`inventory.json`](inventory.json) with its stage, hash, line endings, timeline
references, dependencies, purpose, necessity, performance impact, security
assessment, result, and preservation policy. The generated record is the
file-level authority; [`../../scripts/README.md`](../../scripts/README.md) is
the human entry-point map.

The review deliberately keeps filenames stable. Hundreds of AOSP16 progress
records cite exact script names, so physically grouping them after the fact
would weaken traceability and break replay documentation.

## Active Android-16 Findings

The maintained chain now shares
[`android16_env.sh`](../../scripts/lib/android16_env.sh), which:

- resolves the configured target root and rejects the AOSP16 development root;
- checks Git root, allowed branch, HEAD, product, and `OUT_DIR`;
- exports one set of app-player, HD guest, release, and graphics paths;
- records tree/branch/commit/output and artifact SHA-256 in an identity sidecar.

The build, stage, graphics, Root packaging, Windows deploy, and boot-oracle
scripts now fail on their own failed stage instead of allowing a later command
to hide the return code. Required APKs and every Layer 2 oracle are fatal when
missing. This closes the previously observed false-success path where an
Android-16 command silently built from `~/aosp16`.

No guest runtime overhead is introduced by these guards. They add Git and hash
readback during build/deploy, which is negligible compared with compilation and
image packaging. Full artifact hashing is intentional release evidence. The
normal chain compiles goldfish EGL/gralloc/HWC once, then stages the verified
output during packaging; it no longer repeats the same graphics build in three
successive scripts.

## Promotion Tools

[`audit_android16_promotion.py`](../../scripts/audit_android16_promotion.py)
performs read-only freeze and target audit operations. It checks initialization,
detached HEAD, dirty state, branch, project HEAD, root gitlink, expected branch
distribution, remotes, and optional remote branch-tip reachability. The
recorded complete topology is 1,016 projects: 985 on `aosp16-bst` and 31 on
`aosp16-bst-merge`.

[`merge_aosp16_to_android16.sh`](../../scripts/merge_aosp16_to_android16.sh) is
retained as the cont.103 executor but is inert unless the historical apply flag
is explicit. It is evidence, not the current promotion entry point.

## Historical Findings

- `scripts/p2_mech2_apply.py` is truncated at lines 20-21. It is preserved as
  an expected historical failure; the successful output is the canonical
  `P2-MECH-2` diff and cont.65 validation.
- `scripts/archive/patch-makefile-kernel-a16.sh` contains valid Python under a
  Python shebang. The extension is wrong, but changing a cited archive path has
  no functional benefit. Validation follows the interpreter declaration.
- Archived Bash line endings are left byte-for-byte unchanged. The validator
  normalizes line endings only in memory before `bash -n`.
- Failed, reverted, temporary, and superseded scripts remain necessary as
  provenance. They are not safe current commands and must not be called by the
  Android-16 active pipeline.

The exact exception and replacement are machine-readable in
[`validation-allowlist.json`](validation-allowlist.json).

## Remaining Risk

Static parsing cannot establish that remote toolchains, proprietary payloads,
or host/guest contracts are present. Build and boot verification are
deliberately not run in this repository-only review. The activity gate reduces
cross-tree mistakes, but a clean Android-16 build plus artifact-bound Layer 2
run remains required before release.
