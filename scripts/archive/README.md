# AOSP16 Historical Workflow Archive

This directory is part of the AOSP16 development record. Its 239 scripts and
payload helpers preserve the route from initial Android 16 bring-up to the final
green guest. They are not current Android-16 mainline entry points, but they
remain necessary for regression archaeology, failure analysis, and replay
design.

## Categories

| Category | Examples | Historical role | Current disposition |
|---|---|---|---|
| Round patches | `patch-round*.sh` | R11-R160 initrd and boot experiments | Superseded; retain |
| Henry alignment | `henry-*`, `apply-henry-*` | Compared and aligned earlier guest behavior | Superseded; retain |
| init/stage2 | `patch-initsh-*`, `patch-stage2-*` | Iterated first/second-stage startup | Final state captured by patch/checkpoint evidence |
| SELinux | `patch-selinux-*`, `r244-fix-*` | Diagnosed policy and enforcing blockers | Mixed temporary/final lessons; retain |
| Graphics | `patch-hd-nvidia-*`, `patch-goldfish-*` | Tested host GPU and encoder paths | Reverted or replaced; retain |
| Runtime staging | `gen-boot-framework*`, `stage2-good-vhd.sh` | Tested staged ART/framework generation | Strategy abandoned; retain |
| Intermediate packaging | `r229`-`r244`, `hotpatch-*`, `repack-*` | Produced diagnostic Root/fastboot variants | Superseded by final pack chain |
| Known wrong decision | `r252-patch-auth-services.py` | Disabled AuthService while isolating boot | Replaced by top-level r261 correction |

## Preservation Rules

- Do not invoke archive scripts from current Android-16 entry points.
- Do not bulk-replace `~/aosp16`; it records the development source tree.
- Do not normalize archived bytes only to satisfy a parser. Static validation
  normalizes Bash line endings in memory.
- Do not delete duplicates solely by hash. Some encode initrd placement,
  payload layout, or a checkpoint snapshot.
- Record a replacement before moving or deleting a path referenced by progress
  logs.

`patch-makefile-kernel-a16.sh` has a Python shebang and Python content despite
its extension. The validator follows the shebang, records this naming defect,
and does not rewrite the historical file.

See the [script stage index](../README.md), the
[AOSP16 history](../../docs/development-history/aosp16/README.md), and the
[full inventory](../../docs/project-review/inventory.md).
