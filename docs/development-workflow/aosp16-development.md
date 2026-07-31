# AOSP16 Development Workflow

The AOSP16 line used this closed loop:

`research -> modify -> build -> package -> deploy -> boot readback -> checkpoint -> review -> next iteration`

## Purpose

- Establish the BlueStacks Android 16 guest contract from Android 13 sources
  and the Android 16 upstream base.
- Make `bst_x86_64`/qvirt build and boot under the Windows host.
- Port functional customizations in focused groups.
- Produce a green source and artifact baseline suitable for promotion.

## Entry and Exit

Entry required correct source branches, initialized submodules, and a recorded
upstream/fork comparison. Exit required focused patches or commits, registry
mapping, a checkpoint, Layer 1 evidence, and Layer 2 evidence when the change
entered the boot image.

The accepted exit baseline is documented in
[`../development-history/aosp16/final-green-baseline.md`](../development-history/aosp16/final-green-baseline.md).

## Historical Execution Rules

- Existing scripts containing `~/aosp16` describe this stage and retain that
  path for forensic replay.
- Replaying them against a live tree requires explicit human authorization and
  a disposable branch. They are not current Android-16 commands.
- Aggregate or rejected patches are intent/coverage references, not an ordered
  replay series.
- Rounds and cont records remain append-only. Corrections are later records,
  not edits that erase the original observation.
