# Codex Adapter

Read [`CLAUDE.md`](CLAUDE.md) for repository constraints and
[`docs/development-workflow/README.md`](docs/development-workflow/README.md) for
the canonical lifecycle.

Codex must use the same stage, review, evidence, and escalation rules as the
Claude scaffolding. Do not create a parallel process definition here.

For local project review, do not access or mutate either remote AOSP tree. For
an explicitly authorized remote task, identify the stage before acting:

- AOSP16 development/replay
- AOSP16-to-Android-16 promotion
- Android-16 mainline maintenance

Current Android-16 build commands must pass the target-tree identity preflight
and must never consume `~/aosp16/out*`.
