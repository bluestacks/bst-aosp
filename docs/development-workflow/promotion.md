# AOSP16 to Android-16 Promotion

Promotion treats AOSP16 as a validated development line and Android-16 as the
mainline integration tree.

## Workflow

`freeze -> audit -> compare -> merge -> review -> target build -> target boot -> fork push -> root PR`

### 1. Freeze

Capture every source project path, branch, HEAD, dirty state, patch identity,
and validation checkpoint. A dirty source tree is not a reproducible input.

```bash
python3 scripts/audit_android16_promotion.py freeze \
  --source-root ~/aosp16 \
  --paths-from ~/android-16 \
  --output /tmp/aosp16-freeze.json
```

### 2. Audit Target

Check every declared submodule, branch, detached state, dirty state, root
gitlink, and component HEAD before editing:

```bash
python3 scripts/audit_android16_promotion.py audit \
  --root ~/android-16 \
  --enforce-current-baseline \
  --output /tmp/android16-before.json
```

The withdrawn first candidate recorded 1016 initialized projects: 985 on
`aosp16-bst` and 31 on `aosp16-bst-merge`. That topology remains historical.
The current reviewed baseline is 1022 submodules: 987 on `aosp16-bst` and 35 on
`aosp16-bst-merge`; `--enforce-current-baseline` checks those values explicitly.
The camera HAL is inline in the current mainline root, so a duplicate camera
submodule is intentionally excluded.

### 3. Compare and Merge

- Compare by project and file; do not infer coverage from a hand-maintained
  project list.
- Use binary-capable diffs for APK/JAR/keystore-like paths, but never promote a
  private signing credential.
- Record every semantic conflict as “AOSP16 intent vs Android-16 mainline
  behavior”, the selected side, and why.
- Preserve Android-16 25Q4 infrastructure when an r4-era substitution has
  become obsolete; preserve BlueStacks product hooks when still required.
- Keep `goldfish-opengl-pie` on its established external path and compile the
  selected EGL/gralloc/HWC provider explicitly. It must not be added to the
  main Kati module scan: preserve the native 25Q4 gfxstream graph, then stage
  the Windows provider through the dedicated graphics flow.
- Windows product changes belong to
  `device/generic/x86_64/android_x86_64`; do not restore qvirt or weaken
  target-global build/VINTF policy.
- The historical first-pass executor is inert unless explicitly invoked with
  `--apply-historical`. It is evidence, not the current maintenance path.

### 4. Validate Only the Target

Before any build:

```bash
bash scripts/g1_build_android16.sh --check
```

The build gate must read back the resolved tree, branch, HEAD, OUT_DIR, product,
graphics source, and clean multi-project state. A path resolving to the AOSP16
development tree or any uncommitted project is fatal. Build, system stage, Root
image, deployment, and boot evidence must share the same source HEAD and
artifact hash.

### 5. Publish

- Push changed component repositories to `mark-bst:aosp16-bst-merge`.
- Require every commit in `aosp16-bst..aosp16-bst-merge` to use
  `[A16] <imperative summary>`; the audit rejects nonconforming titles.
- Verify each pushed branch tip equals the root gitlink SHA.
- Update and review root gitlinks only after component reachability passes.
- Submit the root branch to `bluestacks/android-16:aosp16-bst`.
- Read the PR back and store root SHA, component SHAs, changed files, conflict
  status, and validation identity.

Use `--check-remotes` in the promotion audit for the component branch-tip
readback. Networked publish checks are never implied by a local static pass.
