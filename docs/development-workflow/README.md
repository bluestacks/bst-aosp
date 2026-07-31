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

The initial AOSP16-to-Android-16 promotion is complete and represented by
[bluestacks/android-16#1](https://github.com/bluestacks/android-16/pull/1).
Current implementation work belongs to the Android-16 mainline stage unless a
new, explicitly frozen development batch is promoted.

This repository is documentation, scripts, patch evidence, and workflow
scaffolding. It is not an AOSP source tree.
