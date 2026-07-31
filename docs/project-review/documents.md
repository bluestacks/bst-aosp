# Documentation Review

## Authority Order

The project has four documentation roles. Conflicts are resolved by role and
evidence date, not by whichever file is shortest:

1. `progress/porting-log.md` and archived boot-debug logs preserve the original
   chronological development record.
2. `patches/android-16/meta/`, checkpoints, registries, and artifact hashes
   bind claims to concrete source or build evidence.
3. `docs/development-history/` indexes the chronology without rewriting it.
4. `docs/development-workflow/`, `CLAUDE.md`, and `.claude/` define the current
   three-stage process.

Architecture and build guides summarize those sources. They are not permitted
to override a later checkpoint or verified artifact identity.

## Stage Corrections

Previous navigation treated scripts acting on `~/aosp16` as the current remote
pipeline. This was true during development but became unsafe after promotion.
The updated documentation now distinguishes:

- AOSP16 historical development reproduction;
- the one-time AOSP16-to-Android-16 promotion;
- continued development on Android-16 after merge.

Historical commands retain their original paths. Current commands point to the
Android-16 gate and require the target identity readback.

## Development Records

Original progress content remains append-only and in original order.
[`timeline.json`](../development-history/timeline.json) indexes headings, dates,
cont numbers, rounds, and source lines. Curated decision documents connect the
initial problem, failed attempts, final repair, performance tradeoff, and boot
evidence.

The AOSP16 record is not labeled obsolete. Its failed rounds and temporary
workarounds explain why the final patch set has its present shape and are
required to review future regressions.

## Link and Command Review

The inventory resolves local Markdown links and reports missing targets as
findings. Claude commands and rules now point to the canonical workflow instead
of copying a second process into Codex. `AGENTS.md` is a thin adapter and leaves
`CLAUDE.md` as the shared repository contract.

Generated documents are marked as regenerable. Their JSON inputs and source
logs remain authoritative; manual edits to generated indexes are not durable.

## Known Limits

Timeline indexing operates at heading granularity. Command-block and hunk-level
details are covered by the per-file inventory, patch inventory, curated
decisions, and original logs rather than duplicating all log prose. External
GitHub PR state is recorded from the local development record and was not
refetched during this task.
