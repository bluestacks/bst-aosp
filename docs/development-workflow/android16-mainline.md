# Android-16 Mainline Maintenance

After the initial promotion, ordinary fixes are made directly against the
Android-16 integration model.

## Branch Model

- Base: `aosp16-bst`.
- Work/integration: `aosp16-bst-merge`.
- Unchanged component repositories remain on the base branch.
- A component moves to the merge branch only when its reviewed content changes.

## Work Unit

1. Run the read-only promotion audit without recorded-count enforcement when
   the mainline has legitimately evolved.
2. Select the affected component and record its base SHA.
3. Make a focused change; do not copy an entire AOSP16-era source file over a
   newer Android-16 file.
4. Run local syntax/static checks.
5. Run the target-tree preflight, Layer 1 build, package/deploy, and required
   Layer 2 oracles.
6. Review the component diff against `aosp16-bst` or its explicit fork point.
7. Commit and push the component, update the root gitlink, re-audit, then update
   the root PR.

## Prohibited Fallbacks

- No build, stage, package, or validation input may come from
  `~/aosp16/out*`.
- A successful AOSP16 command is not evidence for Android-16.
- A root PR does not prove component SHAs are reachable.
- A command returning zero does not prove its artifact exists or passed boot
  validation.
