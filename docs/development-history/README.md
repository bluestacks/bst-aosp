# Development History

This directory indexes the predecessor audit and two connected engineering
lines:

1. [`a13-port-audit/`](a13-port-audit/README.md) compares the final A13 product
   line with both A16 trees and records code-level omissions, adaptations and
   rejected legacy patches.
2. [`aosp16/`](aosp16/README.md) is the validated development line. It contains
   the bring-up, source port, build, packaging, boot, failure, and functional
   parity record.
3. [`android16-merge/`](android16-merge/README.md) is the promotion of that
   validated line into the Android-16 mainline integration repository.

The source of truth remains the append-only
[`progress/porting-log.md`](../../progress/porting-log.md), archived boot-debug
record, patch registry, and checkpoints. Documents here provide navigation and
traceability; they do not rewrite the original chronology.

The machine-readable combined heading index is
[`timeline.json`](timeline.json).
