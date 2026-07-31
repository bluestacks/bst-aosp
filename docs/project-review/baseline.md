# Initial Working Tree Baseline

This baseline was captured before the repository-wide review edits on
`codex/project-deep-review`. It preserves the pre-existing migration work as a
distinct input to the review; no reset, stash, or overwrite was performed.

## Git State

- Base branch and commit: `master` at `8aa7d62`
- Review branch: `codex/project-deep-review`
- Repository remote: none configured

Pre-existing modified files:

- `progress/porting-log.md`
- `scripts/g1_apply_boot_overlays.sh`
- `scripts/g1_build_libs.sh`
- `scripts/g1_rebuild_graphics.sh`
- `scripts/g1_stage_system.sh`
- `scripts/g8_disable_vendor_hal_rc.sh`

Pre-existing untracked source and documentation:

- `docs/android-16-patch-review/`
- `scripts/aemu_host_supported.py`
- `scripts/audit_a16_merge.sh`
- `scripts/g1_build_android16.sh`
- `scripts/generate_android16_patch_inventory.py`
- `scripts/libhidl_drop_mgr_token.py`
- `scripts/merge_aosp16_to_android16.sh`
- `scripts/resolve_kernel_conflicts.py`

Pre-existing generated or diagnostic material:

- `.codex-tmp/`

The files above must be reviewed on their own merits. Generated logs and copied
build artifacts remain outside commits; source, patch review, and development
history files may be committed only after validation.
