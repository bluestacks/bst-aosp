# Development Workflow

This is the canonical workflow index. Agent-specific files under `.claude/` or
`AGENTS.md` adapt these rules; they do not define a second lifecycle.

## Three Stages

1. [`aosp16-development.md`](aosp16-development.md): historical and replayable
   development line from source triage through the cont.101 green baseline.
2. [`promotion.md`](promotion.md): controlled promotion of a frozen AOSP16 line
   into the Android-16 mainline integration tree.
3. [`android16-mainline.md`](android16-mainline.md): ordinary fixes after the
   promotion baseline has landed.

All stages use [`review-and-evidence.md`](review-and-evidence.md): no completion
claim is valid without tree identity, source identity, output identity, and an
independent validation readback.

Historical binaries follow [`binary-artifacts.md`](binary-artifacts.md):
identity metadata stays in Git, while the 16 required non-reconstructable
inputs are packaged into deterministic external bundles.

## Current State

The initial promotion PRs are historical. Promotion PR
[bluestacks/android-16#4](https://github.com/bluestacks/android-16/pull/4) is
merged, and follow-up Draft PR
[bluestacks/android-16#5](https://github.com/bluestacks/android-16/pull/5)
carries the runtime-validated component pointers from Android root
`eb146d4c3b26dbd8447e74f343020015ee85ced7` into
`bst-v5.22.210-A16`.

The one authorized clean Android-16 build is complete. Every later source
change must preserve `out_nxt_Baklava64` and use the canonical incremental
build/package flow. The final package passed 10/10 cold boots plus properties,
Launcher, IME, FPS, app, Houdini, camera, Play/GMS and ADB policy oracles. The
remaining Hyper-V shared-folder gate requires a maintained host/guest transport
provider outside the submitted Android/goldfish scope; an empty directory or
hypervisor-property override is not acceptance evidence.

This repository is documentation, scripts, patch evidence, and workflow
scaffolding. It is not an AOSP source tree.
